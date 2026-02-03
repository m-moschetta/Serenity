//
//  EmergencyEmailService.swift
//  Serenity
//
//  Service for sending crisis alert emails via worker endpoint
//

import Foundation

final class EmergencyEmailService {
    static let shared = EmergencyEmailService()
    private init() {}

    // Worker endpoint (to be configured by user - can be updated in settings later)
    // TODO: Replace with actual worker URL once deployed
    private let workerEndpoint = "https://YOUR_WORKER_URL/send-crisis-email"

    struct EmailRequest: Codable {
        let toEmail: String
        let userName: String
    }

    struct EmailResponse: Codable {
        let success: Bool
        let message: String?
    }

    /// Sends crisis alert email via worker endpoint
    /// - Parameters:
    ///   - email: Emergency contact email address
    ///   - userName: User's name (or default text if not provided)
    /// - Throws: EmailError if sending fails
    func sendCrisisAlert(to email: String, userName: String) async throws {
        let emailRequest = EmailRequest(
            toEmail: email,
            userName: userName
        )

        guard let url = URL(string: workerEndpoint) else {
            throw EmailError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(emailRequest)
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EmailError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw EmailError.sendFailed(statusCode: httpResponse.statusCode)
        }

        // Optional: Parse response for success confirmation
        if let emailResponse = try? JSONDecoder().decode(EmailResponse.self, from: data) {
            if !emailResponse.success {
                throw EmailError.workerError(message: emailResponse.message ?? "Unknown error")
            }
        }
    }

    enum EmailError: Error, LocalizedError {
        case invalidEndpoint
        case invalidResponse
        case sendFailed(statusCode: Int)
        case workerError(message: String)

        var errorDescription: String? {
            switch self {
            case .invalidEndpoint:
                return "Worker endpoint URL non valido"
            case .invalidResponse:
                return "Risposta non valida dal server"
            case .sendFailed(let statusCode):
                return "Invio email fallito (codice: \(statusCode))"
            case .workerError(let message):
                return "Errore worker: \(message)"
            }
        }
    }
}
