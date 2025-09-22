//
//  ProxyGateway.swift
//  Serenity
//
//  Cloudflare proxy routing for keyless usage
//

import Foundation

enum ProxyGateway {
    static let baseURL = URL(string: "https://llm-proxy-gateway.mariomos94.workers.dev")!
    
    enum Provider: String {
        case openai
        case mistral
        case groq
    }
    
    struct Endpoint {
        let url: URL
        let headers: [String: String]
    }
    
    static func endpoint(for provider: Provider, pathComponents: [String]) -> Endpoint {
        var url = baseURL
        for component in pathComponents {
            url.appendPathComponent(component)
        }
        return Endpoint(url: url, headers: ["x-provider": provider.rawValue])
    }
}
