//
//  TonePreferences.swift
//  Serenity
//
//  Preferenze per la personalizzazione del tono di voce dell'assistente
//

import Foundation
import SwiftUI

// MARK: - Tone Preference Keys

enum TonePreferenceKey {
    static let empathy = "pref_tone_empathy"
    static let approach = "pref_tone_approach"
    static let energy = "pref_tone_energy"
    static let mood = "pref_tone_mood"
    static let length = "pref_tone_length"
    static let style = "pref_tone_style"
}

// MARK: - Tone Option Enums

enum ToneEmpathy: String, CaseIterable {
    case empathetic = "empathetic"
    case neutral = "neutral"

    var label: String {
        switch self {
        case .empathetic: return "Empatico"
        case .neutral: return "Neutro"
        }
    }

    var instruction: String {
        switch self {
        case .empathetic: return "Sii empatico, comprensivo e accogliente"
        case .neutral: return "Sii neutro, oggettivo e pratico"
        }
    }
}

enum ToneApproach: String, CaseIterable {
    case gentle = "gentle"
    case direct = "direct"

    var label: String {
        switch self {
        case .gentle: return "Gentile"
        case .direct: return "Diretto"
        }
    }

    var instruction: String {
        switch self {
        case .gentle: return "Usa un approccio gentile e delicato"
        case .direct: return "Sii diretto e vai al punto"
        }
    }
}

enum ToneEnergy: String, CaseIterable {
    case calm = "calm"
    case energetic = "energetic"

    var label: String {
        switch self {
        case .calm: return "Calmo"
        case .energetic: return "Energico"
        }
    }

    var instruction: String {
        switch self {
        case .calm: return "Mantieni un tono calmo e riflessivo"
        case .energetic: return "Sii energico, motivante e incoraggiante"
        }
    }
}

enum ToneMood: String, CaseIterable {
    case serious = "serious"
    case light = "light"

    var label: String {
        switch self {
        case .serious: return "Serio"
        case .light: return "Leggero"
        }
    }

    var instruction: String {
        switch self {
        case .serious: return "Mantieni un tono serio e professionale"
        case .light: return "Puoi essere leggero e usare un po' di ironia quando appropriato"
        }
    }
}

enum ToneLength: String, CaseIterable {
    case brief = "brief"
    case detailed = "detailed"

    var label: String {
        switch self {
        case .brief: return "Brevi"
        case .detailed: return "Dettagliate"
        }
    }

    var instruction: String {
        switch self {
        case .brief: return "Dai risposte concise e mirate"
        case .detailed: return "Fornisci risposte dettagliate e approfondite"
        }
    }
}

enum ToneStyle: String, CaseIterable {
    case intimate = "intimate"
    case professional = "professional"

    var label: String {
        switch self {
        case .intimate: return "Intimo"
        case .professional: return "Professionale"
        }
    }

    var instruction: String {
        switch self {
        case .intimate: return "Usa uno stile intimo e amichevole, come un amico fidato"
        case .professional: return "Mantieni uno stile professionale e formale"
        }
    }
}

// MARK: - Tone Preferences Manager

final class TonePreferences {
    static let shared = TonePreferences()
    private let defaults = UserDefaults.standard

    private init() {}

    // MARK: - Getters/Setters

    var empathy: ToneEmpathy {
        get {
            guard let raw = defaults.string(forKey: TonePreferenceKey.empathy) else { return .empathetic }
            return ToneEmpathy(rawValue: raw) ?? .empathetic
        }
        set { defaults.set(newValue.rawValue, forKey: TonePreferenceKey.empathy) }
    }

    var approach: ToneApproach {
        get {
            guard let raw = defaults.string(forKey: TonePreferenceKey.approach) else { return .gentle }
            return ToneApproach(rawValue: raw) ?? .gentle
        }
        set { defaults.set(newValue.rawValue, forKey: TonePreferenceKey.approach) }
    }

    var energy: ToneEnergy {
        get {
            guard let raw = defaults.string(forKey: TonePreferenceKey.energy) else { return .calm }
            return ToneEnergy(rawValue: raw) ?? .calm
        }
        set { defaults.set(newValue.rawValue, forKey: TonePreferenceKey.energy) }
    }

    var mood: ToneMood {
        get {
            guard let raw = defaults.string(forKey: TonePreferenceKey.mood) else { return .serious }
            return ToneMood(rawValue: raw) ?? .serious
        }
        set { defaults.set(newValue.rawValue, forKey: TonePreferenceKey.mood) }
    }

    var length: ToneLength {
        get {
            guard let raw = defaults.string(forKey: TonePreferenceKey.length) else { return .brief }
            return ToneLength(rawValue: raw) ?? .brief
        }
        set { defaults.set(newValue.rawValue, forKey: TonePreferenceKey.length) }
    }

    var style: ToneStyle {
        get {
            guard let raw = defaults.string(forKey: TonePreferenceKey.style) else { return .intimate }
            return ToneStyle(rawValue: raw) ?? .intimate
        }
        set { defaults.set(newValue.rawValue, forKey: TonePreferenceKey.style) }
    }

    // MARK: - Build Tone Instructions

    func buildToneInstructions() -> String {
        var instructions: [String] = []

        instructions.append(empathy.instruction)
        instructions.append(approach.instruction)
        instructions.append(energy.instruction)
        instructions.append(mood.instruction)
        instructions.append(length.instruction)
        instructions.append(style.instruction)

        return "<communication_style>\n" + instructions.joined(separator: "\n") + "\n</communication_style>"
    }

    // MARK: - Save All (for onboarding)

    func saveAll(
        empathy: ToneEmpathy,
        approach: ToneApproach,
        energy: ToneEnergy,
        mood: ToneMood,
        length: ToneLength,
        style: ToneStyle
    ) {
        self.empathy = empathy
        self.approach = approach
        self.energy = energy
        self.mood = mood
        self.length = length
        self.style = style
    }

    // MARK: - Reset to Defaults

    func resetToDefaults() {
        empathy = .empathetic
        approach = .gentle
        energy = .calm
        mood = .serious
        length = .brief
        style = .intimate
    }
}
