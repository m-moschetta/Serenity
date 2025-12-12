//
//  MistralClient.swift
//  Serenity
//
//  Minimal client for Mistral chat + streaming
//

import Foundation

final class MistralClient: AIProviderType {
    static let shared = MistralClient()
    private init() {}

    // Configurazione URLSession con timeout esteso
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120.0  // 2 minuti per la richiesta
        config.timeoutIntervalForResource = 300.0  // 5 minuti per la risorsa
        return URLSession(configuration: config)
    }()
    
    enum ClientError: LocalizedError {
        case invalidResponse(String)
        case timeout(String)
        var errorDescription: String? {
            switch self {
            case .invalidResponse(let msg): return msg
            case .timeout(let msg): return "Timeout: \(msg). Riprova con una connessione più stabile."
            }
        }
    }
    
    var apiKeyProvider: () -> String? = { KeychainService.shared.mistralApiKey }
    
    struct RequestBody: Codable {
        let model: String
        let messages: [MistralMessage]
        let temperature: Double?
        let max_tokens: Int?
        let stream: Bool?
    }
    
    enum MistralMessageContent: Codable {
        case string(String)
        case parts([MistralContentPart])
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let s = try? container.decode(String.self) {
                self = .string(s)
                return
            }
            if let parts = try? container.decode([MistralContentPart].self) {
                self = .parts(parts)
                return
            }
            throw DecodingError.typeMismatch(
                MistralMessageContent.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Expected string or array content")
            )
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let s): try container.encode(s)
            case .parts(let parts): try container.encode(parts)
            }
        }
    }
    
    struct MistralContentPart: Codable {
        let type: String // "text" | "image_url"
        let text: String?
        let image_url: MistralImageURL?
    }
    
    struct MistralImageURL: Codable {
        let url: String
    }
    
    struct MistralMessage: Codable {
        let role: String
        let content: MistralMessageContent
        
        var contentText: String {
            switch content {
            case .string(let s): return s
            case .parts(let parts): return parts.compactMap { $0.text }.joined()
            }
        }
    }
    
    struct Choice: Codable { let message: MistralMessage }
    struct ResponseBody: Codable { let choices: [Choice] }
    
    private func encodeMessages(_ messages: [ProviderMessage]) -> [MistralMessage] {
        messages.map(Self.encodeProviderMessage)
    }
    
    func chat(messages: [ProviderMessage], model: String, temperature: Double, maxTokens: Int) async throws -> String {
        let trimmedKey = apiKeyProvider()?.trimmingCharacters(in: .whitespacesAndNewlines)
        let endpoint = resolveEndpoint(apiKey: trimmedKey)
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        for (field, value) in endpoint.headers {
            request.addValue(value, forHTTPHeaderField: field)
        }
        let body = RequestBody(model: model, messages: encodeMessages(messages), temperature: temperature, max_tokens: maxTokens, stream: nil)
        request.httpBody = try JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                let text = String(data: data, encoding: .utf8) ?? ""
                Diagnostics.shared.lastAIError = text
                throw ClientError.invalidResponse("Mistral: \(text)")
            }
            let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
            return decoded.choices.first?.message.contentText ?? ""
        } catch {
            Diagnostics.shared.lastAIError = error.localizedDescription
            throw error
        }
    }

    private static func encodeProviderMessage(_ m: ProviderMessage) -> MistralMessage {
        if m.images.isEmpty {
            return MistralMessage(role: m.role, content: .string(m.content))
        }
        
        var parts: [MistralContentPart] = []
        let trimmed = m.content.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            parts.append(MistralContentPart(type: "text", text: m.content, image_url: nil))
        } else {
            parts.append(MistralContentPart(type: "text", text: " ", image_url: nil))
        }
        
        for img in m.images {
            let b64 = img.data.base64EncodedString()
            let uri = "data:\(img.mimeType);base64,\(b64)"
            parts.append(MistralContentPart(type: "image_url", text: nil, image_url: MistralImageURL(url: uri)))
        }
        return MistralMessage(role: m.role, content: .parts(parts))
    }
    
    private func resolveEndpoint(apiKey: String?) -> ProxyGateway.Endpoint {
        if let apiKey, !apiKey.isEmpty {
            return ProxyGateway.Endpoint(
                url: URL(string: "https://api.mistral.ai/v1/chat/completions")!,
                headers: ["Authorization": "Bearer \(apiKey)"]
            )
        }
        return ProxyGateway.endpoint(for: .mistral, pathComponents: ["v1", "chat", "completions"])
    }
    
    // streaming non utilizzato
}
