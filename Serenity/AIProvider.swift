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
    let images: [ProviderImage]

    init(role: String, content: String, images: [ProviderImage] = []) {
        self.role = role
        self.content = content
        self.images = images
    }
}

struct ProviderImage {
    let mimeType: String // e.g. "image/jpeg"
    let data: Data
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

    // Helper per aggiungere il prompt terapeutico come messaggio di sistema
    func prepareMessages(userMessages: [ProviderMessage]) -> [ProviderMessage] {
        var messages = [ProviderMessage]()

        // Build the complete system prompt with tone instructions
        let basePrompt = TherapeuticPrompt.systemPrompt
        let toneInstructions = TonePreferences.shared.buildToneInstructions()

        // Get onboarding context if available
        let onboardingContext = OnboardingStorage.shared.summary

        // Combine: base prompt + tone instructions + onboarding context
        var fullSystemPrompt = basePrompt + "\n\n" + toneInstructions
        if !onboardingContext.isEmpty {
            fullSystemPrompt += "\n\n" + onboardingContext
        }

        // Aggiungi il prompt di sistema completo
        messages.append(ProviderMessage(role: "system", content: fullSystemPrompt))

        // Aggiungi i messaggi dell'utente
        messages.append(contentsOf: userMessages)

        return messages
    }

    // Metodo per chat con rilevamento di crisi LLM-based
    func chatWithCrisisDetection(messages: [ProviderMessage], model: String = "gpt-5.2", temperature: Double = 0.4, maxTokens: Int = 800) async throws -> String {
        // Controlla se l'ultimo messaggio dell'utente contiene segnali di crisi usando LLM
        if let lastUserMessage = messages.last(where: { $0.role == "user" }) {
            let isCrisis = await CrisisDetection.detectCrisis(in: lastUserMessage.content, using: self)
            if isCrisis {
                return CrisisDetection.crisisResponse
            }
        }

        // Prepara i messaggi con il prompt terapeutico
        let preparedMessages = prepareMessages(userMessages: messages)

        // Chiama il provider appropriato
        return try await provider().chat(messages: preparedMessages, model: model, temperature: temperature, maxTokens: maxTokens)
    }
}
