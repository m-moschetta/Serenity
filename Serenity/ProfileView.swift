//
//  ProfileView.swift
//  Serenity
//
//  Vista profilo con preferenze e onboarding
//

import SwiftUI

struct ProfileView: View {
    @State private var showingSettings = false
    @State private var showingToneSettings = false
    @State private var showingOnboardingSummary = false

    var body: some View {
        ZStack {
            ChatStyle.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Profilo")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Gestisci preferenze, tono di voce e le risposte dell'onboarding.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    // Profile Settings Section
                    ProfileSettingsSection(
                        onToneTap: { showingToneSettings = true },
                        onOnboardingTap: { showingOnboardingSummary = true }
                    )
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
        }
        .navigationTitle("Profilo")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(.white)
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingToneSettings) {
            ToneSettingsSheet()
        }
        .sheet(isPresented: $showingOnboardingSummary) {
            OnboardingSummarySheet()
        }
    }
}

// MARK: - Profile Colors

enum ProfileColors {
    static let teal = Color(red: 0.2, green: 0.7, blue: 0.7)
    static let coral = Color(red: 0.95, green: 0.5, blue: 0.45)
    static let amber = Color(red: 0.95, green: 0.75, blue: 0.3)
    static let mint = Color(red: 0.4, green: 0.85, blue: 0.7)
    static let softBlue = Color(red: 0.4, green: 0.6, blue: 0.9)

    static let cardTeal = Color(red: 0.85, green: 0.95, blue: 0.95)
    static let cardCoral = Color(red: 1.0, green: 0.92, blue: 0.9)
    static let cardAmber = Color(red: 1.0, green: 0.96, blue: 0.88)
    static let cardMint = Color(red: 0.9, green: 0.98, blue: 0.95)
    static let cardBlue = Color(red: 0.9, green: 0.94, blue: 1.0)
}

// MARK: - Profile Settings Section

struct ProfileSettingsSection: View {
    let onToneTap: () -> Void
    let onOnboardingTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personalizzazione")
                .font(.headline)
                .foregroundStyle(.white)

            VStack(spacing: 0) {
                Button(action: onToneTap) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(ProfileColors.coral.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "waveform")
                                .foregroundStyle(ProfileColors.coral)
                        }
                        Text("Tono di voce")
                            .foregroundStyle(Color(white: 0.2))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Color(white: 0.6))
                            .font(.caption)
                    }
                    .padding()
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.leading, 60)

                Button(action: onOnboardingTap) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(ProfileColors.teal.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "person.text.rectangle")
                                .foregroundStyle(ProfileColors.teal)
                        }
                        Text("Profilo e preferenze")
                            .foregroundStyle(Color(white: 0.2))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Color(white: 0.6))
                            .font(.caption)
                    }
                    .padding()
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(0.95))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            )
        }
    }
}

// MARK: - Tone Settings Sheet

struct ToneSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var toneEmpathy: ToneEmpathy = TonePreferences.shared.empathy
    @State private var toneApproach: ToneApproach = TonePreferences.shared.approach
    @State private var toneEnergy: ToneEnergy = TonePreferences.shared.energy
    @State private var toneMood: ToneMood = TonePreferences.shared.mood
    @State private var toneLength: ToneLength = TonePreferences.shared.length
    @State private var toneStyle: ToneStyle = TonePreferences.shared.style

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Personalizza come Tranquiz comunica con te")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 20) {
                        ToneOptionRow(label: "Empatia", selected: $toneEmpathy)
                        ToneOptionRow(label: "Approccio", selected: $toneApproach)
                        ToneOptionRow(label: "Energia", selected: $toneEnergy)
                        ToneOptionRow(label: "Tono", selected: $toneMood)
                        ToneOptionRow(label: "Lunghezza", selected: $toneLength)
                        ToneOptionRow(label: "Stile", selected: $toneStyle)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .navigationTitle("Tono di voce")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Salva") {
                        TonePreferences.shared.saveAll(
                            empathy: toneEmpathy,
                            approach: toneApproach,
                            energy: toneEnergy,
                            mood: toneMood,
                            length: toneLength,
                            style: toneStyle
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

private struct ToneOptionRow<T: RawRepresentable & CaseIterable & Hashable>: View where T.RawValue == String {
    let label: String
    @Binding var selected: T

    private func labelFor(_ option: T) -> String {
        switch option {
        case let e as ToneEmpathy: return e.label
        case let a as ToneApproach: return a.label
        case let e as ToneEnergy: return e.label
        case let m as ToneMood: return m.label
        case let l as ToneLength: return l.label
        case let s as ToneStyle: return s.label
        default: return option.rawValue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(Array(T.allCases), id: \.self) { option in
                    Button {
                        selected = option
                    } label: {
                        Text(labelFor(option))
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selected == option ? ChatStyle.accentPurpleDark : Color(.systemBackground))
                            .foregroundColor(selected == option ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Onboarding Summary Sheet

struct OnboardingSummarySheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("onboardingCompleted") private var onboardingCompleted: Bool = false

    private var profile: OnboardingProfile? {
        OnboardingStorage.shared.loadProfile()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let profile = profile {
                        // Summary Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Il tuo profilo")
                                .font(.headline)

                            Text(profile.summaryText())
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        // Answers Section
                        if !profile.answers.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Le tue risposte")
                                    .font(.headline)

                                ForEach(profile.answers, id: \.questionId) { answer in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(answer.question)
                                            .font(.subheadline.weight(.medium))
                                        Text(answer.answers.joined(separator: ", "))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                        }

                        // Redo Onboarding Button
                        Button {
                            onboardingCompleted = false
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Modifica le risposte")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ChatStyle.accentPurpleDark)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .padding(.top)
                    } else {
                        ContentUnavailableView(
                            "Nessun profilo trovato",
                            systemImage: "person.crop.circle.badge.questionmark",
                            description: Text("Completa l'onboarding per vedere il tuo profilo")
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Profilo e preferenze")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Chiudi") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
