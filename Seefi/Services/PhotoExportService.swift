import Foundation
import Photos
import UIKit

/// Exports received photos to Photos Library or Files.
enum PhotoExportService {
    
    /// Save photo to Photos Library.
    static func saveToPhotosLibrary(url: URL) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
        }
    }
    
    /// Export multiple photos to Photos Library.
    static func saveToPhotosLibrary(urls: [URL]) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            for url in urls {
                PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
            }
        }
    }
    
    /// Prepare a UIActivityViewController for sharing (export to Files, etc.)
    static func shareURLs(_ urls: [URL], from sourceView: UIView?) -> UIActivityViewController {
        let activityVC = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController, let source = sourceView {
            popover.sourceView = source
            popover.sourceRect = source.bounds
        }
        return activityVC
    }
}
