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

## References

- [eyefiserver2](https://github.com/dgrant/eyefiserver2)
- [node-eyefimobiserver](https://github.com/michaelbrandt/node-eyefimobiserver)
- [EyeFi Protocol](https://github.com/tachang/EyeFiServer/blob/master/Documentation/EyeFi%20Protocol.txt)

## License

See LICENSE file.
