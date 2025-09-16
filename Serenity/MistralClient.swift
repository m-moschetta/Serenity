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
        case missingAPIKey
        case invalidResponse(String)
        case timeout(String)
        var errorDescription: String? {
            switch self {
            case .missingAPIKey: return "API key mancante (Mistral)."
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
    struct MistralMessage: Codable { let role: String; let content: String }
    struct Choice: Codable { let message: MistralMessage }
    struct ResponseBody: Codable { let choices: [Choice] }
    
    private func encodeMessages(_ messages: [ProviderMessage]) -> [MistralMessage] {
        messages.map { MistralMessage(role: $0.role, content: $0.content) }
    }
    
    func chat(messages: [ProviderMessage], model: String, temperature: Double, maxTokens: Int) async throws -> String {
        guard let apiKey = apiKeyProvider(), !apiKey.isEmpty else { throw ClientError.missingAPIKey }
        var request = URLRequest(url: URL(string: "https://api.mistral.ai/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let body = RequestBody(model: model, messages: encodeMessages(messages), temperature: temperature, max_tokens: maxTokens, stream: nil)
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? ""
            Diagnostics.shared.lastAIError = text
            throw ClientError.invalidResponse("Mistral: \(text)")
        }
        let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
        return decoded.choices.first?.message.content ?? ""
    }
    
    // streaming non utilizzato
}
