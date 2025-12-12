//
//  OnboardingModel.swift
//  Serenity
//
//  Data models e storage per l'onboarding
//

import Foundation

enum OnboardingQuestionKind: Equatable {
    case singleChoice
    case multiChoice(max: Int)
    case freeText(placeholder: String? = nil)
    case scale(options: [String])
}

struct OnboardingOption: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String?
    let triggersSafety: Bool

    init(id: String, title: String, detail: String? = nil, triggersSafety: Bool = false) {
        self.id = id
        self.title = title
        self.detail = detail
        self.triggersSafety = triggersSafety
    }
}

struct OnboardingQuestion: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let kind: OnboardingQuestionKind
    let options: [OnboardingOption]
    let maxSelection: Int
    let reason: OnboardingReason?

    init(
        id: String,
        title: String,
        subtitle: String? = nil,
        kind: OnboardingQuestionKind,
        options: [OnboardingOption] = [],
        reason: OnboardingReason? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.kind = kind
        self.options = options
        switch kind {
        case .multiChoice(let max):
            self.maxSelection = max
        default:
            self.maxSelection = 1
        }
        self.reason = reason
    }
}

enum OnboardingReason: String, CaseIterable, Identifiable, Codable {
    case anxiety
    case sadness
    case parenting
    case growth
    case relationship
    case genderIdentity
    case sexuality
    case lifeEvent
    case workStudy
    case foodBody
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .anxiety: return "Provo spesso stati d’ansia"
        case .sadness: return "Mi sento triste e giù di morale"
        case .parenting: return "Ho difficoltà con mio figlio / mia figlia"
        case .growth: return "Voglio crescere come persona"
        case .relationship: return "Ho difficoltà con la mia relazione"
        case .genderIdentity: return "Voglio esplorare la mia identità di genere"
        case .sexuality: return "Riguarda la sfera sessuale"
        case .lifeEvent: return "È successa una cosa che mi ha cambiato"
        case .workStudy: return "Sto avendo problemi con il lavoro o lo studio"
        case .foodBody: return "Penso di avere un problema con il cibo"
        case .other: return "Per un motivo diverso"
        }
    }
}

struct OnboardingAnswer: Codable, Hashable {
    let questionId: String
    let question: String
    let answers: [String]
    let reason: OnboardingReason?
    let isSafetyRelated: Bool
}

struct OnboardingProfile: Codable {
    var createdAt: Date
    var answers: [OnboardingAnswer]
    var primaryReason: OnboardingReason?
    var otherReasons: [OnboardingReason]
    var safetyFlag: Bool

    func summaryText() -> String {
        var lines: [String] = []
        lines.append("Profilo onboarding (usa queste informazioni per contestualizzare tono e suggerimenti, non per fare diagnosi):")

        let commonKeys: Set<String> = ["q0_gender", "q0_age", "q0_history", "q0_meds"]
        let common = answers.filter { commonKeys.contains($0.questionId) }
        for ans in common {
            if let first = ans.answers.first {
                lines.append("- \(ans.question): \(first)")
            }
        }

        if let main = primaryReason {
            let others = otherReasons.map { $0.label }
            let otherText = others.isEmpty ? "" : " | Altri: \(others.joined(separator: ", "))"
            lines.append("- Motivo principale: \(main.label)\(otherText)")
        }

        let grouped = Dictionary(grouping: answers.filter { !commonKeys.contains($0.questionId) && !["q1_root", "safety_check"].contains($0.questionId) }, by: { $0.reason })
        for (reason, entries) in grouped.sorted(by: { ($0.key?.label ?? "") < ($1.key?.label ?? "") }) {
            guard let reason else { continue }
            let joined = entries.map { "\($0.question): \($0.answers.joined(separator: ", "))" }.joined(separator: " | ")
            if !joined.isEmpty {
                lines.append("- \(reason.label): \(joined)")
            }
        }

        if safetyFlag {
            lines.append("- Segnali di forte compromissione emersi in onboarding: SÌ (mantieni attenzione e valuta tono più protettivo).")
        }

        return lines.joined(separator: "\n")
    }
}

final class OnboardingStorage {
    static let shared = OnboardingStorage()

    private let dataKey = "onboardingProfileData"
    private let completedKey = "onboardingCompleted"
    private let summaryKey = "onboardingSummary"
    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save(profile: OnboardingProfile) {
        do {
            let data = try JSONEncoder().encode(profile)
            defaults.set(data, forKey: dataKey)
            defaults.set(true, forKey: completedKey)
            defaults.set(profile.summaryText(), forKey: summaryKey)
        } catch {
            print("Onboarding save error: \(error)")
        }
    }

    func loadProfile() -> OnboardingProfile? {
        guard let data = defaults.data(forKey: dataKey) else { return nil }
        do {
            return try JSONDecoder().decode(OnboardingProfile.self, from: data)
        } catch {
            print("Onboarding decode error: \(error)")
            return nil
        }
    }

    func markIncomplete() {
        defaults.set(false, forKey: completedKey)
    }

    func clear() {
        defaults.removeObject(forKey: dataKey)
        defaults.removeObject(forKey: summaryKey)
        defaults.set(false, forKey: completedKey)
    }

    var summary: String {
        defaults.string(forKey: summaryKey) ?? ""
    }

    var isCompleted: Bool {
        defaults.bool(forKey: completedKey)
    }
}
