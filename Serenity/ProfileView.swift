//
//  ProfileView.swift
//  Serenity
//
//  Vista profilo con grafico umore e statistiche, ispirato ad Apple Health
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MoodEntry.date, order: .reverse) private var allEntries: [MoodEntry]

    @State private var selectedPeriod: TimePeriod = .week
    @State private var showingSettings = false
    @State private var showingEveningCheckIn = false
    @State private var showingMorningCheckIn = false
    @State private var showingToneSettings = false
    @State private var showingOnboardingSummary = false

    private var filteredEntries: [MoodEntry] {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -selectedPeriod.days, to: now) ?? now
        return allEntries.filter { $0.date >= startDate }
    }

    private var eveningEntries: [MoodEntry] {
        filteredEntries.filter { $0.checkInType == .evening }
    }

    private var morningEntries: [MoodEntry] {
        filteredEntries.filter { $0.checkInType == .morning }
    }

    private var averageMood: Double {
        guard !eveningEntries.isEmpty else { return 0 }
        let total = eveningEntries.reduce(0) { $0 + $1.moodScore }
        return Double(total) / Double(eveningEntries.count)
    }

    private var moodTrend: MoodTrend {
        guard eveningEntries.count >= 2 else { return .stable }
        let sorted = eveningEntries.sorted { $0.date < $1.date }
        let midpoint = sorted.count / 2
        let firstHalf = Array(sorted.prefix(midpoint))
        let secondHalf = Array(sorted.suffix(sorted.count - midpoint))

        guard !firstHalf.isEmpty, !secondHalf.isEmpty else { return .stable }

        let firstAvg = Double(firstHalf.reduce(0) { $0 + $1.moodScore }) / Double(firstHalf.count)
        let secondAvg = Double(secondHalf.reduce(0) { $0 + $1.moodScore }) / Double(secondHalf.count)

        let diff = secondAvg - firstAvg
        if diff > 0.3 { return .improving }
        if diff < -0.3 { return .declining }
        return .stable
    }

    var body: some View {
        ZStack {
            ChatStyle.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Period Picker
                    Picker("Periodo", selection: $selectedPeriod) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Stats Cards
                    HStack(spacing: 12) {
                        StatCard(
                            title: "Check-in",
                            value: "\(filteredEntries.count)",
                            icon: "checkmark.circle.fill",
                            color: ProfileColors.teal,
                            backgroundColor: ProfileColors.cardTeal
                        )

                        StatCard(
                            title: "Umore",
                            value: MoodAdjectivesLibrary.moodEmoji(for: averageMood),
                            icon: "face.smiling",
                            color: ProfileColors.amber,
                            backgroundColor: ProfileColors.cardAmber
                        )

                        StatCard(
                            title: "Trend",
                            value: moodTrend.label,
                            icon: moodTrend.icon,
                            color: moodTrend.color,
                            backgroundColor: moodTrend == .improving ? ProfileColors.cardMint :
                                           moodTrend == .declining ? ProfileColors.cardCoral :
                                           ProfileColors.cardAmber
                        )
                    }
                    .padding(.horizontal)

                    // Mood Chart
                    MoodChartView(entries: Array(filteredEntries), period: selectedPeriod)
                        .padding(.horizontal)

                    // Daily Check-in Buttons
                    CheckInButtonsSection(
                        onMorningTap: { showingMorningCheckIn = true },
                        onEveningTap: { showingEveningCheckIn = true }
                    )
                    .padding(.horizontal)

                    // Profile Settings Section
                    ProfileSettingsSection(
                        onToneTap: { showingToneSettings = true },
                        onOnboardingTap: { showingOnboardingSummary = true }
                    )
                    .padding(.horizontal)

                    // Recent Check-ins Section
                    if !filteredEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Check-in recenti")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.horizontal)

                            ForEach(filteredEntries.prefix(10)) { entry in
                                CheckInRow(entry: entry)
                            }
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "heart.text.square")
                                .font(.system(size: 50))
                                .foregroundStyle(ChatStyle.accentPurpleDark)

                            Text("Inizia a tracciare il tuo umore")
                                .font(.headline)
                                .foregroundStyle(ChatStyle.accentPurpleDark)

                            Text("I check-in giornalieri ti aiuteranno a capire meglio come ti senti nel tempo.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(ChatStyle.accentPurpleLight.opacity(0.95))
                        )
                        .padding(.horizontal)
                    }

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
        .sheet(isPresented: $showingEveningCheckIn) {
            EveningCheckInSheet()
        }
        .sheet(isPresented: $showingMorningCheckIn) {
            MorningCheckInSheet()
        }
        .sheet(isPresented: $showingToneSettings) {
            ToneSettingsSheet()
        }
        .sheet(isPresented: $showingOnboardingSummary) {
            OnboardingSummarySheet()
        }
    }
}

