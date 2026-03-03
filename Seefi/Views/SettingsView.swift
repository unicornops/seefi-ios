import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var wifiSSID = ""
    @State private var wifiPassword = ""
    @State private var showAddCard = false
    @State private var newCardMAC = ""
    @State private var newCardKey = ""
    
    var body: some View {
        NavigationStack {
            Form {
                wifiSection
                proCardsSection
            }
            .navigationTitle("Settings")
            .onAppear {
                wifiSSID = appState.wifiConfig.ssid
                wifiPassword = appState.wifiConfig.password
            }
            .onChange(of: wifiSSID) { _, newValue in
                appState.updateWiFiConfig(WiFiConfig(ssid: newValue, password: wifiPassword))
            }
            .onChange(of: wifiPassword) { _, newValue in
                appState.updateWiFiConfig(WiFiConfig(ssid: wifiSSID, password: newValue))
            }
            .sheet(isPresented: $showAddCard) {
                AddProCardSheet(
                    mac: $newCardMAC,
                    uploadKey: $newCardKey,
                    onSave: {
                        let config = CardConfiguration(
                            macAddress: newCardMAC.trimmingCharacters(in: .whitespaces),
                            uploadKey: newCardKey.trimmingCharacters(in: .whitespaces)
                        )
                        appState.addCardConfiguration(config)
                        newCardMAC = ""
                        newCardKey = ""
                        showAddCard = false
                    },
                    onCancel: {
                        newCardMAC = ""
                        newCardKey = ""
                        showAddCard = false
                    }
                )
            }
        }
    }
    
    private var wifiSection: some View {
        Section {
            TextField("Network name (SSID)", text: $wifiSSID)
                .textContentType(.none)
                .autocapitalization(.none)
            SecureField("Password", text: $wifiPassword)
                .textContentType(.password)
        } header: {
            Text("Card Wi-Fi")
        } footer: {
            Text("Enter the Wi-Fi network name and password from your card's packaging or Eye-Fi Center. Used to connect your device to the card's network.")
        }
    }
    
    private var proCardsSection: some View {
        Section {
            ForEach(appState.cardConfigurations) { config in
                VStack(alignment: .leading, spacing: 4) {
                    Text(config.name)
                        .font(.headline)
                    Text("MAC: \(config.macAddress)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        appState.removeCardConfiguration(config)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            Button {
                showAddCard = true
            } label: {
                Label("Add Pro / X2 card", systemImage: "plus.circle")
            }
        } header: {
            Text("Pro / X2 cards")
        } footer: {
            Text("Pro and X2 series cards require MAC address and upload key from Settings.xml (in Eye-Fi Center config folder). Mobi series cards work without configuration.")
        }
    }
}

struct AddProCardSheet: View {
    @Binding var mac: String
    @Binding var uploadKey: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    private var isValid: Bool {
        !mac.trimmingCharacters(in: .whitespaces).isEmpty && !uploadKey.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("MAC address", text: $mac)
                        .textContentType(.none)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    SecureField("Upload key", text: $uploadKey)
                        .textContentType(.none)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                } footer: {
                    Text("Find these in C:\\Users\\...\\AppData\\Roaming\\Eye-Fi\\Settings.xml (Windows) or ~/Library/Application Support/Eye-Fi/Settings.xml (Mac).")
                }
            }
            .navigationTitle("Add Pro card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave() }
                        .disabled(!isValid)
                }
            }
        }
    }
}
