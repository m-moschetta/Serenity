//
//  GroqClient.swift
//  Serenity
//
//  Groq client (OpenAI-compatible endpoints)
//

import Foundation

final class GroqClient: AIProviderType {
    static let shared = GroqClient()
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
            case .missingAPIKey: return "API key mancante (Groq)."
            case .invalidResponse(let msg): return msg
            case .timeout(let msg): return "Timeout: \(msg). Riprova con una connessione più stabile."
            }
        }
    }
    
    var apiKeyProvider: () -> String? = { KeychainService.shared.groqApiKey }
    
    // OpenAI-like payloads with plain text content
    struct Message: Codable { let role: String; let content: String }
    struct Request: Codable {
        let model: String
        let messages: [Message]
        let temperature: Double?
        let max_tokens: Int?
        let stream: Bool?
    }
    struct Choice: Codable { let message: Message }
    struct Response: Codable { let choices: [Choice] }
    
    private func encode(_ messages: [ProviderMessage]) -> [Message] { messages.map { Message(role: $0.role, content: $0.content) } }
    
    func chat(messages: [ProviderMessage], model: String, temperature: Double, maxTokens: Int) async throws -> String {
        guard let apiKey = apiKeyProvider(), !apiKey.isEmpty else { throw ClientError.missingAPIKey }
        var request = URLRequest(url: URL(string: "https://api.groq.com/openai/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let body = Request(model: model, messages: encode(messages), temperature: temperature, max_tokens: maxTokens, stream: nil)
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? ""
            Diagnostics.shared.lastAIError = text
            throw ClientError.invalidResponse("Groq: \(text)")
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return decoded.choices.first?.message.content ?? ""
    }
    
    // streaming non utilizzato
}
