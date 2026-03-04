# Seefi

A native iOS app that receives photos from Wi-Fi SD cards. Connect your iPhone to your card's network and get your shots directly on your device.

## Features

- **Receive photos** from Wi-Fi SD cards (Mobi and Pro/X2 series)
- **In-app gallery** to browse received photos
- **Export options** to Photos Library or Files
- **NEHotspotConfiguration** for easy Wi-Fi connection to the card's network

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Physical device for testing (Simulator cannot receive from real cards)

## Setup

1. Clone the repository
2. Run `xcodegen generate` to create the Xcode project
3. Open `Seefi.xcodeproj` in Xcode
4. Add your Apple Developer Team in Signing & Capabilities
5. Build and run on a device

## Usage

1. **Settings**: Enter your card's Wi-Fi network name (SSID) and password. For Pro/X2 cards, add MAC address and upload key from Settings.xml.
2. **Receive**: Tap "Start Receiving" to start the server and join the card's network. Take a photo with your camera.
3. **Gallery**: View and export received photos to Photos or Files.

## Protocol

The app implements the Wi-Fi SD card SOAP protocol on port 59278:

- `StartSession` – authentication handshake
- `GetPhotoStatus` – card verification before upload
- `Upload` – multipart TAR file upload

Credential computation follows the Mobi (zero key) and Pro (upload_key) variants.

## Releases

Releases are automated with [release-please](https://github.com/googleapis/release-please-action). Use [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, etc.) in your commits; release-please will create Release PRs and, when merged, build the iOS app and attach the IPA to the GitHub release.

To enable IPA builds, add these repository secrets (aligned with [github-copilot-notify](https://github.com/unicornops/github-copilot-notify)):

| Secret | Description |
|--------|-------------|
| `APPLE_CERTIFICATE_BASE64` | Your distribution certificate (.p12), base64-encoded |
| `APPLE_CERTIFICATE_PASSWORD` | Password for the .p12 certificate |
| `APPLE_PROVISIONING_PROFILE_BASE64` | Ad-hoc provisioning profile (.mobileprovision), base64-encoded |
| `APPLE_TEAM_ID` | Your Apple Developer Team ID (10 characters) |

Convert files to base64: `base64 -i file.p12 | pbcopy`

## References

- [eyefiserver2](https://github.com/dgrant/eyefiserver2)
- [node-eyefimobiserver](https://github.com/michaelbrandt/node-eyefimobiserver)
- [EyeFi Protocol](https://github.com/tachang/EyeFiServer/blob/master/Documentation/EyeFi%20Protocol.txt)

## License

See LICENSE file.
