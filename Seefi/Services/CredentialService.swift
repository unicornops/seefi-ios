import Foundation
import CommonCrypto

/// Computes credentials for Wi-Fi SD card authentication.
/// Mobi series: key is 32 zero bytes.
/// Pro series: uses upload_key from card configuration.
enum CredentialService {
    static let mobiKey = "00000000000000000000000000000000"
    
    /// Compute credential for Server→Card (StartSession response)
    /// Formula: MD5(hexToBytes(mac + cnonce + key))
    static func credentialServerToClient(mac: String, cnonce: String, key: String = mobiKey) -> String {
        let input = mac + cnonce + key
        return md5Hex(hexString: input)
    }
    
    /// Compute credential for Card→Server (GetPhotoStatus verification)
    /// Formula: MD5(hexToBytes(mac + key + snonce))
    static func credentialClientToServer(mac: String, snonce: String, key: String = mobiKey) -> String {
        let input = mac + key + snonce
        return md5Hex(hexString: input)
    }
    
    /// Convert hex string to bytes, then MD5 hash, return hex digest.
    /// Per eyefi-mobi.py: take 2 chars at a time, parse as hex, treat as byte.
    static func md5Hex(hexString: String) -> String {
        let bytes = hexStringToBytes(hexString)
        return md5(bytes).map { String(format: "%02x", $0) }.joined()
    }
    
    private static func hexStringToBytes(_ hex: String) -> [UInt8] {
        var bytes: [UInt8] = []
        let chars = Array(hex)
        var i = 0
        while i + 1 < chars.count {
            let pair = String(chars[i]) + String(chars[i + 1])
            if let byte = UInt8(pair, radix: 16) {
                bytes.append(byte)
            }
            i += 2
        }
        return bytes
    }
    
    private static func md5(_ data: [UInt8]) -> [UInt8] {
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_MD5(buffer.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest
    }
}
