# Seefi – AI Agent Instructions

Project-level guidance for AI coding assistants (Cursor, Claude, GitHub Copilot).

## Project Overview

Seefi is a native iOS app that receives photos from Wi-Fi SD cards (Mobi and Pro/X2 series). Users connect their iPhone to the card's network and receive shots directly on the device.

## Architecture

- **Models** (`Seefi/Models/`): `CardConfiguration`, `WiFiConfig`, `AppState`, `ReceivedPhoto`
- **Views** (`Seefi/Views/`): SwiftUI views – `MainView`, `SettingsView`, `ReceiveView`, `PhotoGalleryView`
- **Services** (`Seefi/Services/`): `CardProtocolServer`, `CredentialService`, `PhotoImportService`, `PhotoExportService`

## Tech Stack

- **Platform**: iOS 15.0+
- **Language**: Swift 5
- **UI**: SwiftUI
- **Build**: XcodeGen (`project.yml`) – run `xcodegen generate` after changes to `project.yml`
- **Dependencies**: GCDWebServer (SOAP server), NetworkExtension (NEHotspotConfiguration)

## Conventions

- Use SwiftUI for all UI
- Prefer `@StateObject` / `@ObservedObject` for view state
- Keep networking and protocol logic in Services
- Use `async/await` where appropriate; avoid blocking the main thread

## Protocol

Implements Wi-Fi SD card SOAP protocol on port 59278: `StartSession`, `GetPhotoStatus`, `Upload`. Credential computation supports Mobi (zero key) and Pro (upload_key) variants.

## Testing

- Use a physical device; Simulator cannot receive from real cards
- Ensure proper entitlements and Info.plist usage descriptions for network and photo access
