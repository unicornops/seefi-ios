import SwiftUI
import UIKit

struct PhotoGalleryView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedPhoto: ReceivedPhoto?
    @State private var showExportSheet = false
    @State private var exportPhoto: ReceivedPhoto?
    @State private var showSaveSuccess = false
    
    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 4)]
    
    var body: some View {
        NavigationStack {
            Group {
                if appState.receivedPhotos.isEmpty {
                    ContentUnavailableView(
                        "No photos yet",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text("Photos received from your Wi-Fi SD card will appear here.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 4) {
                            ForEach(appState.receivedPhotos) { photo in
                                Button {
                                    selectedPhoto = photo
                                } label: {
                                    GalleryThumbnailView(photo: photo)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(4)
                    }
                }
            }
            .navigationTitle("Gallery")
            .navigationDestination(item: $selectedPhoto) { photo in
                PhotoDetailView(
                    photo: photo,
                    onExportToPhotos: { exportToPhotos(photo) },
                    onExportToFiles: { exportToFiles(photo) },
                    onDelete: {
                        appState.deletePhoto(photo)
                        selectedPhoto = nil
                    }
                )
            }
            .sheet(isPresented: $showExportSheet) {
                if let photo = exportPhoto {
                    ShareSheet(items: [photo.fileURL])
                }
            }
            .overlay {
                if showSaveSuccess {
                    Text("Saved to Photos")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
    
    private func exportToPhotos(_ photo: ReceivedPhoto) {
        Task {
            do {
                try await PhotoExportService.saveToPhotosLibrary(url: photo.fileURL)
                await MainActor.run {
                    showSaveSuccess = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showSaveSuccess = false
                    }
                }
            } catch {
                print("Export to Photos failed: \(error)")
            }
        }
    }
    
    private func exportToFiles(_ photo: ReceivedPhoto) {
        exportPhoto = photo
        showExportSheet = true
    }
}

struct GalleryThumbnailView: View {
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
                Color.gray.opacity(0.2)
            @unknown default:
                EmptyView()
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .clipped()
    }
}

struct PhotoDetailView: View {
    let photo: ReceivedPhoto
    let onExportToPhotos: () -> Void
    let onExportToFiles: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                AsyncImage(url: photo.fileURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    case .empty:
                        ProgressView()
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                
                Text(photo.filename)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 12) {
                    Button {
                        onExportToPhotos()
                    } label: {
                        Label("Save to Photos", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button {
                        onExportToFiles()
                    } label: {
                        Label("Export to Files", systemImage: "folder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Photo")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [URL]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
