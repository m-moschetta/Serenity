//
//  MoodAdjectives.swift
//  Serenity
//
//  Libreria degli aggettivi per il check-in serale con declinazione di genere
//

import Foundation
import SwiftUI

enum MoodCategory: String, CaseIterable {
    case positive
    case neutral
    case negative

    var displayName: String {
        switch self {
        case .positive: return "Positivi"
        case .neutral: return "Neutrali"
        case .negative: return "Negativi"
        }
    }

    var color: Color {
        switch self {
        case .positive: return .green
        case .neutral: return .orange
        case .negative: return .red
        }
    }
}

struct MoodAdjective: Identifiable, Hashable {
    let id: String
    let masculine: String
    let feminine: String
    let neutral: String
    let category: MoodCategory
    let score: Int  // +2, +1, 0, -1, -2

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: MoodAdjective, rhs: MoodAdjective) -> Bool {
        lhs.id == rhs.id
    }
}

struct MoodAdjectivesLibrary {
    static let adjectives: [MoodAdjective] = [
        // Positivi (+2)
        MoodAdjective(id: "happy", masculine: "Felice", feminine: "Felice", neutral: "Felice", category: .positive, score: 2),
        MoodAdjective(id: "serene", masculine: "Sereno", feminine: "Serena", neutral: "Seren*", category: .positive, score: 2),
        MoodAdjective(id: "grateful", masculine: "Grato", feminine: "Grata", neutral: "Grat*", category: .positive, score: 2),
        MoodAdjective(id: "joyful", masculine: "Gioioso", feminine: "Gioiosa", neutral: "Gioios*", category: .positive, score: 2),

        // Positivi (+1)
        MoodAdjective(id: "motivated", masculine: "Motivato", feminine: "Motivata", neutral: "Motivat*", category: .positive, score: 1),
        MoodAdjective(id: "satisfied", masculine: "Soddisfatto", feminine: "Soddisfatta", neutral: "Soddisfatt*", category: .positive, score: 1),
        MoodAdjective(id: "energetic", masculine: "Energico", feminine: "Energica", neutral: "Energic*", category: .positive, score: 1),
        MoodAdjective(id: "optimistic", masculine: "Ottimista", feminine: "Ottimista", neutral: "Ottimista", category: .positive, score: 1),
        MoodAdjective(id: "peaceful", masculine: "Tranquillo", feminine: "Tranquilla", neutral: "Tranquill*", category: .positive, score: 1),
        MoodAdjective(id: "hopeful", masculine: "Fiducioso", feminine: "Fiduciosa", neutral: "Fiducios*", category: .positive, score: 1),

        // Neutrali (0)
        MoodAdjective(id: "confused", masculine: "Confuso", feminine: "Confusa", neutral: "Confus*", category: .neutral, score: 0),
        MoodAdjective(id: "tired", masculine: "Stanco", feminine: "Stanca", neutral: "Stanc*", category: .neutral, score: 0),
        MoodAdjective(id: "thoughtful", masculine: "Pensieroso", feminine: "Pensierosa", neutral: "Pensieros*", category: .neutral, score: 0),
        MoodAdjective(id: "neutral", masculine: "Indifferente", feminine: "Indifferente", neutral: "Indifferente", category: .neutral, score: 0),

        // Negativi (-1)
        MoodAdjective(id: "sad", masculine: "Triste", feminine: "Triste", neutral: "Triste", category: .negative, score: -1),
        MoodAdjective(id: "stressed", masculine: "Stressato", feminine: "Stressata", neutral: "Stressat*", category: .negative, score: -1),
        MoodAdjective(id: "frustrated", masculine: "Frustrato", feminine: "Frustrata", neutral: "Frustrat*", category: .negative, score: -1),
        MoodAdjective(id: "worried", masculine: "Preoccupato", feminine: "Preoccupata", neutral: "Preoccupat*", category: .negative, score: -1),

        // Negativi (-2)
        MoodAdjective(id: "angry", masculine: "Arrabbiato", feminine: "Arrabbiata", neutral: "Arrabbiat*", category: .negative, score: -2),
        MoodAdjective(id: "scared", masculine: "Spaventato", feminine: "Spaventata", neutral: "Spaventat*", category: .negative, score: -2),
        MoodAdjective(id: "anxious", masculine: "Ansioso", feminine: "Ansiosa", neutral: "Ansios*", category: .negative, score: -2),
        MoodAdjective(id: "desperate", masculine: "Disperato", feminine: "Disperata", neutral: "Disperat*", category: .negative, score: -2),
    ]

    static func label(for adjective: MoodAdjective, gender: String) -> String {
        switch gender {
        case "f": return adjective.feminine
        case "m": return adjective.masculine
        default: return adjective.neutral
        }
    }

    static func adjectives(for category: MoodCategory) -> [MoodAdjective] {
        adjectives.filter { $0.category == category }
    }

    static func moodEmoji(for score: Double) -> String {
        switch score {
        case 1.5...: return "😊"
        case 0.5..<1.5: return "🙂"
        case -0.5..<0.5: return "😐"
        case -1.5..<(-0.5): return "😔"
        default: return "😢"
        }
    }

    static func moodColor(for score: Double) -> Color {
        switch score {
        case 1...: return .green
        case 0..<1: return .yellow
        case -1..<0: return .orange
        default: return .red
        }
    }
}
