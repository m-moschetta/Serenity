//
//  EveningCheckInSheet.swift
//  Serenity
//
//  Sheet modale per il check-in serale con griglia di aggettivi
//

import SwiftUI
import SwiftData

struct EveningCheckInSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var selectedMoodIds: Set<String> = []

    // Ottieni genere dall'onboarding
    private var userGender: String {
        guard let profile = OnboardingStorage.shared.loadProfile(),
              let genderAnswer = profile.answers.first(where: { $0.questionId == "q0_gender" }),
              let gender = genderAnswer.answers.first else {
            return "nb"  // default non binario
        }
        return gender
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.indigo)

                        Text("Come e andata la giornata?")
                            .font(.title2.bold())

                        Text("Seleziona gli aggettivi che descrivono come ti senti")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Aggettivi positivi
                    moodSection(category: .positive)

                    // Aggettivi neutrali
                    moodSection(category: .neutral)

                    // Aggettivi negativi
                    moodSection(category: .negative)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Check-in serale")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") { saveEntry() }
                        .disabled(selectedMoodIds.isEmpty)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    @ViewBuilder
    private func moodSection(category: MoodCategory) -> some View {
        let filteredAdjectives = MoodAdjectivesLibrary.adjectives(for: category)

        VStack(alignment: .leading, spacing: 12) {
            Text(category.displayName)
                .font(.headline)
                .foregroundStyle(category.color)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(filteredAdjectives) { adjective in
                    MoodChip(
                        label: MoodAdjectivesLibrary.label(for: adjective, gender: userGender),
                        isSelected: selectedMoodIds.contains(adjective.id),
                        color: category.color
                    ) {
                        toggleSelection(adjective.id)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func toggleSelection(_ id: String) {
        if selectedMoodIds.contains(id) {
            selectedMoodIds.remove(id)
        } else {
            selectedMoodIds.insert(id)
        }
    }

    private func saveEntry() {
        let moodIds = Array(selectedMoodIds)
        let score = MoodEntry.calculateScore(from: moodIds)

        let entry = MoodEntry(
            checkInType: .evening,
            moodScore: score,
            selectedMoodIds: moodIds
        )

        context.insert(entry)
        try? context.save()

        dismiss()
    }
}

// MARK: - Mood Chip

struct MoodChip: View {
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(isSelected ? color.opacity(0.2) : Color(.tertiarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? color : .primary)
    }
}

#Preview {
    EveningCheckInSheet()
        .modelContainer(for: MoodEntry.self, inMemory: true)
}
