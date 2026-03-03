import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView {
            ReceiveView()
                .environmentObject(appState)
                .tabItem {
                    Label("Receive", systemImage: "antenna.radiowaves.left.and.right")
                }
            
            PhotoGalleryView()
                .environmentObject(appState)
                .tabItem {
                    Label("Gallery", systemImage: "photo.on.rectangle.angled")
                }
            
            SettingsView()
                .environmentObject(appState)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
