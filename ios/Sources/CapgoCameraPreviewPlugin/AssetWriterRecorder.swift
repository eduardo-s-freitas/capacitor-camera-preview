import AVFoundation
import CoreMedia
import CoreGraphics

/// Records video by writing sample buffers itself, instead of handing a file to
/// `AVCaptureMovieFileOutput`.
///
/// WHY
/// `AVCaptureMovieFileOutput` owns its file. Removing it from a running session
/// finalises whatever it was recording, which is what made `flip()` mid-recording
/// destroy the take: the flip detaches and re-attaches the movie output to rebind
/// its connection to the new camera input, and the recording dies with it.
///
/// An asset writer has no such tie. It consumes buffers from wherever they come
/// from, so swapping the camera input underneath is invisible to it — the frames
/// simply start arriving from the other lens. That is the whole reason for this
/// class.
///
/// THREADING
/// Every `append` must arrive on the capture delegate queue, and only from there.
/// `stop` may be called from anywhere; it hops to that queue itself. `state` is
/// only mutated on the delegate queue, so nothing here needs a lock beyond the
/// completion handoff.
final class AssetWriterRecorder {

    /// Why a recording ended. Mirrors the strings the movie-output path already
    /// reports through `recordingFinished`, so callers do not have to change.
    enum FinishReason: String {
        case completed
        case maxDurationReached
        case maxFileSizeReached
        case error
    }

    struct Configuration {
        let outputURL: URL
        /// Seconds. `nil` or <= 0 means no limit.
        let maxDuration: Double?
        /// Bytes. `nil` or <= 0 means no limit.
        let maxFileSize: Int64?
        /// False when the session was started with audio disabled, or when the
        /// microphone permission was refused.
        let includeAudio: Bool
    }

    private enum State: Equatable {
        case idle
        /// Writer exists but no session has started: waiting for the first video
        /// buffer, because the session must start on a real presentation time.
        case waitingForFirstFrame
        case recording
        /// A stop is in flight. Late buffers are dropped rather than appended,
        /// which would throw.
        case finishing
    }

    private let configuration: Configuration
    private var writer: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var state: State = .idle
    private var sessionStart: CMTime = .invalid
    private var lastVideoTime: CMTime = .invalid
    private var completion: ((URL?, FinishReason, Error?) -> Void)?

    /// Set once a limit trips, so the buffer that crosses it does not also try to
    /// stop a second time on the next frame.
    private var pendingReason: FinishReason?
    private var transform: CGAffineTransform = .identity

    /// Called once, on the capture queue, when a configured limit is hit.
    var onLimitReached: ((FinishReason) -> Void)?

    var isRecording: Bool {
        switch state {
        case .waitingForFirstFrame, .recording: return true
        case .idle, .finishing: return false
        }
    }

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    // MARK: - Lifecycle

    /// Arms the recorder. The writer itself is not built until the first video
    /// buffer arrives, because only that buffer knows the real frame size.
    ///
    /// Guessing the size from the device's active format is wrong here: the
    /// capture connection is set to portrait, which rotates the delivered
    /// buffers, so the format's landscape dimensions would produce a stretched
    /// clip.
    ///
    /// - Parameter transform: rotation/mirroring recorded into the file, so
    ///   playback is upright without the player having to know how the phone was
    ///   held.
    func prepare(transform: CGAffineTransform) throws {
        guard state == .idle else { throw CameraControllerError.recordingInProgress }
        // A leftover file at this path would make the writer fail to start.
        try? FileManager.default.removeItem(at: configuration.outputURL)
        self.transform = transform
        self.state = .waitingForFirstFrame
    }

