import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var receivedPhotos: [ReceivedPhoto] = []
    @Published var cardConfigurations: [CardConfiguration] = []
    @Published var wifiConfig: WiFiConfig = WiFiConfig()
    
    let cardProtocolServer: CardProtocolServer
    
    private let cardsKey = "seefi.cardConfigurations"
    private let wifiKey = "seefi.wifiConfig"
    
    init() {
        cardProtocolServer = CardProtocolServer(
            cardConfigurations: { [weak self] in self?.cardConfigurations ?? [] },
            onPhotoReceived: { [weak self] photo in
                Task { @MainActor in
                    self?.receivedPhotos.insert(photo, at: 0)
                }
            }
        )
        
        loadPersistedData()
        loadReceivedPhotosFromDisk()
    }
    
    func addPhoto(_ photo: ReceivedPhoto) {
        receivedPhotos.insert(photo, at: 0)
    }
    
    func addCardConfiguration(_ config: CardConfiguration) {
        cardConfigurations.append(config)
        persistCardConfigurations()
    }
    
    func removeCardConfiguration(_ config: CardConfiguration) {
        cardConfigurations.removeAll { $0.id == config.id }
        persistCardConfigurations()
    }
    
    func updateWiFiConfig(_ config: WiFiConfig) {
        wifiConfig = config
        UserDefaults.standard.set(try? JSONEncoder().encode(config), forKey: wifiKey)
    }
    
    func deletePhoto(_ photo: ReceivedPhoto) {
        receivedPhotos.removeAll { $0.id == photo.id }
        try? FileManager.default.removeItem(at: photo.fileURL)
    }
    
    private func persistCardConfigurations() {
        if let data = try? JSONEncoder().encode(cardConfigurations) {
            UserDefaults.standard.set(data, forKey: cardsKey)
        }
    }
    
    private func loadPersistedData() {
        if let data = UserDefaults.standard.data(forKey: cardsKey),
           let configs = try? JSONDecoder().decode([CardConfiguration].self, from: data) {
            cardConfigurations = configs
        }
        if let data = UserDefaults.standard.data(forKey: wifiKey),
           let config = try? JSONDecoder().decode(WiFiConfig.self, from: data) {
            wifiConfig = config
        }
    }
    
    private func loadReceivedPhotosFromDisk() {
        let baseURL = PhotoImportService.receivedPhotosURL
        guard let enumerator = FileManager.default.enumerator(at: baseURL, includingPropertiesForKeys: [.creationDateKey], options: [.skipsHiddenFiles]) else { return }
        
        var photos: [ReceivedPhoto] = []
        for case let url as URL in enumerator {
            guard url.pathExtension.lowercased() == "jpg" || url.pathExtension.lowercased() == "jpeg" || url.pathExtension.lowercased() == "png" else { continue }
            let resource = try? url.resourceValues(forKeys: [.creationDateKey])
            let date = resource?.creationDate ?? Date()
            photos.append(ReceivedPhoto(filename: url.lastPathComponent, fileURL: url, receivedAt: date))
        }
        receivedPhotos = photos.sorted { $0.receivedAt > $1.receivedAt }
    }
}
