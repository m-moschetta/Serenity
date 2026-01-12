//
//  MorningCheckInSheet.swift
//  Serenity
//
//  Sheet modale per il check-in mattutino con domande aperte
//

import SwiftUI
import SwiftData

struct MorningCheckInSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var motivation: String = ""
    @State private var fear: String = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case motivation
        case fear
    }

    private var canSave: Bool {
        !motivation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.orange)

                        Text("Buongiorno!")
                            .font(.title.bold())

                        Text("Prenditi un momento per riflettere sulla giornata che ti aspetta")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Domanda 1 - Motivazione
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Cosa ti motiva oggi?", systemImage: "bolt.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)

                        Text("Qual e la cosa che ti motiva di piu ad affrontare la giornata di oggi?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextEditor(text: $motivation)
                            .frame(minHeight: 100)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(.tertiarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color(.separator), lineWidth: 0.5)
                            )
                            .focused($focusedField, equals: .motivation)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )

                    // Domanda 2 - Paura
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Cosa ti preoccupa?", systemImage: "cloud.fill")
                            .font(.headline)
                            .foregroundStyle(.gray)

                        Text("C'e qualcosa che ti spaventa o ti preoccupa per oggi?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextEditor(text: $fear)
                            .frame(minHeight: 100)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(.tertiarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color(.separator), lineWidth: 0.5)
                            )
                            .focused($focusedField, equals: .fear)

                        Text("Questo campo e opzionale")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )

                    Spacer(minLength: 40)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Check-in mattutino")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") { saveEntry() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Fine") { focusedField = nil }
                    }
                }
            }
        }
    }

    private func saveEntry() {
        let entry = MoodEntry(
            checkInType: .morning,
            moodScore: 0,  // Non applicabile per morning
            morningMotivation: motivation.trimmingCharacters(in: .whitespacesAndNewlines),
            morningFear: fear.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : fear.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        context.insert(entry)
        try? context.save()

        dismiss()
    }
}

#Preview {
    MorningCheckInSheet()
        .modelContainer(for: MoodEntry.self, inMemory: true)
}
