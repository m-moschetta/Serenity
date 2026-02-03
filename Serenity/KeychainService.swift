//
//  KeychainService.swift
//  Serenity
//
//  Store API key securely
//

import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()
    private init() {}
    
    private let service = "Serenity.OpenAI"
    private let account = "apiKey"
    private let mistralService = "Serenity.Mistral"
    private let mistralAccount = "apiKey"
    private let groqService = "Serenity.Groq"
    private let groqAccount = "apiKey"
    private let emergencyContactService = "Serenity.EmergencyContact"

    var apiKey: String? {
        get { try? read() }
        set {
            if let newValue = newValue {
                _ = try? save(newValue)
            } else {
                _ = try? delete()
            }
        }
    }
    
    var mistralApiKey: String? {
        get { try? read(service: mistralService, account: mistralAccount) }
        set {
            if let newValue = newValue {
                _ = try? save(newValue, service: mistralService, account: mistralAccount)
            } else {
                _ = try? delete(service: mistralService, account: mistralAccount)
            }
        }
    }
    
    var groqApiKey: String? {
        get { try? read(service: groqService, account: groqAccount) }
        set {
            if let newValue = newValue {
                _ = try? save(newValue, service: groqService, account: groqAccount)
            } else {
                _ = try? delete(service: groqService, account: groqAccount)
            }
        }
    }

    var emergencyContactEmail: String? {
        get { try? read(service: emergencyContactService, account: "email") }
        set {
            if let newValue = newValue {
                _ = try? save(newValue, service: emergencyContactService, account: "email")
            } else {
                _ = try? delete(service: emergencyContactService, account: "email")
            }
        }
    }

    func save(_ value: String, service: String? = nil, account: String? = nil) throws {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service ?? self.service,
            kSecAttrAccount as String: account ?? self.account,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
    }
    
    func read(service: String? = nil, account: String? = nil) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service ?? self.service,
            kSecAttrAccount as String: account ?? self.account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { return nil }
        guard let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func delete(service: String? = nil, account: String? = nil) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service ?? self.service,
            kSecAttrAccount as String: account ?? self.account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
