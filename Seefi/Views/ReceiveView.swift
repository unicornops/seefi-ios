import SwiftUI
import NetworkExtension

struct ReceiveView: View {
    @EnvironmentObject var appState: AppState
    @State private var isConnectingToWiFi = false
    @State private var wifiError: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    serverSection
                    instructionsSection
                    recentPhotosSection
                }
                .padding()
            }
            .navigationTitle("Receive")
            .navigationDestination(for: ReceivedPhoto.self) { photo in
                PhotoDetailView(
                    photo: photo,
                    onExportToPhotos: { exportToPhotos(photo) },
                    onExportToFiles: { exportToFiles(photo) },
                    onDelete: { appState.deletePhoto(photo) }
                )
            }
            .alert("Wi-Fi", isPresented: .constant(wifiError != nil)) {
                Button("OK") { wifiError = nil }
            } message: {
                if let error = wifiError {
                    Text(error)
                }
            }
        }
    }
    
    private func exportToPhotos(_ photo: ReceivedPhoto) {
        Task {
            try? await PhotoExportService.saveToPhotosLibrary(url: photo.fileURL)
        }
    }
    
    private func exportToFiles(_ photo: ReceivedPhoto) {
        // Use Gallery tab for full export options
    }
    
    private var serverSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Server Status")
                .font(.headline)
            
            if appState.cardProtocolServer.isRunning {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Server running on port \(CardProtocolServer.port)")
                        .font(.subheadline)
                }
                if let url = appState.cardProtocolServer.serverURL {
                    Text("Local: \(url.absoluteString)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Button("Stop Receiving") {
                    appState.cardProtocolServer.stop()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            } else {
                Button {
                    startReceiving()
                } label: {
                    Label("Start Receiving", systemImage: "play.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isConnectingToWiFi)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How to receive photos")
                .font(.headline)
            Text("1. Enter your card's Wi-Fi details in Settings.")
            Text("2. Tap Start Receiving (you'll be prompted to join the card's network).")
            Text("3. Turn on your camera and take a photo.")
            Text("4. Photos will appear here and in the Gallery tab.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }
    
    private var recentPhotosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recently received")
                .font(.headline)
            
            if appState.receivedPhotos.isEmpty {
                Text("No photos received yet.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                    ForEach(appState.receivedPhotos.prefix(12)) { photo in
                        NavigationLink(value: photo) {
                            PhotoThumbnailView(photo: photo)
                        }
                    }
                }
            }
        }
    }
    
    private func startReceiving() {
        isConnectingToWiFi = true
        wifiError = nil
        
        let config = appState.wifiConfig
        if config.isValid {
            let hotspotConfig = NEHotspotConfiguration(ssid: config.ssid, passphrase: config.password, isWEP: false)
            hotspotConfig.joinOnce = false
            
            NEHotspotConfigurationManager.shared.apply(hotspotConfig) { error in
                DispatchQueue.main.async {
                    isConnectingToWiFi = false
                    if let error = error as NSError? {
                        if error.domain == "NEHotspotConfigurationError",
                           error.code == NEHotspotConfigurationError.userDenied.rawValue {
                            wifiError = "Wi-Fi join was cancelled. Connect manually in Settings, then tap Start Receiving."
                        } else {
                            wifiError = error.localizedDescription
                        }
                    }
                    appState.cardProtocolServer.start()
                }
            }
        } else {
            isConnectingToWiFi = false
            wifiError = "Please enter your card's Wi-Fi network name and password in Settings first."
            appState.cardProtocolServer.start()
        }
    }
}

struct PhotoThumbnailView: View {
    let photo: ReceivedPhoto
    
    var body: some View {
        AsyncImage(url: photo.fileURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            case .empty:
                ProgressView()
            @unknown default:
                EmptyView()
            }
        }
        .frame(width: 80, height: 80)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