    /// Builds the writer around the dimensions of the first real frame.
    private func startWriter(matching sampleBuffer: CMSampleBuffer) throws {
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
            throw CameraControllerError.unknown
        }
        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)

        let writer = try AVAssetWriter(outputURL: configuration.outputURL, fileType: .mp4)

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(dimensions.width),
            AVVideoHeightKey: Int(dimensions.height)
        ]
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        // Tells the writer that buffers arrive at capture speed and must not be
        // reordered or buffered up: without it, real-time capture drops frames.
        videoInput.expectsMediaDataInRealTime = true
        videoInput.transform = self.transform
        guard writer.canAdd(videoInput) else { throw CameraControllerError.invalidOperation }
        writer.add(videoInput)

        if configuration.includeAudio {
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 1,
                AVSampleRateKey: 44100,
                AVEncoderBitRateKey: 64000
            ]
            let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            audioInput.expectsMediaDataInRealTime = true
            if writer.canAdd(audioInput) {
                writer.add(audioInput)
                self.audioInput = audioInput
            }
        }

        self.writer = writer
        self.videoInput = videoInput
    }

    /// Appends a captured buffer. Safe to call before the first frame, after a
    /// limit has tripped, or after stopping — those cases are dropped.
    func append(_ sampleBuffer: CMSampleBuffer, isVideo: Bool) {
        guard pendingReason == nil else { return }

        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        if state == .waitingForFirstFrame {
            // Audio can arrive first. Starting on it would open the clip on
            // silence with no picture, and the frame size would still be unknown.
            guard isVideo, time.isValid else { return }
            do {
                try startWriter(matching: sampleBuffer)
            } catch {
                state = .idle
                onLimitReached = nil
                return
            }
            guard let writer = writer, writer.startWriting() else {
                state = .idle
                return
            }
            writer.startSession(atSourceTime: time)
            sessionStart = time
            state = .recording
        }

        guard state == .recording, writer?.status == .writing else { return }

        if isVideo {
            guard let input = videoInput, input.isReadyForMoreMediaData else { return }
            input.append(sampleBuffer)
            lastVideoTime = time
            checkLimits(at: time)
        } else {
            // Audio before the session start would be rejected by the writer.
            guard sessionStart.isValid, time >= sessionStart else { return }
            guard let input = audioInput, input.isReadyForMoreMediaData else { return }
            input.append(sampleBuffer)
        }
    }

    /// Ends the recording and finalises the file.
    ///
    /// The completion is always called exactly once, on the queue
    /// `finishWriting` uses. A recorder that has not started produces
    /// `.error`, matching how the movie-output path reported the same case.
    func stop(reason: FinishReason = .completed, completion: @escaping (URL?, FinishReason, Error?) -> Void) {
        guard state == .recording || state == .waitingForFirstFrame else {
            completion(nil, .error, CameraControllerError.invalidOperation)
            return
        }

        state = .finishing
        self.completion = completion

        // Stopped before a single frame arrived: there is no writer to finalise
        // and no file to hand back.
        guard let writer = writer, sessionStart.isValid else {
            self.writer?.cancelWriting()
            try? FileManager.default.removeItem(at: configuration.outputURL)
            finish(url: nil, reason: .error, error: CameraControllerError.unknown)
            return
        }

        videoInput?.markAsFinished()
        audioInput?.markAsFinished()

        writer.endSession(atSourceTime: lastVideoTime)
        let outputURL = configuration.outputURL
        writer.finishWriting { [weak self] in
            guard let self = self else { return }
            if writer.status == .completed {
                self.finish(url: outputURL, reason: reason, error: nil)
            } else {
                try? FileManager.default.removeItem(at: outputURL)
                self.finish(url: nil, reason: .error, error: writer.error ?? CameraControllerError.unknown)
            }
        }
    }

    /// Abandons the recording without producing a file. Used when the session
    /// tears down underneath us.
    func cancel() {
        guard let writer = writer else { return }
        state = .finishing
        writer.cancelWriting()
        try? FileManager.default.removeItem(at: configuration.outputURL)
        finish(url: nil, reason: .error, error: CameraControllerError.invalidOperation)
    }

    // MARK: - Limits

    /// `maxRecordedDuration` and `maxRecordedFileSize` were properties of
    /// `AVCaptureMovieFileOutput`. With a writer they have to be enforced here.
    private func checkLimits(at time: CMTime) {
        if let maxDuration = configuration.maxDuration, maxDuration > 0, sessionStart.isValid {
            let elapsed = CMTimeGetSeconds(CMTimeSubtract(time, sessionStart))
            if elapsed >= maxDuration {
                trip(.maxDurationReached)
                return
            }
        }

        if let maxFileSize = configuration.maxFileSize, maxFileSize > 0 {
            let path = configuration.outputURL.path
            if let attributes = try? FileManager.default.attributesOfItem(atPath: path),
               let size = attributes[.size] as? Int64, size >= maxFileSize {
                trip(.maxFileSizeReached)
            }
        }
    }

    /// Records that a limit was reached. The actual stop is left to the owner,
    /// which knows how to report it — stopping from inside an append would run
    /// finalisation on the capture queue and stall it.
    private func trip(_ reason: FinishReason) {
        guard pendingReason == nil else { return }
        pendingReason = reason
        onLimitReached?(reason)
    }

    // MARK: - Teardown

    private func finish(url: URL?, reason: FinishReason, error: Error?) {
        let completion = self.completion
        self.completion = nil
        self.writer = nil
        self.videoInput = nil
        self.audioInput = nil
        self.state = .idle
        self.sessionStart = .invalid
        self.lastVideoTime = .invalid
        self.pendingReason = nil
        completion?(url, reason, error)
    }
}