// MARK: - Mood Trend

enum MoodTrend {
    case improving
    case stable
    case declining

    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }

    var color: Color {
        switch self {
        case .improving: return .green
        case .stable: return .orange
        case .declining: return .red
        }
    }

    var label: String {
        switch self {
        case .improving: return "In crescita"
        case .stable: return "Stabile"
        case .declining: return "In calo"
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

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let backgroundColor: Color

    init(title: String, value: String, icon: String, color: Color, backgroundColor: Color = ChatStyle.accentPurpleLight.opacity(0.95)) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.headline)
                .foregroundStyle(Color(white: 0.2))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption)
                .foregroundStyle(Color(white: 0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(backgroundColor)
                .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Check-in Row

struct CheckInRow: View {
    let entry: MoodEntry

    private var userGender: String {
        guard let profile = OnboardingStorage.shared.loadProfile(),
              let genderAnswer = profile.answers.first(where: { $0.questionId == "q0_gender" }),
              let gender = genderAnswer.answers.first else {
            return "nb"
        }
        return gender
    }

    private var rowColor: Color {
        entry.checkInType == .morning ? ProfileColors.cardAmber : ProfileColors.cardBlue
    }

    private var accentColor: Color {
        entry.checkInType == .morning ? ProfileColors.amber : ProfileColors.softBlue
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon per tipo con cerchio colorato
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: entry.checkInType.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.checkInType.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(white: 0.2))

                    Spacer()

                    Text(entry.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(Color(white: 0.5))
                }

                if entry.checkInType == .evening {
                    // Mostra aggettivi selezionati
                    let moodLabels = entry.selectedMoodIds.compactMap { id in
                        MoodAdjectivesLibrary.adjectives.first { $0.id == id }
                    }.map { MoodAdjectivesLibrary.label(for: $0, gender: userGender) }

                    if !moodLabels.isEmpty {
                        Text(moodLabels.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(Color(white: 0.5))
                            .lineLimit(1)
                    }

                    // Score emoji
                    HStack(spacing: 4) {
                        Text("Umore:")
                            .font(.caption2)
                            .foregroundStyle(Color(white: 0.5))
                        Text(MoodAdjectivesLibrary.moodEmoji(for: Double(entry.moodScore)))
                    }
                } else if let motivation = entry.morningMotivation {
                    Text(motivation)
                        .font(.caption)
                        .foregroundStyle(Color(white: 0.5))
                        .lineLimit(2)
                }
            }

            Text(entry.date, style: .time)
                .font(.caption2)
                .foregroundStyle(Color(white: 0.6))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(rowColor)
                .shadow(color: accentColor.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

// MARK: - Check-in Buttons Section

struct CheckInButtonsSection: View {
    let onMorningTap: () -> Void
    let onEveningTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Check-in giornaliero")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                Button(action: onMorningTap) {
                    HStack(spacing: 10) {
                        Image(systemName: "sun.horizon.fill")
                            .font(.title2)
                            .foregroundStyle(ProfileColors.amber)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Mattutino")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color(white: 0.2))
                            Text("Motivazione & obiettivi")
                                .font(.caption2)
                                .foregroundStyle(Color(white: 0.5))
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(ProfileColors.cardAmber)
                            .shadow(color: ProfileColors.amber.opacity(0.2), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(.plain)

                Button(action: onEveningTap) {
                    HStack(spacing: 10) {
                        Image(systemName: "moon.stars.fill")
                            .font(.title2)
                            .foregroundStyle(ProfileColors.softBlue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Serale")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color(white: 0.2))
                            Text("Come ti senti?")
                                .font(.caption2)
                                .foregroundStyle(Color(white: 0.5))
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(ProfileColors.cardBlue)
                            .shadow(color: ProfileColors.softBlue.opacity(0.2), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
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
    .modelContainer(for: MoodEntry.self, inMemory: true)
}
