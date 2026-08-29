import { Capacitor, registerPlugin } from '@capacitor/core';
const CameraPreview = registerPlugin('CameraPreview', {
    web: () => import('./web').then((m) => new m.CameraPreviewWeb()),
});
export * from './definitions';
export { CameraPreview };
export async function getBase64FromFilePath(filePath) {
    const url = Capacitor.convertFileSrc(filePath);
    const response = await fetch(url);
    if (!response.ok) {
        throw new Error(`Failed to read file at path: ${filePath} (status ${response.status})`);
    }
    const blob = await response.blob();
    return await new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onloadend = () => {
            const dataUrl = reader.result;
            const commaIndex = dataUrl.indexOf(',');
            resolve(commaIndex >= 0 ? dataUrl.substring(commaIndex + 1) : dataUrl);
        };
        reader.onerror = () => reject(reader.error);
        reader.readAsDataURL(blob);
    });
}
export async function deleteFile(path) {
    // Use native bridge to delete file to handle platform-specific permissions/URIs
    const { success } = await CameraPreview.deleteFile({ path });
    return !!success;
}
//# sourceMappingURL=index.js.map