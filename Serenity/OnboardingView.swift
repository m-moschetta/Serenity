//
//  OnboardingView.swift
//  Serenity
//
//  Flusso di onboarding strutturato per personalizzare il contesto dell'assistente
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("onboardingCompleted") private var onboardingCompleted: Bool = false
    @AppStorage("onboardingSummary") private var onboardingSummary: String = ""

    @State private var questions: [OnboardingQuestion] = OnboardingFlowLibrary.commonQuestions + [OnboardingFlowLibrary.rootQuestion]
    @State private var currentIndex: Int = 0
    @State private var selectionAnswers: [String: [String]] = [:]
    @State private var textAnswers: [String: String] = [:]
    @State private var selectedReasons: [OnboardingReason] = []
    @State private var didAppendFlows = false
    @State private var safetyAsked = false
    @State private var safetyFlagged = false
    @State private var showSafetySheet = false
    @State private var showCrisisOverlay = false

    private var currentQuestion: OnboardingQuestion { questions[currentIndex] }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let isCompactHeight = proxy.size.height < 750
                ScrollView {
                    VStack(spacing: 14) {
                        progressHeader
                            .padding(.bottom, 4)
                        QuestionCard(
                            question: currentQuestion,
                            selections: selectionAnswers[currentQuestion.id] ?? [],
                            text: textAnswers[currentQuestion.id] ?? "",
                            onToggle: toggleSelection,
                            onTextChange: { textAnswers[currentQuestion.id] = $0 }
                        )
                        if let reason = currentQuestion.reason {
                            SkipFlowButton(title: "Salta questo motivo", action: { skip(reason: reason) })
                        }
                        Spacer(minLength: isCompactHeight ? 40 : 80)
                    }
                    .padding(.horizontal, isCompactHeight ? 12 : 18)
                    .padding(.top, 16)
                    .padding(.bottom, 140)
                }
            }
            .navigationTitle("Onboarding")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if currentIndex > 0 {
                        Button("Indietro") { goBack() }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            actionBar
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .background(.thinMaterial)
        }
        .sheet(isPresented: $showSafetySheet) {
            SafetyCheckSheet { choice in
                selectionAnswers[OnboardingFlowLibrary.safetyQuestion.id] = [choice.id]
                safetyAsked = true
                if choice.id == "often" || choice.id == "sometimes" {
                    safetyFlagged = true
                    showCrisisOverlay = true
                }
            }
            .presentationDetents([.fraction(0.5), .large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showCrisisOverlay) {
            CrisisOverlayView(isPresented: $showCrisisOverlay)
        }
    }

    // MARK: - UI

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Costruiamo il tuo spazio su misura")
                .font(.headline)
            ProgressView(value: Double(currentIndex + 1), total: Double(questions.count))
                .tint(ChatStyle.accentPurpleDark)
            if let reason = currentQuestion.reason {
                Text(reason.label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionBar: some View {
        VStack(spacing: 12) {
            Button(action: next) {
                Text(isLastQuestion ? "Concludi" : "Avanti")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isCurrentValid ? ChatStyle.accentPurpleDark : Color.gray.opacity(0.4))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(!isCurrentValid)

            Text("Queste domande orientano il supporto, non sostituiscono un parere medico. In caso di emergenza usa i numeri dedicati.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }

    // MARK: - Actions

    private func toggleSelection(_ option: OnboardingOption) {
        switch currentQuestion.kind {
        case .multiChoice(let max):
            var values = selectionAnswers[currentQuestion.id] ?? []
            if values.contains(option.id) {
                values.removeAll { $0 == option.id }
            } else {
                if values.count >= max { values.removeFirst() }
                values.append(option.id)
            }
            selectionAnswers[currentQuestion.id] = values
        default:
            if selectionAnswers[currentQuestion.id]?.first == option.id {
                selectionAnswers[currentQuestion.id] = []
            } else {
                selectionAnswers[currentQuestion.id] = [option.id]
            }
        }
    }

    private func goBack() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }

    private func skip(reason: OnboardingReason) {
        var nextIndex = currentIndex
        while nextIndex < questions.count && questions[nextIndex].reason == reason {
            nextIndex += 1
        }
        currentIndex = min(nextIndex, questions.count - 1)
    }

    private func next() {
        guard isCurrentValid else { return }

        if currentQuestion.id == OnboardingFlowLibrary.rootQuestion.id {
            let ids = selectionAnswers[currentQuestion.id] ?? []
            selectedReasons = ids.compactMap { OnboardingReason(rawValue: $0) }
            appendReasonFlowsIfNeeded()
        }

        evaluateSafety(for: currentQuestion)

        if isLastQuestion {
            finish()
            return
        }

        withAnimation(.easeInOut) {
            currentIndex += 1
        }
    }

    private func evaluateSafety(for question: OnboardingQuestion) {
        guard !safetyAsked else { return }
        let selected = selectionAnswers[question.id] ?? []
        let risky = question.options.contains { opt in
            selected.contains(opt.id) && opt.triggersSafety
        }
        if risky {
            showSafetySheet = true
        }
    }

    private func appendReasonFlowsIfNeeded() {
        guard !didAppendFlows else { return }
        didAppendFlows = true
        var queue: [OnboardingQuestion] = []
        for reason in selectedReasons {
            queue.append(contentsOf: OnboardingFlowLibrary.flow(for: reason))
        }
        questions.append(contentsOf: queue)
    }

    private func finish() {
        let allAnswers = buildAnswers()
        let profile = OnboardingProfile(
            createdAt: .now,
            answers: allAnswers,
            primaryReason: selectedReasons.first,
            otherReasons: Array(selectedReasons.dropFirst()),
            safetyFlag: safetyFlagged || safetyAnswerIsRisky()
        )
        onboardingSummary = profile.summaryText()
        OnboardingStorage.shared.save(profile: profile)
        onboardingCompleted = true
        sendWelcomeMessage(profile: profile)
        dismiss()
    }

    private func buildAnswers() -> [OnboardingAnswer] {
        var result: [OnboardingAnswer] = []
        for q in questions {
            if let list = selectionAnswers[q.id] {
                let risky = q.options.contains { opt in list.contains(opt.id) && opt.triggersSafety }
                let pretty = list.compactMap { id in
                    q.options.first(where: { $0.id == id })?.title ?? textAnswers[q.id]
                }
                result.append(OnboardingAnswer(questionId: q.id, question: q.title, answers: pretty, reason: q.reason, isSafetyRelated: risky))
            } else if let text = textAnswers[q.id]?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
                result.append(OnboardingAnswer(questionId: q.id, question: q.title, answers: [text], reason: q.reason, isSafetyRelated: false))
            }
        }
        if let safety = selectionAnswers[OnboardingFlowLibrary.safetyQuestion.id] {
            let title = OnboardingFlowLibrary.safetyQuestion.title
            result.append(OnboardingAnswer(questionId: OnboardingFlowLibrary.safetyQuestion.id, question: title, answers: safety, reason: nil, isSafetyRelated: true))
        }
        return result
    }

    private func safetyAnswerIsRisky() -> Bool {
        guard let val = selectionAnswers[OnboardingFlowLibrary.safetyQuestion.id]?.first else { return false }
        return val == "often" || val == "sometimes"
    }

    // MARK: - Helpers

    private var isCurrentValid: Bool {
        switch currentQuestion.kind {
        case .singleChoice:
            return !(selectionAnswers[currentQuestion.id]?.isEmpty ?? true)
        case .multiChoice:
            return !(selectionAnswers[currentQuestion.id]?.isEmpty ?? true)
        case .scale(let options):
            return selectionAnswers[currentQuestion.id]?.contains(where: options.contains) ?? false
        case .freeText:
            if let text = textAnswers[currentQuestion.id]?.trimmingCharacters(in: .whitespacesAndNewlines) {
                return !text.isEmpty
            }
            return false
        }
    }

    private var isLastQuestion: Bool {
        currentIndex == questions.count - 1
    }

	    private func sendWelcomeMessage(profile: OnboardingProfile) {
	        // Costruisci un messaggio di benvenuto coerente con il motivo principale e con eventuali segnali di sicurezza.
	        var intro = "Grazie per aver condiviso qualcosa di te. Ho preso nota di quello che hai raccontato per personalizzare il supporto."
        if let main = profile.primaryReason {
            intro += " Ho capito che il motivo principale è: \(main.label.lowercased())."
        }
        if profile.safetyFlag {
            intro += " Se in qualsiasi momento senti che le cose diventano troppo pesanti, scrivilo pure e ti indicherò subito numeri e risorse di emergenza."
        }
        intro += " Ti va di raccontarmi cosa ti pesa di più in questo momento o da dove vorresti iniziare?"
	
	        // Salva il messaggio come system per mostrarlo all'utente all'apertura del chat.
	        Task { @MainActor in
	            let conversation = (try? context.fetch(FetchDescriptor<Conversation>()).first) ?? {
	                let newConversation = Conversation()
	                context.insert(newConversation)
	                return newConversation
	            }()
	            let msg = ChatMessage(role: .assistant, content: intro)
	            msg.conversation = conversation
	            conversation.messages.append(msg)
	            conversation.updatedAt = .now
	            try? context.save()
	        }
	    }
}

// MARK: - Subviews

private struct QuestionCard: View {
    let question: OnboardingQuestion
    let selections: [String]
    let text: String
    let onToggle: (OnboardingOption) -> Void
    let onTextChange: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(question.title)
                .font(.title3.weight(.semibold))
            if let subtitle = question.subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            switch question.kind {
            case .freeText(let placeholder):
                TextField(placeholder ?? "Scrivi qui", text: Binding(
                    get: { text },
                    set: { onTextChange($0) }
                ))
                .textFieldStyle(.roundedBorder)
            default:
                VStack(spacing: 8) {
                    ForEach(question.options) { opt in
                        OptionRow(
                            option: opt,
                            isSelected: selections.contains(opt.id),
                            kind: question.kind,
                            selectionCount: selections.count,
                            maxSelection: question.maxSelection,
                            onToggle: { onToggle(opt) }
                        )
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

private struct OptionRow: View {
    let option: OnboardingOption
    let isSelected: Bool
    let kind: OnboardingQuestionKind
    let selectionCount: Int
    let maxSelection: Int
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? ChatStyle.accentPurpleDark : .secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    if let detail = option.detail {
                        Text(detail)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if option.triggersSafety {
                        Text("Nodo di sicurezza: se scegli questa opzione potremmo mostrarti i numeri di aiuto.")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }
                Spacer()
                if case .multiChoice = kind {
                    Text("\(selectionCount)/\(maxSelection)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(isSelected ? ChatStyle.accentPurpleLight.opacity(0.2) : Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct SkipFlowButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

private struct SafetyCheckSheet: View {
    let onSelect: (OnboardingOption) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(OnboardingFlowLibrary.safetyQuestion.title)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle = OnboardingFlowLibrary.safetyQuestion.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                VStack(spacing: 10) {
                    ForEach(OnboardingFlowLibrary.safetyQuestion.options) { opt in
                        Button {
                            onSelect(opt)
                            dismiss()
                        } label: {
                            HStack(alignment: .center, spacing: 10) {
                                Text(opt.title)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
    }
}
