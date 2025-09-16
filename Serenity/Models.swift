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
    
    init(id: UUID = UUID(), title: String = "Parla con Serenity", createdAt: Date = .now, updatedAt: Date = .now) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
