import Foundation

/// Extracts TAR archives and saves photos to app storage.
enum PhotoImportService {
    private static let receivedPhotosDirectory = "ReceivedPhotos"
    
    static var receivedPhotosURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(receivedPhotosDirectory)
    }
    
    /// Extract TAR data, save image files to app Documents, invoke onPhotoSaved for each.
    /// Returns true if at least one photo was saved.
    @discardableResult
    static func extractAndSave(
        tarData: Data,
        originalFilename: String,
        onPhotoSaved: (ReceivedPhoto) -> Void
    ) -> Bool {
        let baseURL = receivedPhotosURL
        try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateFolder = dateFormatter.string(from: Date())
        let outputDir = baseURL.appendingPathComponent(dateFolder)
        try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
        var savedCount = 0
        var offset = 0
        let data = tarData
        
        while offset + 512 <= data.count {
            let header = data.subdata(in: offset..<(offset + 512))
            offset += 512
            
            let filename = header.subdata(in: 0..<100)
                .withUnsafeBytes { String(cString: $0.bindMemory(to: CChar.self).baseAddress!) }
                .trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
            
            guard !filename.isEmpty else { break }
            
            let sizeString = header.subdata(in: 124..<136)
                .withUnsafeBytes { String(cString: $0.bindMemory(to: CChar.self).baseAddress!) }
                .trimmingCharacters(in: CharacterSet(charactersIn: "\0 "))
            
            let size = Int(sizeString, radix: 8) ?? 0
            let typeflag = header[156]
            
            if typeflag == 0x35 { // '5' = directory
                let dirURL = outputDir.appendingPathComponent(filename)
                try? FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)
            } else if typeflag == 0x30 || typeflag == 0 { // '0' or null = regular file
                let ext = (filename as NSString).pathExtension.lowercased()
                let isImage = ["jpg", "jpeg", "png", "raw", "cr2", "nef", "arw", "dng"].contains(ext)
                
                if isImage && offset + size <= data.count {
                    let fileData = data.subdata(in: offset..<(offset + size))
                    let baseName = (filename as NSString).lastPathComponent
                    let uniqueName = UUID().uuidString + "." + ext
                    let fileURL = outputDir.appendingPathComponent(uniqueName)
                    
                    do {
                        try fileData.write(to: fileURL)
                        let photo = ReceivedPhoto(filename: baseName, fileURL: fileURL)
                        onPhotoSaved(photo)
                        savedCount += 1
                    } catch {
                        print("PhotoImportService: failed to write \(baseName): \(error)")
                    }
                }
            }
            
            offset += size
            if size % 512 != 0 {
                offset += 512 - (size % 512)
            }
        }
        
        return savedCount > 0
    }
}
