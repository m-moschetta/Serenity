//
//  OpenAIClient.swift
//  Serenity
//
//  Minimal client for OpenAI chat + summarization
//

import Foundation

struct OpenAIMessage: Codable {
    let role: String
    let content: String?
    let tool_calls: [OpenAIToolCall]? // when function calling is used
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
    
    func chat(messages: [ProviderMessage], model: String = "gpt-4o-mini", temperature: Double = 0.4, maxTokens: Int = 800) async throws -> String {
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
            messages: messages.map { OpenAIMessage(role: $0.role, content: $0.content, tool_calls: nil) },
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
            return decoded.choices.first?.message.content ?? ""
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
            messages: messages.map { OpenAIMessage(role: $0.role, content: $0.content, tool_calls: nil) },
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
                return .content(msg?.content ?? "")
            }
        } catch {
            Diagnostics.shared.lastAIError = error.localizedDescription
            throw error
        }
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
