import Foundation
import GCDWebServers

/// HTTP server implementing the Wi-Fi SD card SOAP protocol on port 59278.
final class CardProtocolServer: ObservableObject {
    static let port: UInt = 59278
    
    private var webServer: GCDWebServer?
    private var currentSnonce: String?
    private var cardConfigurations: () -> [CardConfiguration]
    private var onPhotoReceived: (ReceivedPhoto) -> Void
    
    @Published private(set) var isRunning = false
    @Published private(set) var serverURL: URL?
    
    init(
        cardConfigurations: @escaping () -> [CardConfiguration],
        onPhotoReceived: @escaping (ReceivedPhoto) -> Void
    ) {
        self.cardConfigurations = cardConfigurations
        self.onPhotoReceived = onPhotoReceived
    }
    
    func start() {
        guard webServer == nil else { return }
        
        let server = GCDWebServer()
        
        // SOAP endpoint - dispatch by SOAPAction header
        server.addDefaultHandler(forMethod: "POST", request: GCDWebServerDataRequest.self) { [weak self] request in
            guard let self = self else { return nil }
            let dataRequest = request as! GCDWebServerDataRequest
            let soapAction = request.headers["Soapaction"] ?? request.headers["SOAPAction"] ?? ""
            
            if request.path == "/api/soap/eyefilm/v1" {
                if soapAction.contains("StartSession") {
                    return self.handleStartSession(body: dataRequest.data)
                }
                if soapAction.contains("GetPhotoStatus") {
                    return self.handleGetPhotoStatus(body: dataRequest.data)
                }
                if soapAction.contains("MarkLastPhotoInRoll") {
                    return self.handleMarkLastPhotoInRoll()
                }
            }
            
            if request.path == "/api/soap/eyefilm/v1/upload" {
                return nil // Handled by multipart handler
            }
            
            return GCDWebServerDataResponse(data: Data(), contentType: "text/xml")
        }
        
        // Multipart upload handler
        server.addHandler(forMethod: "POST", path: "/api/soap/eyefilm/v1/upload", request: GCDWebServerMultiPartFormRequest.self) { [weak self] request in
            guard let self = self else { return nil }
            let multipartRequest = request as! GCDWebServerMultiPartFormRequest
            return self.handleUpload(multipartRequest: multipartRequest)
        }
        
        let options: [String: Any] = [
            GCDWebServerOption_Port: Self.port,
            GCDWebServerOption_BindToLocalhost: false
        ]
        
        do {
            try server.start(options: options)
            webServer = server
            isRunning = true
            serverURL = server.serverURL
        } catch {
            print("CardProtocolServer failed to start: \(error)")
        }
    }
    
    func stop() {
        webServer?.stop()
        webServer = nil
        currentSnonce = nil
        isRunning = false
        serverURL = nil
    }
    
    // MARK: - Handlers
    
    private func handleStartSession(body: Data?) -> GCDWebServerDataResponse {
        guard let body = body,
              let xml = String(data: body, encoding: .utf8),
              let mac = extractXMLValue(xml, tag: "macaddress"),
              let cnonce = extractXMLValue(xml, tag: "cnonce"),
              let transfermode = extractXMLValue(xml, tag: "transfermode"),
              let transfermodetimestamp = extractXMLValue(xml, tag: "transfermodetimestamp") else {
            return errorResponse()
        }
        
        let key = keyForMAC(mac)
        let credential = CredentialService.credentialServerToClient(mac: mac, cnonce: cnonce, key: key)
        let snonce = randomHexString(length: 32)
        currentSnonce = snonce
        
        let responseXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
        <SOAP-ENV:Body>
        <StartSessionResponse xmlns="http://localhost/api/soap/eyefilm">
        <credential>\(credential)</credential>
        <snonce>\(snonce)</snonce>
        <transfermode>\(transfermode)</transfermode>
        <transfermodetimestamp>\(transfermodetimestamp)</transfermodetimestamp>
        <upsyncallowed>false</upsyncallowed>
        </StartSessionResponse>
        </SOAP-ENV:Body>
        </SOAP-ENV:Envelope>
        """
        
        return xmlResponse(responseXML)
    }
    
    private func handleGetPhotoStatus(body: Data?) -> GCDWebServerDataResponse {
        guard let body = body,
              let xml = String(data: body, encoding: .utf8),
              let credential = extractXMLValue(xml, tag: "credential"),
              let mac = extractXMLValue(xml, tag: "macaddress"),
              let snonce = currentSnonce else {
            return errorResponse()
        }
        
        let key = keyForMAC(mac)
        let expected = CredentialService.credentialClientToServer(mac: mac, snonce: snonce, key: key)
        
        guard credential == expected else {
            return GCDWebServerDataResponse(data: "Nice try!".data(using: .utf8)!, contentType: "text/plain")
        }
        
        let responseXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
        <SOAP-ENV:Body>
        <GetPhotoStatusResponse xmlns="http://localhost/api/soap/eyefilm">
        <fileid>1</fileid>
        <offset>0</offset>
        </GetPhotoStatusResponse>
        </SOAP-ENV:Body>
        </SOAP-ENV:Envelope>
        """
        
        return xmlResponse(responseXML)
    }
    
