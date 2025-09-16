//
//  ModelCatalog.swift
//  Serenity
//
//  Fetch and cache available models for providers
//

import Foundation
import Combine

final class ModelCatalog: ObservableObject {
    static let shared = ModelCatalog()
    private init() {}
    
    @Published var openaiModels: [String] = [
        "gpt-5-mini", "gpt-5",
        "gpt-4.1-mini", "gpt-4o-mini", "o4-mini",
        "gpt-4o", "gpt-4.1"
    ]
    
    @Published var mistralModels: [String] = [
        "pixtral-large-latest", "pixtral-medium-latest",
        "mistral-large-latest", "mistral-medium-latest", "mistral-small-latest"
    ]

    @Published var groqModels: [String] = [
        "llama3-8b-8192", "llama3-70b-8192", "mixtral-8x7b-32768",
        "gemma2-9b-it", "gemma-7b-it"
    ]
    
    struct OpenAIModelsResponse: Decodable { let data: [OpenAIModel] }
    struct OpenAIModel: Decodable { let id: String }
    
    struct MistralModelsResponse: Decodable { let data: [MistralModel] }
    struct MistralModel: Decodable { let id: String }

    struct GroqModelsResponse: Decodable { let data: [GroqModel] }
    struct GroqModel: Decodable { let id: String }
    
    func refreshOpenAI(apiKey: String) async throws {
        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/models")!)
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? ""
            Diagnostics.shared.lastAIError = text
            throw NSError(domain: "ModelCatalog", code: (resp as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: text])
        }
        let decoded = try JSONDecoder().decode(OpenAIModelsResponse.self, from: data)
        let sorted = decoded.data.map { $0.id }.sorted()
        await MainActor.run { self.openaiModels = sorted }
    }
    
    func refreshMistral(apiKey: String) async throws {
        var req = URLRequest(url: URL(string: "https://api.mistral.ai/v1/models")!)
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? ""
            Diagnostics.shared.lastAIError = text
            throw NSError(domain: "ModelCatalog", code: (resp as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: text])
        }
        let decoded = try JSONDecoder().decode(MistralModelsResponse.self, from: data)
        let sorted = decoded.data.map { $0.id }.sorted()
        await MainActor.run { self.mistralModels = sorted }
    }

    func refreshGroq(apiKey: String) async throws {
        var req = URLRequest(url: URL(string: "https://api.groq.com/openai/v1/models")!)
        req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? ""
            Diagnostics.shared.lastAIError = text
            throw NSError(domain: "ModelCatalog", code: (resp as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: text])
        }
        let decoded = try JSONDecoder().decode(GroqModelsResponse.self, from: data)
        let sorted = decoded.data.map { $0.id }.sorted()
        await MainActor.run { self.groqModels = sorted }
    }
}
