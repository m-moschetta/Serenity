//
//  AIProvider.swift
//  Serenity
//
//  Abstraction for multiple LLM providers (OpenAI, Mistral)
//

import Foundation

struct ProviderMessage {
    let role: String // "system" | "user" | "assistant"
    let content: String
}

protocol AIProviderType {
    func chat(messages: [ProviderMessage], model: String, temperature: Double, maxTokens: Int) async throws -> String
}

enum AIProviderChoice: String {
    case openai
    case mistral
    case groq
}

enum AIProviderError: Error { case unsupported }

final class AIService {
    static let shared = AIService()
    private init() {}
    
    var providerChoice: AIProviderChoice {
        AIProviderChoice(rawValue: UserDefaults.standard.string(forKey: "aiProvider") ?? "openai") ?? .openai
    }
    
    func provider() -> AIProviderType {
        switch providerChoice {
        case .openai: return OpenAIClient.shared
        case .mistral: return MistralClient.shared
        case .groq: return GroqClient.shared
        }
    }
}