    private func handleMarkLastPhotoInRoll() -> GCDWebServerDataResponse {
        let responseXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
        <SOAP-ENV:Body>
        <MarkLastPhotoInRollResponse xmlns="http://localhost/api/soap/eyefilm"/>
        </SOAP-ENV:Body>
        </SOAP-ENV:Envelope>
        """
        return xmlResponse(responseXML)
    }
    
    private func handleUpload(multipartRequest: GCDWebServerMultiPartFormRequest) -> GCDWebServerDataResponse {
        guard let soapArg = multipartRequest.firstArgument(forControlName: "SOAPENVELOPE"),
              let soapEnvelope = soapArg.string,
              let filename = extractXMLValue(soapEnvelope, tag: "filename") else {
            return errorResponse()
        }
        
        let tarData: Data?
        if let filePart = multipartRequest.firstFile(forControlName: "FILENAME") {
            tarData = try? Data(contentsOf: URL(fileURLWithPath: filePart.temporaryPath))
        } else if let argPart = multipartRequest.firstArgument(forControlName: "FILENAME") {
            tarData = argPart.data
        } else {
            tarData = nil
        }
        
        guard let data = tarData else {
            return errorResponse()
        }
        
        let success = PhotoImportService.extractAndSave(
            tarData: data,
            originalFilename: filename,
            onPhotoSaved: { [weak self] photo in
                DispatchQueue.main.async {
                    self?.onPhotoReceived(photo)
                }
            }
        )
        
        let responseXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
        <SOAP-ENV:Body>
        <UploadPhotoResponse xmlns="http://localhost/api/soap/eyefilm">
        <success>\(success ? "true" : "false")</success>
        </UploadPhotoResponse>
        </SOAP-ENV:Body>
        </SOAP-ENV:Envelope>
        """
        
        return xmlResponse(responseXML)
    }
    
    private func keyForMAC(_ mac: String) -> String {
        let configs = cardConfigurations()
        return configs.first { $0.macAddress.lowercased() == mac.lowercased() }?.uploadKey ?? "00000000000000000000000000000000"
    }
    
    private func extractXMLValue(_ xml: String, tag: String) -> String? {
        let patterns = [
            "<\(tag)>([^<]*)</\(tag)>",
            "<[^:]+:\(tag)>([^<]*)</[^:]+:\(tag)>"
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: xml, range: NSRange(xml.startIndex..., in: xml)),
               let range = Range(match.range(at: 1), in: xml) {
                return String(xml[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }
    
    private func randomHexString(length: Int) -> String {
        (0..<length).map { _ in String(format: "%x", Int.random(in: 0..<16)) }.joined()
    }
    
    private func xmlResponse(_ xml: String) -> GCDWebServerDataResponse {
        let data = xml.data(using: .utf8)!
        return GCDWebServerDataResponse(data: data, contentType: "text/xml; charset=\"utf-8\"")
    }
    
    private func errorResponse() -> GCDWebServerDataResponse {
        GCDWebServerDataResponse(data: Data(), contentType: "text/xml")
    }
}
