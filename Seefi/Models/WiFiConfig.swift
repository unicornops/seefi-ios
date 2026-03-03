import Foundation

struct WiFiConfig: Codable, Equatable {
    var ssid: String
    var password: String
    
    init(ssid: String = "", password: String = "") {
        self.ssid = ssid
        self.password = password
    }
    
    var isValid: Bool {
        !ssid.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
