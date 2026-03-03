import Foundation

struct ReceivedPhoto: Identifiable, Equatable, Hashable {
    let id: UUID
    let filename: String
    let fileURL: URL
    let receivedAt: Date
    
    init(id: UUID = UUID(), filename: String, fileURL: URL, receivedAt: Date = Date()) {
        self.id = id
        self.filename = filename
        self.fileURL = fileURL
        self.receivedAt = receivedAt
    }
}
