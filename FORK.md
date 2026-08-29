# Vybt fork of `@capgo/capacitor-camera-preview`

Maintained for the [Vybt](https://github.com/eduardo-s-freitas/vybt-vibe-now) app.

## Base

| | |
|---|---|
| Branch | `vybt` |
| Forked from | `Cap-go/capacitor-camera-preview` |
| Base commit | `5b88dc05d4` — `chore(release): 8.11.2` (2026-07-15) |

**Deliberately based on the 8.11.2 release, not on `main`.** At the time of the
fork `main` was ahead with an Android `toBack` compositor rework and a Gradle 9
upgrade — neither released, neither tested in the app, and neither touching iOS.
Starting from the exact code already shipping to users kept the Android change
below validated against what it was tested on.

## Changes on this branch

### `android/…/CameraXView.java` — flip during video recording

Calling `flip()` while recording aborted the take: `stopRecordVideo()` then failed
with `No video recording in progress`, and no `recordingFinished` event was
emitted. Two things each broke it, so both had to change:

1. **`bindCameraUseCases()` rebuilt the recorder unconditionally.** A `Recording`
   is bound to the `Recorder` it started from, so replacing that instance orphans
   it. The rebuild is now skipped while a recording is in flight:

   ```java
   if (sessionConfig.isVideoModeEnabled() && (videoCapture == null || currentRecording == null)) {
   ```

2. **`cameraProvider.unbindAll()` finalised the recording.**
   [`asPersistentRecording()`](https://developer.android.com/reference/androidx/camera/video/PendingRecording#asPersistentRecording())
   makes it survive the unbind/rebind, and is applied to both the audio-enabled
   and muted branches.

Verified on device: recording continues across a camera switch and stops normally.

## Not fixed here: iOS

iOS has the same symptom from an unrelated cause. `flip()` in
`CameraController.swift` removes the `AVCaptureMovieFileOutput` from the session
and re-adds it to rebind its connection ("Re-attach movie file output"). Removing
an output that is recording ends it with an error, so the delegate reports reason
`"error"`, `stopRecordingCompletion` is rejected, and `recordingFinishedCallback`
never fires. It surfaces in the app as *"That recording could not be saved"*.

Supporting it needs `AVAssetWriter` + `AVCaptureVideoDataOutput` instead of
`AVCaptureMovieFileOutput`, since only the former survives an input switch.

Groundwork already in the plugin, which makes this smaller than it sounds:
`dataOutput` (an `AVCaptureVideoDataOutput`) is **already** added to every session
with a sample-buffer delegate on a dedicated queue, so video frames are flowing.
What is missing is an `AVCaptureAudioDataOutput`, the asset writer itself, and
moving `maxDuration` / `maxFileSize` from the movie output into code.

Two things to watch when doing it:
- `alwaysDiscardsLateVideoFrames = true` is right for preview and wrong for
  recording — it must be `false` while writing.
- `videoSettings` is `32BGRA`; writable, but not the cheapest path.

## Keeping up with upstream

```bash
git fetch upstream
git merge upstream/main        # resolve, then re-verify the flip on device
```

Upstream is active — 8 releases in the three weeks before this fork — so expect
to do this deliberately rather than often. Nothing warns you when you fall
behind; that is the trade-off taken when choosing a fork over `patch-package`.

## Consuming app

`vybt-vibe-now/package.json` points at this branch. Pin to a commit SHA rather
than the branch name before a release, so a build cannot pick up an unreviewed
commit:

```json
"@capgo/camera-preview": "github:eduardo-s-freitas/capacitor-camera-preview#<sha>"
```

## Upstream issue

The Android analysis and the suggested diff are written up for filing at
`Cap-go/capacitor-camera-preview` — see `ISSUE-flip-during-recording.md` in the
Vybt repo. Licence is MPL-2.0, so changes to these files are published here.
