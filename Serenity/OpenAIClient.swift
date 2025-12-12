//
//  OpenAIClient.swift
//  Serenity
//
//  Minimal client for OpenAI chat + summarization
//

import Foundation

enum OpenAIMessageContent: Codable {
    case string(String)
    case parts([OpenAIContentPart])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let s = try? container.decode(String.self) {
            self = .string(s)
            return
        }
        if let parts = try? container.decode([OpenAIContentPart].self) {
            self = .parts(parts)
            return
        }
        throw DecodingError.typeMismatch(
            OpenAIMessageContent.self,
            .init(codingPath: decoder.codingPath, debugDescription: "Expected string or array content")
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s):
            try container.encode(s)
        case .parts(let parts):
            try container.encode(parts)
        }
    }
}

struct OpenAIContentPart: Codable {
    let type: String // "text" | "image_url"
    let text: String?
    let image_url: OpenAIImageURL?
}

struct OpenAIImageURL: Codable {
    let url: String
}

struct OpenAIMessage: Codable {
    let role: String
    let content: OpenAIMessageContent?
    let tool_calls: [OpenAIToolCall]? // when function calling is used

    var contentText: String {
        switch content {
        case .string(let s): return s
        case .parts(let parts):
            return parts.compactMap { $0.text }.joined()
        case .none:
            return ""
        }
    }
}

struct OpenAIToolCall: Codable {
    let id: String
    let type: String // "function"
    let function: OpenAIToolFunctionCall
}

struct OpenAIToolFunctionCall: Codable {
    let name: String
    let arguments: String // JSON string
}

struct ChatCompletionsRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double?
    let max_tokens: Int?
    let stream: Bool?
    let tools: [OpenAITool]?
    let tool_choice: String? // "auto"
}

struct ChatChoice: Codable {
    let index: Int
    let message: OpenAIMessage
}

struct ChatCompletionsResponse: Codable {
    let choices: [ChatChoice]
}

// MARK: - Tools

struct OpenAITool: Codable {
    let type: String // "function"
    let function: OpenAIToolFunction
}

struct OpenAIToolFunction: Codable {
    let name: String
    let description: String
    let parameters: JSONSchema
}

struct JSONSchema: Codable {
    let type: String // "object"
    let properties: [String: JSONSchemaProperty]
    let required: [String]
}

struct JSONSchemaProperty: Codable {
    let type: String
    let description: String?
}

final class OpenAIClient: AIProviderType {
    static let shared = OpenAIClient()
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
    
    var apiKeyProvider: () -> String? = { KeychainService.shared.apiKey }
    
    func chat(messages: [ProviderMessage], model: String = "gpt-5.2", temperature: Double = 0.4, maxTokens: Int = 800) async throws -> String {
        let trimmedKey = apiKeyProvider()?.trimmingCharacters(in: .whitespacesAndNewlines)
        let endpoint = resolveEndpoint(apiKey: trimmedKey)
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        for (field, value) in endpoint.headers {
            request.addValue(value, forHTTPHeaderField: field)
        }
        let body = ChatCompletionsRequest(
            model: model,
            messages: messages.map(Self.encodeProviderMessage),
            temperature: temperature,
            max_tokens: maxTokens,
            stream: nil,
            tools: nil,
            tool_choice: nil
        )
        request.httpBody = try JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                let text = String(data: data, encoding: .utf8) ?? ""
                Diagnostics.shared.lastAIError = text
                throw ClientError.invalidResponse("OpenAI: \(text)")
            }
            let decoded = try JSONDecoder().decode(ChatCompletionsResponse.self, from: data)
            return decoded.choices.first?.message.contentText ?? ""
        } catch {
            Diagnostics.shared.lastAIError = error.localizedDescription
            throw error
        }
    }

    enum ChatResult { case content(String); case tool(name: String, argumentsJSON: String) }

    func chatWithTools(messages: [ProviderMessage], model: String, temperature: Double, maxTokens: Int, tools: [OpenAITool]) async throws -> ChatResult {
        let trimmedKey = apiKeyProvider()?.trimmingCharacters(in: .whitespacesAndNewlines)
        let endpoint = resolveEndpoint(apiKey: trimmedKey)
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        for (field, value) in endpoint.headers {
            request.addValue(value, forHTTPHeaderField: field)
        }
        let body = ChatCompletionsRequest(
            model: model,
            messages: messages.map(Self.encodeProviderMessage),
            temperature: temperature,
            max_tokens: maxTokens,
            stream: nil,
            tools: tools,
            tool_choice: "auto"
        )
        request.httpBody = try JSONEncoder().encode(body)

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                let text = String(data: data, encoding: .utf8) ?? ""
                Diagnostics.shared.lastAIError = text
                throw ClientError.invalidResponse("OpenAI: \(text)")
            }
            let decoded = try JSONDecoder().decode(ChatCompletionsResponse.self, from: data)
            let msg = decoded.choices.first?.message
            if let tool = msg?.tool_calls?.first {
                return .tool(name: tool.function.name, argumentsJSON: tool.function.arguments)
            } else {
                return .content(msg?.contentText ?? "")
            }
        } catch {
            Diagnostics.shared.lastAIError = error.localizedDescription
            throw error
        }
    }

    private static func encodeProviderMessage(_ m: ProviderMessage) -> OpenAIMessage {
        if m.images.isEmpty {
            return OpenAIMessage(role: m.role, content: .string(m.content), tool_calls: nil)
        }

        var parts: [OpenAIContentPart] = []
        let trimmed = m.content.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            parts.append(OpenAIContentPart(type: "text", text: m.content, image_url: nil))
        } else {
            // alcuni modelli si comportano meglio con almeno un part testuale
            parts.append(OpenAIContentPart(type: "text", text: " ", image_url: nil))
        }

        for img in m.images {
            let b64 = img.data.base64EncodedString()
            let uri = "data:\(img.mimeType);base64,\(b64)"
            parts.append(OpenAIContentPart(type: "image_url", text: nil, image_url: OpenAIImageURL(url: uri)))
        }
        return OpenAIMessage(role: m.role, content: .parts(parts), tool_calls: nil)
    }
    
    private func resolveEndpoint(apiKey: String?) -> ProxyGateway.Endpoint {
        if let apiKey, !apiKey.isEmpty {
            return ProxyGateway.Endpoint(
                url: URL(string: "https://api.openai.com/v1/chat/completions")!,
                headers: ["Authorization": "Bearer \(apiKey)"]
            )
        }
        return ProxyGateway.endpoint(for: .openai, pathComponents: ["v1", "chat", "completions"])
    }
}
