//
//  Models.swift
//  Serenity
//
//  Chat models and persistence using SwiftData
//

import Foundation
import SwiftData

enum ChatRole: String, Codable, CaseIterable {
    case user
    case assistant
    case system
}

@Model
final class ChatMessage {
    var id: UUID
    var role: ChatRole
    var content: String
    var createdAt: Date
    
    @Relationship(inverse: \Conversation.messages)
    var conversation: Conversation?
    
    @Relationship(deleteRule: .cascade)
    var attachments: [Attachment] = []
    
    init(id: UUID = UUID(), role: ChatRole, content: String, createdAt: Date = .now, conversation: Conversation? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
        self.conversation = conversation
    }
}

enum AttachmentType: String, Codable, CaseIterable { case image }

@Model
final class Attachment {
    var id: UUID
    var type: AttachmentType
    var localPath: String // relative file path in app documents
    var createdAt: Date
    
    @Relationship(inverse: \ChatMessage.attachments)
    var message: ChatMessage?
    
    init(id: UUID = UUID(), type: AttachmentType, localPath: String, createdAt: Date = .now, message: ChatMessage? = nil) {
        self.id = id
        self.type = type
        self.localPath = localPath
        self.createdAt = createdAt
        self.message = message
    }
}

@Model
final class MemorySummary {
    var id: UUID
    var createdAt: Date
    var content: String
    var messageCount: Int
    
    @Relationship(inverse: \Conversation.memories)
    var conversation: Conversation?
    
    init(id: UUID = UUID(), createdAt: Date = .now, content: String, messageCount: Int, conversation: Conversation? = nil) {
        self.id = id
        self.createdAt = createdAt
        self.content = content
        self.messageCount = messageCount
        self.conversation = conversation
    }
}

@Model
final class Conversation {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade)
    var messages: [ChatMessage] = []
    
    @Relationship(deleteRule: .cascade)
    var memories: [MemorySummary] = []

    init(id: UUID = UUID(), title: String = "Tranquiz", createdAt: Date = .now, updatedAt: Date = .now) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class OverviewReportLog {
    var id: UUID
    var createdAt: Date
    var provider: String
    var model: String
    var temperature: Double
    var maxTokens: Int
    var prompt: String
    var payload: String
    var response: String
    var outputFormat: String

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        provider: String,
        model: String,
        temperature: Double,
        maxTokens: Int,
        prompt: String,
        payload: String,
        response: String,
        outputFormat: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.provider = provider
        self.model = model
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.prompt = prompt
        self.payload = payload
        self.response = response
        self.outputFormat = outputFormat
    }
}

// Helper per ottenere un ModelContext condiviso fuori dall'albero SwiftUI
enum ModelContextContainer {
    static func sharedContext() throws -> ModelContext {
        let schema = Schema([
            Conversation.self,
            ChatMessage.self,
            MemorySummary.self,
            Attachment.self,
            OverviewReportLog.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [modelConfiguration]).mainContext
    }
}
