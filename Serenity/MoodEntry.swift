//
//  MoodEntry.swift
//  Serenity
//
//  Modello SwiftData per salvare i check-in dell'umore
//

import Foundation
import SwiftData

enum CheckInType: String, Codable, CaseIterable {
    case morning
    case evening
    case weekly

    var displayName: String {
        switch self {
        case .morning: return "Mattutino"
        case .evening: return "Serale"
        case .weekly: return "Settimanale"
        }
    }

    var icon: String {
        switch self {
        case .morning: return "sun.max.fill"
        case .evening: return "moon.fill"
        case .weekly: return "calendar"
        }
    }
}

@Model
final class MoodEntry {
    var id: UUID
    var date: Date
    var checkInTypeRaw: String
    var moodScore: Int  // -2 a +2 per calcolo grafico

    // Evening check-in
    var selectedMoodIds: [String]

    // Morning check-in
    var morningMotivation: String?
    var morningFear: String?

    // Weekly
    var weeklyAIResponse: String?
    var weeklyMoodSummary: String?

    var createdAt: Date

    var checkInType: CheckInType {
        get { CheckInType(rawValue: checkInTypeRaw) ?? .evening }
        set { checkInTypeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        date: Date = .now,
        checkInType: CheckInType,
        moodScore: Int = 0,
        selectedMoodIds: [String] = [],
        morningMotivation: String? = nil,
        morningFear: String? = nil,
        weeklyAIResponse: String? = nil,
        weeklyMoodSummary: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.checkInTypeRaw = checkInType.rawValue
        self.moodScore = moodScore
        self.selectedMoodIds = selectedMoodIds
        self.morningMotivation = morningMotivation
        self.morningFear = morningFear
        self.weeklyAIResponse = weeklyAIResponse
        self.weeklyMoodSummary = weeklyMoodSummary
        self.createdAt = createdAt
    }

    // Helper per calcolare moodScore dagli aggettivi
    static func calculateScore(from moodIds: [String]) -> Int {
        guard !moodIds.isEmpty else { return 0 }
        let adjectives = MoodAdjectivesLibrary.adjectives
        var total = 0
        var count = 0
        for id in moodIds {
            if let adj = adjectives.first(where: { $0.id == id }) {
                total += adj.score
                count += 1
            }
        }
        return count > 0 ? Int(round(Double(total) / Double(count))) : 0
    }
}
