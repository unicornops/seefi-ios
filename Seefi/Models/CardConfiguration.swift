import Foundation

struct CardConfiguration: Identifiable, Codable, Equatable {
    let id: UUID
    var macAddress: String
    var uploadKey: String
    var name: String
    
    init(id: UUID = UUID(), macAddress: String, uploadKey: String, name: String = "") {
        self.id = id
        self.macAddress = macAddress
        self.uploadKey = uploadKey
        self.name = name.isEmpty ? "Pro Card" : name
    }
}
