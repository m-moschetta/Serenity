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

    // Name collection step
    @State private var showingNameStep = true
    @State private var userName: String = ""

    // Emergency contact step
    @State private var showingEmergencyContactStep = false
    @State private var emergencyEmail: String = ""

    // Tone preferences step
    @State private var showingToneStep = false
    @State private var toneEmpathy: ToneEmpathy = .empathetic
    @State private var toneApproach: ToneApproach = .gentle
    @State private var toneEnergy: ToneEnergy = .calm
    @State private var toneMood: ToneMood = .serious
    @State private var toneLength: ToneLength = .brief
    @State private var toneStyle: ToneStyle = .intimate

    // Notifications step
    @State private var showingNotificationsStep = false
    @State private var notificationsEnabled = true
    @State private var morningTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @State private var eveningTime = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()
    @State private var weeklyEnabled = true

    private var currentQuestion: OnboardingQuestion { questions[currentIndex] }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let isCompactHeight = proxy.size.height < 750
                ScrollView {
                    VStack(spacing: 14) {
                        if showingNameStep {
                            nameStepContent
                                .padding(.bottom, 4)
                        } else if showingEmergencyContactStep {
                            emergencyContactStepContent
                                .padding(.bottom, 4)
                        } else if showingNotificationsStep {
                            notificationsStepHeader
                                .padding(.bottom, 4)
                            NotificationsSetupCard(
                                notificationsEnabled: $notificationsEnabled,
                                morningTime: $morningTime,
                                eveningTime: $eveningTime,
                                weeklyEnabled: $weeklyEnabled
                            )
                        } else if showingToneStep {
                            toneStepHeader
                                .padding(.bottom, 4)
                            ToneSelectionCard(
                                empathy: $toneEmpathy,
                                approach: $toneApproach,
                                energy: $toneEnergy,
                                mood: $toneMood,
                                length: $toneLength,
                                style: $toneStyle
                            )
                        } else {
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
                    if showingEmergencyContactStep {
                        Button("Indietro") {
                            showingEmergencyContactStep = false
                            showingNotificationsStep = true
                        }
                    } else if showingNotificationsStep {
                        Button("Indietro") {
                            showingNotificationsStep = false
                            showingToneStep = true
                        }
                    } else if showingToneStep {
                        Button("Indietro") { showingToneStep = false }
                    } else if currentIndex > 0 {
                        Button("Indietro") { goBack() }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if showingNameStep {
                nameActionBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .background(.thinMaterial)
            } else if showingEmergencyContactStep {
                emergencyContactActionBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .background(.thinMaterial)
            } else if showingNotificationsStep {
                notificationsActionBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .background(.thinMaterial)
            } else if showingToneStep {
                toneActionBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .background(.thinMaterial)
            } else {
                actionBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .background(.thinMaterial)
            }
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

    private var nameStepContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Come ti chiami?")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Questo ci aiuta a personalizzare l'esperienza e verrà usato per contattare il tuo supporto di emergenza se necessario.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("Il tuo nome (opzionale)", text: $userName)
                .textFieldStyle(.roundedBorder)
                .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private var nameActionBar: some View {
        Button(action: proceedFromName) {
            Text("Continua")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ChatStyle.accentPurpleDark)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func proceedFromName() {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        OnboardingStorage.saveUserName(trimmed.isEmpty ? nil : trimmed)
        withAnimation(.easeInOut) {
            showingNameStep = false
            currentIndex = 0
        }
    }

    private var emergencyContactStepContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Contatto di Emergenza (Facoltativo)")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("In caso di segnali di crisi, possiamo avvisare automaticamente una persona di tua fiducia.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField("Email contatto emergenza", text: $emergencyEmail)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.top, 8)

            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.orange)
                Text("Le conversazioni non verranno mai inoltrate e rimangono sempre private sul dispositivo. Questa opzione è facoltativa ma consigliata.")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private var emergencyContactActionBar: some View {
        VStack(spacing: 12) {
            Button {
                completeOnboardingWithEmail()
            } label: {
                Text("Salva e Completa")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ChatStyle.accentPurpleDark)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Button("Salta") {
                completeOnboardingWithEmail(skipEmail: true)
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            Text("Potrai modificare queste impostazioni in qualsiasi momento dal profilo.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }

    private func completeOnboardingWithEmail(skipEmail: Bool = false) {
        if !skipEmail {
            let trimmed = emergencyEmail.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && isValidEmail(trimmed) {
                OnboardingStorage.saveEmergencyContact(trimmed)
            }
        }
        finish()
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private var toneStepHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Come preferisci che ti parli Tranquiz?")
                .font(.headline)
            Text("Personalizza lo stile di comunicazione")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var toneActionBar: some View {
        VStack(spacing: 12) {
            Button(action: goToNotifications) {
                Text("Avanti")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ChatStyle.accentPurpleDark)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Text("Potrai modificare queste preferenze in qualsiasi momento dal profilo.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }

    private var notificationsStepHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vuoi attivare i promemoria giornalieri?")
                .font(.headline)
            Text("Ti aiuteranno a riflettere sul tuo stato d'animo")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var notificationsActionBar: some View {
        VStack(spacing: 12) {
            Button(action: goToEmergencyContact) {
                Text("Avanti")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ChatStyle.accentPurpleDark)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Text("Potrai modificare gli orari in qualsiasi momento dal profilo.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }

    private func goToEmergencyContact() {
        // Save notification settings
        saveNotificationSettings()
        withAnimation(.easeInOut) {
            showingNotificationsStep = false
            showingEmergencyContactStep = true
        }
    }

    private func goToNotifications() {
        // Save tone preferences
        TonePreferences.shared.saveAll(
            empathy: toneEmpathy,
            approach: toneApproach,
            energy: toneEnergy,
            mood: toneMood,
            length: toneLength,
            style: toneStyle
        )
        withAnimation(.easeInOut) {
            showingNotificationsStep = true
        }
    }

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
            // Show tone step instead of finishing directly
            withAnimation(.easeInOut) {
                showingToneStep = true
            }
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
            userName: OnboardingStorage.getUserName(),
            emergencyContactEmail: OnboardingStorage.getEmergencyContact(),
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

    private func saveNotificationSettings() {
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(weeklyEnabled, forKey: "weeklyNotificationEnabled")

        let morningComponents = Calendar.current.dateComponents([.hour, .minute], from: morningTime)
        let eveningComponents = Calendar.current.dateComponents([.hour, .minute], from: eveningTime)

        UserDefaults.standard.set(morningComponents.hour ?? 8, forKey: "morningCheckInHour")
        UserDefaults.standard.set(morningComponents.minute ?? 0, forKey: "morningCheckInMinute")
        UserDefaults.standard.set(eveningComponents.hour ?? 21, forKey: "eveningCheckInHour")
        UserDefaults.standard.set(eveningComponents.minute ?? 0, forKey: "eveningCheckInMinute")

        if notificationsEnabled {
            Task {
                let granted = await NotificationManager.shared.requestPermission()
                if granted {
                    NotificationManager.shared.rescheduleAll()
                }
            }
        }
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

// MARK: - Tone Selection Card

private struct ToneSelectionCard: View {
    @Binding var empathy: ToneEmpathy
    @Binding var approach: ToneApproach
    @Binding var energy: ToneEnergy
    @Binding var mood: ToneMood
    @Binding var length: ToneLength
    @Binding var style: ToneStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ToneOptionGroup(
                label: "Empatia",
                options: ToneEmpathy.allCases,
                selected: empathy,
                onSelect: { empathy = $0 }
            )

            ToneOptionGroup(
                label: "Approccio",
                options: ToneApproach.allCases,
                selected: approach,
                onSelect: { approach = $0 }
            )

            ToneOptionGroup(
                label: "Energia",
                options: ToneEnergy.allCases,
                selected: energy,
                onSelect: { energy = $0 }
            )

            ToneOptionGroup(
                label: "Tono",
                options: ToneMood.allCases,
                selected: mood,
                onSelect: { mood = $0 }
            )

            ToneOptionGroup(
                label: "Lunghezza risposte",
                options: ToneLength.allCases,
                selected: length,
                onSelect: { length = $0 }
            )

            ToneOptionGroup(
                label: "Stile",
                options: ToneStyle.allCases,
                selected: style,
                onSelect: { style = $0 }
            )
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

private struct ToneOptionGroup<T: RawRepresentable & CaseIterable & Hashable>: View where T.RawValue == String {
    let label: String
    let options: [T]
    let selected: T
    let onSelect: (T) -> Void

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
                ForEach(options, id: \.self) { option in
                    Button {
                        onSelect(option)
                    } label: {
                        Text(labelFor(option))
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
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

// MARK: - Notifications Setup Card

private struct NotificationsSetupCard: View {
    @Binding var notificationsEnabled: Bool
    @Binding var morningTime: Date
    @Binding var eveningTime: Date
    @Binding var weeklyEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Main toggle
            Toggle(isOn: $notificationsEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Attiva promemoria")
                        .font(.headline)
                    Text("Ricevi notifiche per i check-in giornalieri")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(ChatStyle.accentPurpleDark)

            if notificationsEnabled {
                Divider()

                // Morning time
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "sun.horizon.fill")
                            .foregroundStyle(.orange)
                        Text("Check-in mattutino")
                            .font(.subheadline.weight(.medium))
                    }
                    DatePicker("", selection: $morningTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }

                // Evening time
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "moon.stars.fill")
                            .foregroundStyle(.indigo)
                        Text("Check-in serale")
                            .font(.subheadline.weight(.medium))
                    }
                    DatePicker("", selection: $eveningTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }

                Divider()

                // Weekly toggle
                Toggle(isOn: $weeklyEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundStyle(ChatStyle.accentPurpleDark)
                            Text("Riepilogo settimanale")
                                .font(.subheadline.weight(.medium))
                        }
                        Text("Ricevi un'analisi AI del tuo umore ogni domenica")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(ChatStyle.accentPurpleDark)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .animation(.easeInOut, value: notificationsEnabled)
    }
}
