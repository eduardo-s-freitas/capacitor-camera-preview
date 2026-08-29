import type { CameraPreviewPlugin } from './definitions';
declare const CameraPreview: CameraPreviewPlugin;
export * from './definitions';
export { CameraPreview };
export declare function getBase64FromFilePath(filePath: string): Promise<string>;
export declare function deleteFile(path: string): Promise<boolean>;
