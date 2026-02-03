//
//  OverviewView.swift
//  Serenity
//
//  Sezione overview con statistiche e report condivisibile
//

import SwiftUI
import SwiftData

struct OverviewView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("aiProvider") private var aiProvider: String = "openai"
    @AppStorage("openaiModel") private var openaiModel: String = "gpt-5.2"
    @AppStorage("mistralModel") private var mistralModel: String = "mistral-large-latest"
    @AppStorage("groqModel") private var groqModel: String = "llama3-8b-8192"
    @AppStorage("overviewReportModelOpenAI") private var overviewReportModelOpenAI: String = ""
    @AppStorage("overviewReportModelMistral") private var overviewReportModelMistral: String = ""
    @AppStorage("overviewReportModelGroq") private var overviewReportModelGroq: String = ""
    @AppStorage("overviewReportTemperature") private var overviewReportTemperature: Double = 0.2
    @AppStorage("overviewReportMaxTokens") private var overviewReportMaxTokens: Int = 900
    @AppStorage("overviewReportPrompt") private var overviewReportPrompt: String = """
Sei un assistente clinico che produce un report sintetico per lo psicologo, basato solo su dati aggregati e de-identificati.
Non includere trascrizioni complete, nomi, luoghi specifici o dettagli identificativi.

Obiettivo: fornire due cose in modo chiaro e utile:
1) Contesto tecnico d'uso (come, quando, quanto usa il chatbot)
2) Indici sintetici di contenuto ed emozioni che emergono

Requisiti di output:
- Report in italiano, professionale e conciso.
- Sezioni obbligatorie: Uso, Emozioni, Temi, Interventi, Sicurezza.
- Evidenzia trend, cambiamenti rispetto alla baseline e segnali di rischio.
- Evita ipotesi cliniche o diagnosi.
- Se i dati sono insufficienti, dichiaralo esplicitamente.
"""
    private let defaultOverviewPrompt = """
Sei un assistente clinico che produce un report sintetico per lo psicologo, basato solo su dati aggregati e de-identificati.
Non includere trascrizioni complete, nomi, luoghi specifici o dettagli identificativi.

Obiettivo: fornire due cose in modo chiaro e utile:
1) Contesto tecnico d'uso (come, quando, quanto usa il chatbot)
2) Indici sintetici di contenuto ed emozioni che emergono

Requisiti di output:
- Report in italiano, professionale e conciso.
- Sezioni obbligatorie: Uso, Emozioni, Temi, Interventi, Sicurezza.
- Evidenzia trend, cambiamenti rispetto alla baseline e segnali di rischio.
- Evita ipotesi cliniche o diagnosi.
- Se i dati sono insufficienti, dichiaralo esplicitamente.
"""

    @Query(sort: \MoodEntry.date, order: .reverse) private var allEntries: [MoodEntry]
    @Query(sort: \ChatMessage.createdAt, order: .reverse) private var messages: [ChatMessage]
    @Query(sort: \Conversation.updatedAt, order: .reverse) private var conversations: [Conversation]

    @State private var selectedPeriod: TimePeriod = .week
    @State private var showingEveningCheckIn = false
    @State private var showingMorningCheckIn = false
    @State private var showingShareSheet = false
    @State private var reportURL: URL?
    @State private var isGeneratingReport = false
    @State private var showReportError = false
    @State private var reportErrorMessage = ""

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

    private var hasData: Bool {
        !messages.isEmpty || !allEntries.isEmpty
    }

    private var userMessages: [ChatMessage] {
        messages.filter { $0.role == .user }
    }

    private var assistantMessages: [ChatMessage] {
        messages.filter { $0.role == .assistant }
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

                    // Report Section
                    OverviewReportSection(
                        isDisabled: !hasData,
                        isGenerating: isGeneratingReport,
                        onExportTextTap: generateReportText,
                        onExportJsonTap: generateReportJson
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
        .navigationTitle("Overview")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingEveningCheckIn) {
            EveningCheckInSheet()
        }
        .sheet(isPresented: $showingMorningCheckIn) {
            MorningCheckInSheet()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let reportURL {
                ShareSheet(items: [reportURL])
            }
        }
        .alert("Report overview", isPresented: $showReportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(reportErrorMessage)
        }
    }

    private func generateReportText() {
        Task {
            await generateReportTextAI()
        }
    }

    private func generateReportJson() {
        Task {
            await generateReportJsonAI()
        }
    }

    private func generateReportTextAI() async {
        guard !isGeneratingReport else { return }
        isGeneratingReport = true
        defer { isGeneratingReport = false }

        do {
            let model = currentReportModel()
            let narrative = try await generateReportNarrative(outputFormat: "text")
            let header = reportMetaHeader(provider: aiProvider, model: model)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let filename = "Tranquiz-Overview-Report-\(formatter.string(from: Date())).txt"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            let decorated = header + "\n\n" + narrative
            try decorated.write(to: url, atomically: true, encoding: .utf8)
            reportURL = url
            showingShareSheet = true
        } catch {
            reportErrorMessage = buildReportErrorMessage(prefix: "Non sono riuscito a generare il report con AI.")
            showReportError = true
        }
    }

    private func generateReportJsonAI() async {
        guard !isGeneratingReport else { return }
        isGeneratingReport = true
        defer { isGeneratingReport = false }

        do {
            let model = currentReportModel()
            let narrative = try await generateReportNarrative(outputFormat: "json")
            let report = buildReportModel(
                aiNarrative: narrative,
                aiProvider: aiProvider,
                aiModel: model,
                aiTemperature: overviewReportTemperature,
                aiMaxTokens: overviewReportMaxTokens
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(report)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let filename = "Tranquiz-Overview-Report-\(formatter.string(from: Date())).json"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try data.write(to: url, options: .atomic)
            reportURL = url
            showingShareSheet = true
        } catch {
            reportErrorMessage = buildReportErrorMessage(prefix: "Non sono riuscito a generare il report JSON con AI.")
            showReportError = true
        }
    }

    private func generateReportNarrative(outputFormat: String) async throws -> String {
        let report = buildReportModel(aiNarrative: nil)
        let payload = buildReportPayload(for: report)
        let model = currentReportModel()
        let provider = AIService.shared.provider()
        let prompt = overviewReportPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? defaultOverviewPrompt
            : overviewReportPrompt

        let response = try await provider.chat(
            messages: [
                ProviderMessage(role: "system", content: prompt),
                ProviderMessage(role: "user", content: payload)
            ],
            model: model,
            temperature: overviewReportTemperature,
            maxTokens: overviewReportMaxTokens
        )
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            throw ReportGenerationError.emptyResponse
        }
        await saveReportLog(
            model: model,
            payload: payload,
            response: trimmed,
            outputFormat: outputFormat
        )
        return trimmed
    }

    private func buildReport() -> String {
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "it_IT")
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        let usage = usageSummary()
        let emotions = emotionSummary()
        let themes = themeSummary()
        let interventions = interventionSummary()
        let safety = safetySummary()

        return """
        Tranquiz - Report Overview
        Generato il \(dateFormatter.string(from: now))

        Nota di consenso e privacy
        - Condivisione solo con consenso esplicito dell'utente.
        - Dati de-identificati e aggregati, senza trascrizione completa delle chat.

        1) Metadati sull'uso del chatbot
        \(usage)

        2) Indicatori di stato emotivo
        \(emotions)

        3) Temi ricorrenti e contenuti tipici
        \(themes)

        4) Interventi del chatbot e risposta
        \(interventions)

        5) Sicurezza
        \(safety)
        """
    }

    private func buildReportModel(
        aiNarrative: String? = nil,
        aiProvider: String? = nil,
        aiModel: String? = nil,
        aiTemperature: Double? = nil,
        aiMaxTokens: Int? = nil
    ) -> OverviewReport {
        let now = Date()
        let avgDaysPerWeek = averageDaysPerWeek()
        let avgSessionsPerDay = averageSessionsPerDay()
        let avgMessagesPerSession = averageMessagesPerConversation()
        let peakRanges = topBuckets(from: hourBucketCounts(messages: userMessages), limit: 2)
        let weekendShare = weekendShareRatio(messages: userMessages)
        let usageChange = usageChangeTrend()

        let avgMoodScore = averageMood
        let moodEmoji = MoodAdjectivesLibrary.moodEmoji(for: avgMoodScore)
        let moodTrendText = trendTextForMood()
        let moodRatings = moodRatingsTrend()
        let moodTags = topMoodTags(limit: 5)
        let autoEmotions = topKeywordCategories(from: userMessages, map: emotionKeywords, limit: 4)

        let themes = topKeywordCategories(from: userMessages, map: themeKeywords, limit: 5)
        let triggers = topKeywordCategories(from: userMessages, map: triggerKeywords, limit: 4)
        let distortions = topKeywordCategories(from: userMessages, map: cognitiveKeywords, limit: 3)
        let goals = topGoals(limit: 3)
        let examples = themeExamples(from: themes)

        let interventions = topKeywordCategories(from: assistantMessages, map: interventionKeywords, limit: 4)
        let adherence = adherenceSummary()
        let usefulness = usefulnessSummary()
        let safetyMessages = safetyMessageCount()

        let riskEvents = riskEventsSummary()

        return OverviewReport(
            generatedAt: now,
            consentNote: [
                "Condivisione solo con consenso esplicito dell'utente.",
                "Dati de-identificati e aggregati, senza trascrizione completa delle chat."
            ],
            aiNarrative: aiNarrative,
            aiProvider: aiProvider,
            aiModel: aiModel,
            aiTemperature: aiTemperature,
            aiMaxTokens: aiMaxTokens,
            usage: OverviewReport.Usage(
                daysUsedLast4Weeks: averageDaysUsedLast4Weeks(),
                avgDaysPerWeek: avgDaysPerWeek,
                avgSessionsPerDay: avgSessionsPerDay,
                avgMessagesPerSession: avgMessagesPerSession,
                peakTimeRanges: peakRanges,
                weekendShare: weekendShare,
                usageChange: usageChange
            ),
            emotions: OverviewReport.Emotions(
                avgMoodScore: avgMoodScore,
                moodEmoji: moodEmoji,
                moodTrend: moodTrendText,
                moodRatingsTrend: moodRatings,
                topMoodTags: moodTags,
                autoEmotionSignals: autoEmotions
            ),
            themes: OverviewReport.Themes(
                topThemes: themes,
                triggers: triggers,
                cognitivePatterns: distortions,
                statedGoals: goals,
                exampleSummaries: examples
            ),
            interventions: OverviewReport.Interventions(
                suggestedTypes: interventions,
                adherence: adherence,
                usefulness: usefulness,
                safetyMessagesCount: safetyMessages
            ),
            safety: OverviewReport.Safety(
                riskSignals: riskEvents
            )
        )
    }

    private func usageSummary() -> String {
        let calendar = Calendar.current
        let last28Days = Date().addingTimeInterval(-28 * 24 * 60 * 60)
        let recentMessages = userMessages.filter { $0.createdAt >= last28Days }

        let sessionsByDay = groupSessionsByDay(messages: recentMessages)
        let daysUsed = sessionsByDay.keys.count
        let avgDaysPerWeek = daysUsed > 0 ? Double(daysUsed) / 4.0 : 0
        let avgDaysPerWeekText = String(format: "%.1f", avgDaysPerWeek)

        let totalSessions = sessionsByDay.values.reduce(0) { $0 + $1.count }
        let avgSessionsPerDay = daysUsed > 0 ? Double(totalSessions) / Double(daysUsed) : 0
        let avgSessionsPerDayText = String(format: "%.1f", avgSessionsPerDay)

        let hourBuckets = hourBucketCounts(messages: recentMessages)
        let peakRanges = topBuckets(from: hourBuckets, limit: 2)

        let avgMessagesPerSession = averageMessagesPerConversation()
        let weekendShare = weekendShareRatio(messages: recentMessages)
        let usageChange = usageChangeTrend()

        return """
        - Giorni attivi nelle ultime 4 settimane: \(daysUsed) (\(avgDaysPerWeekText)/settimana).
        - Sessioni medie al giorno: \(avgSessionsPerDayText).
        - Messaggi medi per sessione: \(avgMessagesPerSession).
        - Fasce orarie di picco: \(peakRanges.isEmpty ? "dati insufficienti" : peakRanges.joined(separator: ", ")).
        - Quota uso nel weekend: \(weekendShare).
        - Variazioni recenti: \(usageChange).
        """
    }

    private func emotionSummary() -> String {
        let moodTrendText = trendTextForMood()
        let avgMoodScore = averageMood
        let moodEmoji = MoodAdjectivesLibrary.moodEmoji(for: avgMoodScore)
        let avgMoodScoreText = String(format: "%.2f", avgMoodScore)
        let moodTags = topMoodTags(limit: 5)
        let autoEmotions = topKeywordCategories(from: userMessages, map: emotionKeywords, limit: 4)
        let moodRatings = moodRatingsTrend()

        return """
        - Umore medio (check-in serali): \(moodEmoji) (\(avgMoodScoreText)).
        - Trend umore: \(moodTrendText).
        - Andamento punteggi: \(moodRatings).
        - Tag emotivi piu' frequenti: \(moodTags.isEmpty ? "nessuno" : moodTags.joined(separator: ", ")).
        - Emozioni stimate dai messaggi: \(autoEmotions.isEmpty ? "nessuna categoria prevalente" : autoEmotions.joined(separator: ", ")).
        """
    }

    private func themeSummary() -> String {
        let themes = topKeywordCategories(from: userMessages, map: themeKeywords, limit: 5)
        let triggers = topKeywordCategories(from: userMessages, map: triggerKeywords, limit: 4)
        let distortions = topKeywordCategories(from: userMessages, map: cognitiveKeywords, limit: 3)
        let goals = topGoals(limit: 3)
        let examples = themeExamples(from: themes)

        return """
        - Temi prevalenti: \(themes.isEmpty ? "nessun tema ricorrente" : themes.joined(separator: ", ")).
        - Situazioni-trigger citate: \(triggers.isEmpty ? "nessuna ricorrenza chiara" : triggers.joined(separator: ", ")).
        - Schemi cognitivi rilevati: \(distortions.isEmpty ? "non rilevati" : distortions.joined(separator: ", ")).
        - Obiettivi dichiarati: \(goals.isEmpty ? "non dichiarati" : goals.joined(separator: " · ")).
        - Esempi sintetici (anonimizzati): \(examples.isEmpty ? "nessuno" : examples.joined(separator: " | ")).
        """
    }

    private func interventionSummary() -> String {
        let interventions = topKeywordCategories(from: assistantMessages, map: interventionKeywords, limit: 4)
        let adherence = adherenceSummary()
        let usefulness = usefulnessSummary()
        let safetyMessages = safetyMessageCount()

        return """
        - Tipi di intervento proposti: \(interventions.isEmpty ? "non rilevati" : interventions.joined(separator: ", ")).
        - Aderenza percepita: \(adherence).
        - Utilita' percepita: \(usefulness).
        - Messaggi standard di sicurezza: \(safetyMessages).
        """
    }

    private func safetySummary() -> String {
        let riskEvents = riskEventsSummary()
        return """
        - Segnali di rischio rilevati: \(riskEvents.isEmpty ? "nessun segnale" : riskEvents.joined(separator: "; ")).
        """
    }

    private func groupSessionsByDay(messages: [ChatMessage]) -> [Date: Set<UUID>] {
        let calendar = Calendar.current
        var grouped: [Date: Set<UUID>] = [:]

        for message in messages {
            let day = calendar.startOfDay(for: message.createdAt)
            let conversationId = message.conversation?.id ?? UUID()
            grouped[day, default: []].insert(conversationId)
        }
        return grouped
    }

    private func hourBucketCounts(messages: [ChatMessage]) -> [String: Int] {
        var buckets: [String: Int] = [:]
        let calendar = Calendar.current
        for message in messages {
            let hour = calendar.component(.hour, from: message.createdAt)
            let bucket: String
            switch hour {
            case 0..<6: bucket = "Notte (00-06)"
            case 6..<12: bucket = "Mattina (06-12)"
            case 12..<18: bucket = "Pomeriggio (12-18)"
            default: bucket = "Sera (18-24)"
            }
            buckets[bucket, default: 0] += 1
        }
        return buckets
    }

    private func topBuckets(from counts: [String: Int], limit: Int) -> [String] {
        counts.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { "\($0.key) (\($0.value))" }
    }

    private func averageMessagesPerConversation() -> String {
        guard !conversations.isEmpty else { return "dati insufficienti" }
        let validConversations = conversations.filter { !$0.messages.isEmpty }
        guard !validConversations.isEmpty else { return "dati insufficienti" }
        let totalMessages = validConversations.reduce(0) { $0 + $1.messages.count }
        let avg = Double(totalMessages) / Double(validConversations.count)
        return String(format: "%.1f", avg)
    }

    private func weekendShareRatio(messages: [ChatMessage]) -> String {
        guard !messages.isEmpty else { return "dati insufficienti" }
        let calendar = Calendar.current
        let weekendCount = messages.filter { calendar.isDateInWeekend($0.createdAt) }.count
        let ratio = Double(weekendCount) / Double(messages.count) * 100
        return String(format: "%.0f%%", ratio)
    }

    private func usageChangeTrend() -> String {
        let calendar = Calendar.current
        let now = Date()
        guard let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: now),
              let prevWeekStart = calendar.date(byAdding: .day, value: -14, to: now) else {
            return "dati insufficienti"
        }

        let lastWeekMessages = userMessages.filter { $0.createdAt >= lastWeekStart }
        let prevWeekMessages = userMessages.filter { $0.createdAt >= prevWeekStart && $0.createdAt < lastWeekStart }

        let lastWeekSessions = groupSessionsByDay(messages: lastWeekMessages).values.reduce(0) { $0 + $1.count }
        let prevWeekSessions = groupSessionsByDay(messages: prevWeekMessages).values.reduce(0) { $0 + $1.count }

        guard prevWeekSessions > 0 else {
            return lastWeekSessions > 0 ? "inizio recente dell'uso" : "dati insufficienti"
        }

        let change = (Double(lastWeekSessions) - Double(prevWeekSessions)) / Double(prevWeekSessions) * 100
        if change >= 30 {
            return "aumento significativo (+\(String(format: "%.0f", change))%)"
        }
        if change <= -30 {
            return "riduzione significativa (\(String(format: "%.0f", change))%)"
        }
        return "stabile (\(String(format: "%.0f", change))%)"
    }

    private func trendTextForMood() -> String {
        switch moodTrend {
        case .improving: return "in crescita"
        case .declining: return "in calo"
        case .stable: return "stabile"
        }
    }

    private func topMoodTags(limit: Int) -> [String] {
        let allIds = allEntries.flatMap { $0.selectedMoodIds }
        let counts = Dictionary(grouping: allIds, by: { $0 }).mapValues { $0.count }
        let sorted = counts.sorted { $0.value > $1.value }.prefix(limit)
        return sorted.compactMap { id, _ in
            MoodAdjectivesLibrary.adjectives.first { $0.id == id }?.neutral
        }
    }

    private func moodRatingsTrend() -> String {
        let calendar = Calendar.current
        let now = Date()
        guard let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: now),
              let prevWeekStart = calendar.date(byAdding: .day, value: -14, to: now) else {
            return "dati insufficienti"
        }

        let lastWeek = eveningEntries.filter { $0.date >= lastWeekStart }
        let prevWeek = eveningEntries.filter { $0.date >= prevWeekStart && $0.date < lastWeekStart }

        guard !lastWeek.isEmpty || !prevWeek.isEmpty else { return "dati insufficienti" }
        let lastAvg = lastWeek.isEmpty ? 0 : Double(lastWeek.reduce(0) { $0 + $1.moodScore }) / Double(lastWeek.count)
        let prevAvg = prevWeek.isEmpty ? 0 : Double(prevWeek.reduce(0) { $0 + $1.moodScore }) / Double(prevWeek.count)
        let delta = lastAvg - prevAvg

        if abs(delta) < 0.2 { return "stabile" }
        return delta > 0 ? "in miglioramento" : "in peggioramento"
    }

    private func averageDaysUsedLast4Weeks() -> Int {
        let last28Days = Date().addingTimeInterval(-28 * 24 * 60 * 60)
        let recentMessages = userMessages.filter { $0.createdAt >= last28Days }
        let sessionsByDay = groupSessionsByDay(messages: recentMessages)
        return sessionsByDay.keys.count
    }

    private func averageDaysPerWeek() -> Double {
        let daysUsed = averageDaysUsedLast4Weeks()
        return daysUsed > 0 ? Double(daysUsed) / 4.0 : 0
    }

    private func averageSessionsPerDay() -> Double {
        let last28Days = Date().addingTimeInterval(-28 * 24 * 60 * 60)
        let recentMessages = userMessages.filter { $0.createdAt >= last28Days }
        let sessionsByDay = groupSessionsByDay(messages: recentMessages)
        let totalSessions = sessionsByDay.values.reduce(0) { $0 + $1.count }
        return sessionsByDay.keys.isEmpty ? 0 : Double(totalSessions) / Double(sessionsByDay.keys.count)
    }

    private func topKeywordCategories(from messages: [ChatMessage], map: [String: [String]], limit: Int) -> [String] {
        guard !messages.isEmpty else { return [] }
        let texts = messages.map { $0.content.lowercased() }
        var counts: [String: Int] = [:]

        for (category, keywords) in map {
            let matches = texts.reduce(0) { partial, text in
                partial + (keywords.contains { text.contains($0) } ? 1 : 0)
            }
            if matches > 0 {
                counts[category] = matches
            }
        }

        return counts.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { "\($0.key) (\($0.value))" }
    }

    private func buildReportPayload(for report: OverviewReport) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(report),
           let json = String(data: data, encoding: .utf8) {
            return """
            Dati aggregati in JSON (non includono chat complete):
            \(json)

            Genera il report finale seguendo i requisiti del prompt di sistema.
            """
        }
        return "Dati aggregati non disponibili."
    }

    private func currentModel() -> String {
        if aiProvider == "mistral" {
            return mistralModel
        }
        if aiProvider == "groq" {
            return groqModel
        }
        return openaiModel
    }

    private func reportMetaHeader(provider: String, model: String) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let dateText = formatter.string(from: Date())
        return """
        Tranquiz - Report Overview (AI)
        Generato il \(dateText)
        Provider: \(provider.uppercased())
        Modello: \(model)
        """
    }

    private func buildReportErrorMessage(prefix: String) -> String {
        let last = Diagnostics.shared.lastAIError?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let last, !last.isEmpty {
            return "\(prefix)\nDettagli: \(last)"
        }
        return "\(prefix) Verifica provider e API key."
    }

    private enum ReportGenerationError: LocalizedError {
        case emptyResponse
        var errorDescription: String? {
            "Risposta AI vuota."
        }
    }

    private func currentReportModel() -> String {
        if aiProvider == "mistral" {
            return overviewReportModelMistral.isEmpty ? mistralModel : overviewReportModelMistral
        }
        if aiProvider == "groq" {
            return overviewReportModelGroq.isEmpty ? groqModel : overviewReportModelGroq
        }
        return overviewReportModelOpenAI.isEmpty ? openaiModel : overviewReportModelOpenAI
    }

    @MainActor
    private func saveReportLog(model: String, payload: String, response: String, outputFormat: String) async {
        let log = OverviewReportLog(
            provider: aiProvider,
            model: model,
            temperature: overviewReportTemperature,
            maxTokens: overviewReportMaxTokens,
            prompt: overviewReportPrompt,
            payload: payload,
            response: response,
            outputFormat: outputFormat
        )
        context.insert(log)
        try? context.save()
    }

    private func themeExamples(from themes: [String]) -> [String] {
        guard !themes.isEmpty else { return [] }
        let templates: [String: String] = [
            "Lavoro": "Preoccupazioni legate a carico e performance lavorativa.",
            "Relazioni": "Difficolta' nelle relazioni o paura del rifiuto.",
            "Famiglia": "Tensioni familiari e bisogno di supporto.",
            "Salute": "Ansia per sintomi fisici o benessere generale.",
            "Soldi": "Stress per spese o stabilita' economica.",
            "Autostima": "Pensieri di autosvalutazione e insicurezza.",
            "Studio": "Pressione per esami o risultati accademici.",
            "Solitudine": "Sensazione di isolamento o distanza dagli altri."
        ]

        return themes.prefix(3).compactMap { item in
            let key = item.components(separatedBy: " ").first ?? item
            return templates[key] ?? "Contenuti ricorrenti su \(key.lowercased())."
        }
    }

    private func topGoals(limit: Int) -> [String] {
        let motivations = morningEntries.compactMap { $0.morningMotivation?.lowercased() }
        guard !motivations.isEmpty else { return [] }
        var counts: [String: Int] = [:]
        for (category, keywords) in goalKeywords {
            let matches = motivations.filter { motivation in
                keywords.contains { motivation.contains($0) }
            }.count
            if matches > 0 {
                counts[category] = matches
            }
        }
        return counts.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { "\($0.key) (\($0.value))" }
    }

    private func adherenceSummary() -> String {
        let lowercased = userMessages.map { $0.content.lowercased() }
        let positive = lowercased.filter { $0.contains("ho fatto") || $0.contains("ci ho provato") || $0.contains("ho seguito") }.count
        let negative = lowercased.filter { $0.contains("non ho fatto") || $0.contains("non ci sono riuscito") || $0.contains("non sono riuscit") }.count

        if positive == 0 && negative == 0 { return "non disponibile" }
        if positive > negative { return "tendenza positiva" }
        if negative > positive { return "tendenza negativa" }
        return "mista"
    }

    private func usefulnessSummary() -> String {
        let lowercased = userMessages.map { $0.content.lowercased() }
        let positive = lowercased.filter { $0.contains("utile") || $0.contains("mi aiuta") || $0.contains("mi ha aiutato") }.count
        let negative = lowercased.filter { $0.contains("non utile") || $0.contains("non mi aiuta") || $0.contains("non ha funzionato") }.count

        if positive == 0 && negative == 0 { return "non disponibile" }
        if positive > negative { return "prevalentemente utile" }
        if negative > positive { return "prevalentemente non utile" }
        return "mista"
    }

    private func safetyMessageCount() -> String {
        guard !assistantMessages.isEmpty else { return "0" }
        let lowercased = assistantMessages.map { $0.content.lowercased() }
        let count = lowercased.filter { $0.contains("112") || $0.contains("telefono amico") || $0.contains("samaritans") }.count
        return "\(count)"
    }

    private func riskEventsSummary() -> [String] {
        let calendar = Calendar.current
        let riskKeywords = ["suicid", "farla finita", "uccidermi", "tagliarmi", "autolesion", "non voglio vivere"]
        var events: [String] = []

        for message in userMessages {
            let content = message.content.lowercased()
            if riskKeywords.contains(where: { content.contains($0) }) {
                let date = calendar.startOfDay(for: message.createdAt)
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                let dateText = formatter.string(from: date)
                events.append("possibile rischio il \(dateText)")
            }
        }
        return Array(Set(events)).sorted()
    }

    private var emotionKeywords: [String: [String]] {
        [
            "Tristezza": ["triste", "piango", "vuoto", "depress"],
            "Ansia": ["ansia", "ansioso", "panico", "agitato"],
            "Rabbia": ["rabbia", "arrabbi", "furioso"],
            "Paura": ["paura", "spavent", "terrore"],
            "Solitudine": ["solo", "isolato", "nessuno"],
            "Colpa": ["colpa", "colpevole", "vergogna"]
        ]
    }

    private var themeKeywords: [String: [String]] {
        [
            "Lavoro": ["lavoro", "ufficio", "capo", "collega", "carriera"],
            "Relazioni": ["relazione", "partner", "fidanz", "amore", "rifiuto"],
            "Famiglia": ["famiglia", "madre", "padre", "genitori", "fratell"],
            "Salute": ["salute", "malattia", "sintomo", "dolore", "ansia fisica"],
            "Soldi": ["soldi", "debiti", "stipendio", "spese", "economia"],
            "Autostima": ["vergogna", "insicuro", "sbagliato", "non valgo"],
            "Studio": ["esame", "universita", "scuola", "studio"],
            "Solitudine": ["solo", "isolato", "nessuno", "abbandono"]
        ]
    }

    private var triggerKeywords: [String: [String]] {
        [
            "Conflitti": ["litig", "discussione", "scontro"],
            "Esami/colloqui": ["esame", "colloquio", "selezione"],
            "Social": ["social", "instagram", "tiktok", "facebook"],
            "Sostanze": ["alcool", "droga", "sostanza", "fumo"],
            "Pressione": ["scadenza", "pressione", "performance"]
        ]
    }

    private var cognitiveKeywords: [String: [String]] {
        [
            "Catastrofizzazione": ["catastrof", "andra' tutto male", "disastro"],
            "Tutto o nulla": ["sempre", "mai", "tutto o nulla"],
            "Lettura del pensiero": ["pensa che", "pensano che"]
        ]
    }

    private var interventionKeywords: [String: [String]] {
        [
            "Mindfulness": ["mindfulness", "respirazione", "meditazione"],
            "CBT": ["cbt", "distorsioni", "pensieri automatici"],
            "Journaling": ["scrivi", "diario", "journaling"],
            "Psicoeducazione": ["psicoeduc", "spiegazione", "normalizzare"],
            "Esercizi pratici": ["esercizio", "prova a", "compito"]
        ]
    }

    private var goalKeywords: [String: [String]] {
        [
            "Gestione ansia": ["ansia", "panico", "agitazione", "calma"],
            "Autostima": ["autostima", "fiducia", "insicuro", "valore"],
            "Lavoro/studio": ["lavoro", "studio", "esame", "carriera"],
            "Relazioni": ["relazione", "famiglia", "partner", "amic"],
            "Benessere fisico": ["sonno", "energia", "salute", "stanchezza"],
            "Organizzazione": ["routine", "tempo", "organizzare", "abitudini"]
        ]
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

// MARK: - Report Models

struct OverviewReport: Codable {
    let generatedAt: Date
    let consentNote: [String]
    let aiNarrative: String?
    let aiProvider: String?
    let aiModel: String?
    let aiTemperature: Double?
    let aiMaxTokens: Int?
    let usage: Usage
    let emotions: Emotions
    let themes: Themes
    let interventions: Interventions
    let safety: Safety

    struct Usage: Codable {
        let daysUsedLast4Weeks: Int
        let avgDaysPerWeek: Double
        let avgSessionsPerDay: Double
        let avgMessagesPerSession: String
        let peakTimeRanges: [String]
        let weekendShare: String
        let usageChange: String
    }

    struct Emotions: Codable {
        let avgMoodScore: Double
        let moodEmoji: String
        let moodTrend: String
        let moodRatingsTrend: String
        let topMoodTags: [String]
        let autoEmotionSignals: [String]
    }

    struct Themes: Codable {
        let topThemes: [String]
        let triggers: [String]
        let cognitivePatterns: [String]
        let statedGoals: [String]
        let exampleSummaries: [String]
    }

    struct Interventions: Codable {
        let suggestedTypes: [String]
        let adherence: String
        let usefulness: String
        let safetyMessagesCount: String
    }

    struct Safety: Codable {
        let riskSignals: [String]
    }
}

// MARK: - Report Section

struct OverviewReportSection: View {
    let isDisabled: Bool
    let isGenerating: Bool
    let onExportTextTap: () -> Void
    let onExportJsonTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Report per lo psicologo")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Scarica un riepilogo sintetico con uso, trend emotivi e temi ricorrenti. Nessuna trascrizione completa.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: onExportTextTap) {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.title3)
                    Text(isGenerating ? "Generazione in corso..." : "Scarica report overview")
                        .font(.headline)
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(isDisabled ? Color.gray.opacity(0.4) : ChatStyle.accentPurpleDark)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isDisabled || isGenerating)

            Button(action: onExportJsonTap) {
                HStack(spacing: 12) {
                    Image(systemName: "curlybraces")
                        .font(.title3)
                    Text(isGenerating ? "Generazione in corso..." : "Scarica report JSON")
                        .font(.headline)
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(isDisabled ? Color.gray.opacity(0.4) : ProfileColors.softBlue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isDisabled || isGenerating)

            Text("Report generato con AI usando il provider selezionato nelle impostazioni.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
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

#Preview {
    NavigationStack {
        OverviewView()
    }
    .modelContainer(for: MoodEntry.self, inMemory: true)
}
