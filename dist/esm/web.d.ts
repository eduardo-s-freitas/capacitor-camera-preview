import { WebPlugin } from '@capacitor/core';
import type { BarcodeScannerOptions, CameraDevice, CameraPreviewAspectRatio, CameraOpacityOptions, CameraPreviewFlashMode, CameraPreviewOptions, CameraPreviewPictureOptions, CameraPreviewPlugin, CameraSampleOptions, CameraPermissionStatus, DeviceOrientation, GridMode, ExposureMode, WhiteBalanceMode, FlashMode, LensInfo, PermissionRequestOptions, SafeAreaInsets, VideoCodec, VideoStabilizationMode, VideoQuality } from './definitions';
export declare class CameraPreviewWeb extends WebPlugin implements CameraPreviewPlugin {
    /**
     *  track which camera is used based on start options
     *  used in capture
     */
    private isBackCamera;
    private currentDeviceId;
    private videoElement;
    private isStarted;
    private orientationListenerBound;
    private mediaRecorder;
    private recordedChunks;
    private currentAspectRatio;
    private barcodeDetector;
    private barcodeScannerTimer;
    private barcodeScannerBusy;
    constructor();
    checkPermissions(options?: {
        disableAudio?: boolean;
    }): Promise<CameraPermissionStatus>;
    requestPermissions(options?: PermissionRequestOptions): Promise<CameraPermissionStatus>;
    private mapWebPermission;
    private getCurrentOrientation;
    private ensureOrientationListener;
    getOrientation(): Promise<{
        orientation: DeviceOrientation;
    }>;
    getSafeAreaInsets(): Promise<SafeAreaInsets>;
    getZoomButtonValues(): Promise<{
        values: number[];
    }>;
    getSupportedPictureSizes(): Promise<any>;
    start(options: CameraPreviewOptions): Promise<{
        width: number;
        height: number;
        x: number;
        y: number;
    }>;
    private stopStream;
    stop(_options?: {
        force?: boolean;
    }): Promise<void>;
    capture(options: CameraPreviewPictureOptions): Promise<any>;
    captureSample(_options: CameraSampleOptions): Promise<any>;
    startBarcodeScanner(options?: BarcodeScannerOptions): Promise<void>;
    stopBarcodeScanner(): Promise<void>;
    private getStartBarcodeScannerOptions;
    private toWebBarcodeFormat;
    private toBarcodeScanResult;
    private fromWebBarcodeFormat;
    stopRecordVideo(): Promise<any>;
    startRecordVideo(options: CameraPreviewOptions): Promise<any>;
    getSupportedFlashModes(): Promise<{
        result: CameraPreviewFlashMode[];
    }>;
    getHorizontalFov(): Promise<{
        result: any;
    }>;
    setFlashMode(_options: {
        flashMode: CameraPreviewFlashMode | string;
    }): Promise<void>;
    flip(): Promise<void>;
    setOpacity(_options: CameraOpacityOptions): Promise<any>;
    setVideoQuality(): Promise<void>;
    getVideoQuality(): Promise<{
        quality: VideoQuality;
    }>;
    getSupportedVideoQualities(): Promise<{
        qualities: VideoQuality[];
    }>;
    setVideoCodec(): Promise<void>;
    getVideoCodec(): Promise<{
        codec: VideoCodec;
    }>;
    getSupportedVideoCodecs(): Promise<{
        codecs: VideoCodec[];
    }>;
    isVideoStabilizationSupported(): Promise<{
        supported: boolean;
    }>;
    getSupportedVideoStabilizationModes(): Promise<{
        modes: VideoStabilizationMode[];
    }>;
    getVideoStabilizationMode(): Promise<{
        mode: VideoStabilizationMode;
    }>;
    setVideoStabilizationMode(): Promise<void>;
    isRunning(): Promise<{
        isRunning: boolean;
    }>;
    getAvailableDevices(): Promise<{
        devices: CameraDevice[];
    }>;
    getZoom(): Promise<{
        min: number;
        max: number;
        current: number;
        lens: LensInfo;
    }>;
    setZoom(options: {
        level: number;
        ramp?: boolean;
        autoFocus?: boolean;
    }): Promise<void>;
    getFlashMode(): Promise<{
        flashMode: FlashMode;
    }>;
    getDeviceId(): Promise<{
        deviceId: string;
    }>;
    setDeviceId(options: {
        deviceId: string;
    }): Promise<void>;
    getAspectRatio(): Promise<{
        aspectRatio: CameraPreviewAspectRatio;
    }>;
    setAspectRatio(options: {
        aspectRatio: CameraPreviewAspectRatio;
        x?: number;
        y?: number;
    }): Promise<{
        width: number;
        height: number;
        x: number;
        y: number;
    }>;
    private createGridOverlay;
    setGridMode(options: {
        gridMode: GridMode;
    }): Promise<void>;
    getGridMode(): Promise<{
        gridMode: GridMode;
    }>;
    getPreviewSize(): Promise<{
        x: number;
        y: number;
        width: number;
        height: number;
    }>;
    setPreviewSize(options: {
        x: number;
        y: number;
        width: number;
        height: number;
    }): Promise<{
        width: number;
        height: number;
        x: number;
        y: number;
    }>;
    setFocus(options: {
        x: number;
        y: number;
    }): Promise<void>;
    getExposureModes(): Promise<{
        modes: ExposureMode[];
    }>;
    getExposureMode(): Promise<{
        mode: ExposureMode;
    }>;
    setExposureMode(_options: {
        mode: ExposureMode;
    }): Promise<void>;
    getExposureCompensationRange(): Promise<{
        min: number;
        max: number;
        step: number;
    }>;
    getExposureCompensation(): Promise<{
        value: number;
    }>;
    setExposureCompensation(_options: {
        value: number;
    }): Promise<void>;
    getWhiteBalanceModes(): Promise<{
        modes: WhiteBalanceMode[];
    }>;
    getWhiteBalanceMode(): Promise<{
        mode: WhiteBalanceMode;
    }>;
    setWhiteBalanceMode(_options: {
        mode: WhiteBalanceMode;
    }): Promise<void>;
    getSupportedVideoFrameRates(): Promise<{
        frameRates: number[];
    }>;
    getVideoFrameRate(): Promise<{
        frameRate: number;
    }>;
    setVideoFrameRate(_options: {
        frameRate: number;
    }): Promise<void>;
    deleteFile(_options: {
        path: string;
    }): Promise<{
        success: boolean;
    }>;
    getPluginVersion(): Promise<{
        version: string;
    }>;
}
