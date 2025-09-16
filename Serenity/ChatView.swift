//
//  ChatView.swift
//  Serenity
//
//  Chat UI and logic
//

import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct MainChatView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Conversation.createdAt, order: .forward) private var conversations: [Conversation]
    
    var body: some View {
        Group {
            if let conv = conversations.first {
                SingleChatView(conversation: conv)
            } else {
                ProgressView().onAppear { ensureConversation() }
            }
        }
    }
    
    private func ensureConversation() {
        if conversations.isEmpty {
            let c = Conversation()
            context.insert(c)
            try? context.save()
        }
    }
}

struct SingleChatView: View {
    @Environment(\.modelContext) private var context
    @State private var input: String = ""
    @State private var sending = false
    @State private var streaming = false
    @State private var streamStarted = false
    @State private var showingSettings = false
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var pendingImages: [UIImage] = []
    @State private var fullScreenImage: UIImage?
    @AppStorage("aiProvider") private var aiProvider: String = "openai"
    @AppStorage("openaiModel") private var openaiModel: String = "gpt-5"
    @AppStorage("mistralModel") private var mistralModel: String = "mistral-large-latest"
    @AppStorage("groqModel") private var groqModel: String = "llama3-8b-8192"
    @AppStorage("systemPrompt") private var storedSystemPrompt: String = """
Sei un chatbot progettato per supportare le persone attraverso un dialogo empatico, personalizzato e rispettoso, ispirato al modo in cui un terapeuta umano esperto si relaziona con i propri pazienti. Il tuo scopo è offrire uno spazio di sfogo sicuro, guidato e contenuto, che possa sostenere l’utente nella comprensione e gestione delle proprie emozioni, difficoltà quotidiane, dubbi esistenziali e blocchi interiori, nel rispetto dei limiti del tuo ruolo non terapeutico.

🎯 Obiettivo principale
Fornire ascolto attivo, supporto emotivo e spunti di riflessione attraverso un linguaggio personalizzato e umano. Le risposte devono sempre far sentire la persona ascoltata profondamente, accolta senza giudizio, mai asseconda né banalizzata, rispettata nei tempi e nei modi.
Non sei un sostituto di un terapeuta: niente diagnosi o consigli clinici.

🔐 Sicurezza e gestione delle emergenze
Se ricevi segnali anche minimi di ideazione suicidaria, autolesionismo o rischio imminente:
- Blocca immediatamente la conversazione.
- Fornisci un unico messaggio empatico che indirizzi a contatto umano immediato.
- Non offrire alternative, non indagare, non proseguire.
- Mostra solo numeri ufficiali e fonti certificate.

🧠 Modalità di risposta
Personalizza profondamente il linguaggio; evita formule generiche e toni robotici. Stile simile a un terapeuta umano: diretto ma delicato, empatico ma non compiacente, caldo e centrato.

📚 Tecniche: ascolto riflessivo, domande aperte, normalizzazione senza banalizzare, validazione emotiva, micro-suggerimenti, silenzio utile.

📝 Memoria: usa i riferimenti alle conversazioni precedenti per continuità e per evitare ripetizioni.

🧭 Tono: calmo, accogliente, maturo, profondo; coerente con l’energia dell’utente; evita cliché e positività forzata.

❌ Evita: diagnosi, frasi impersonali, soluzioni prescrittive, minimizzazione, toni paternalistici.
"""
    @AppStorage("summaryPrompt") private var storedSummaryPrompt: String = "Crea un riassunto strutturato e conciso della conversazione. Struttura obbligatoria: \n# Sintesi \n- punti chiave (3-6) \n# Stati Emotivi \n- osservazioni principali \n# Strategie Discusse \n- tecniche, esercizi, compiti \n# Prossimi Passi \n- azioni concrete per la prossima settimana. \nMantieni un tono professionale ed empatico. Conversazione:"
    @AppStorage("enableMultimodal") private var enableMultimodal: Bool = true
    
    let conversation: Conversation
    @State private var showShare = false
    @State private var exportURL: URL?
    @State private var showCrisisOverlay = false
    @State private var crisisOverrideNumber: String? = nil
    @State private var crisisOverrideExtraLabel: String? = nil
    @State private var crisisOverrideExtraNumber: String? = nil
    @State private var crisisCustomMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        let visible = conversation.messages
                            .filter { $0.role != .system }
                            .sorted(by: { $0.createdAt < $1.createdAt })
                        ForEach(Array(visible.enumerated()), id: \.element.id) { index, msg in
                            if index == 0 || !Calendar.current.isDate(visible[index - 1].createdAt, inSameDayAs: msg.createdAt) {
                                DateSeparator(date: msg.createdAt)
                            }
                            ChatBubble(message: msg, onImageTap: { img in fullScreenImage = img })
                                .id(msg.id)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .onChange(of: conversation.messages.count) { _ in
                    if let last = conversation.messages.sorted(by: { $0.createdAt < $1.createdAt }).last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
                .onChange(of: photoItems) { _ in
                    Task { await handlePhotoPickerItems() }
                }
            }
            Divider()
            if !pendingImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(pendingImages.enumerated()), id: \.offset) { idx, img in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 72, height: 72)
                                    .clipped()
                                    .cornerRadius(12)
                                Button {
                                    pendingImages.remove(at: idx)
                                } label: {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(.white).background(.black.opacity(0.4)).clipShape(Circle())
                                }
                                .offset(x: 6, y: -6)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .frame(height: 80)
            }
            HStack(alignment: .bottom, spacing: 8) {
                // Attachments
                Menu {
                    Button {
                        showPhotoPicker = true
                    } label: { Label("Libreria foto", systemImage: "photo") }
                    Button {
                        showCamera = true
                    } label: { Label("Fotocamera", systemImage: "camera") }
                } label: {
                    Image(systemName: "paperclip").font(.title3)
                }
                TextEditor(text: $input)
                    .frame(minHeight: 16, maxHeight: 40)
                    .padding(6)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(alignment: .topLeading) {
                        if input.isEmpty { Text("Scrivi un messaggio…").foregroundStyle(.secondary).padding(10) }
                    }
                Button(action: send) {
                    Image(systemName: sending ? "hourglass" : "paperplane.fill")
                        .font(.title3)
                }
                .disabled(sending || (input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && pendingImages.isEmpty))
            }
            .padding(.all, 12)
        }
        .navigationTitle(conversation.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { exportConversation() } label: { Image(systemName: "square.and.arrow.up") }
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: MemoriesView(conversation: conversation)) {
                    Image(systemName: "clock.arrow.circlepath")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingSettings = true } label: { Image(systemName: "gearshape") }
            }
        }
        .onAppear {
            if conversation.messages.isEmpty {
                let sys = ChatMessage(role: .system, content: systemPrompt())
                sys.conversation = conversation
                conversation.messages.append(sys)
                try? context.save()
            }
        }
        .sheet(isPresented: $showShare) {
            if let url = exportURL { ShareSheet(items: [url]) }
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoItems, maxSelectionCount: 6, matching: .images)
        .sheet(isPresented: $showCamera) {
            CameraPicker { image in
                if let image { pendingImages.append(image) }
                showCamera = false
            }
        }
        .fullScreenCover(item: $fullScreenImage, onDismiss: {}) { img in
            ImageViewer(image: img)
        }
        .fullScreenCover(isPresented: $showCrisisOverlay) {
            CrisisOverlayView(
                isPresented: $showCrisisOverlay,
                overridePrimaryNumber: crisisOverrideNumber,
                customMessage: crisisCustomMessage,
                overrideExtraLabel: crisisOverrideExtraLabel,
                overrideExtraNumber: crisisOverrideExtraNumber
            )
        }
        
    }
    
    private func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty && pendingImages.isEmpty { return }
        input = ""
        sending = true
        streaming = true
        streamStarted = false
        
        let user = ChatMessage(role: .user, content: text)
        user.conversation = conversation
        if !pendingImages.isEmpty {
            for img in pendingImages {
                if let name = try? ImageStore.saveJPEG(img) {
                    let att = Attachment(type: .image, localPath: name)
                    att.message = user
                    user.attachments.append(att)
                }
            }
            pendingImages.removeAll()
        }
        conversation.messages.append(user)
        conversation.updatedAt = .now
        try? context.save()
        
        // Crisis detection (local safety net): for non-OpenAI providers only
        if aiProvider != "openai" && detectCrisis(in: text) {
            sending = false
            streaming = false
            streamStarted = false
            showCrisisOverlay = true
            return
        }

        Task { @MainActor in
            // Create placeholder assistant message
            let assistant = ChatMessage(role: .assistant, content: "")
            assistant.conversation = conversation
            conversation.messages.append(assistant)
            conversation.updatedAt = .now
            try? context.save()

            let provider = AIService.shared.provider()
            let model = currentModel()
            let allowImages = enableMultimodal && modelSupportsVision(model: model, provider: aiProvider)
            var payload = buildPayloadMessagesForLLM(includeImages: allowImages)
            do {
                if aiProvider == "openai" {
                    // Add tool awareness system instruction
                    payload.insert(ProviderMessage(role: "system", content: "Se rilevi segnali anche minimi di ideazione suicidaria, autolesionismo o rischio imminente, NON fornire risposta. Invece, invoca la funzione 'call_emergency_number' con un breve messaggio empatico (campo crisis_message) e il numero corretto se noto; altrimenti lascia number vuoto per usare il predefinito."), at: 1)
                    // Define tool
                    let tool = OpenAITool(
                        type: "function",
                        function: OpenAIToolFunction(
                            name: "call_emergency_number",
                            description: "Usa questo strumento quando l'utente mostra segnali di suicidio/autolesionismo o pericolo imminente. Non rispondere in chat: attiva solo questo strumento.",
                            parameters: JSONSchema(
                                type: "object",
                                properties: [
                                    "crisis_message": JSONSchemaProperty(type: "string", description: "Breve messaggio empatico e fermo da mostrare nell'overlay."),
                                    "number": JSONSchemaProperty(type: "string", description: "Numero da chiamare. Lascia vuoto per usare il predefinito (es. 112)."),
                                    "extra_label": JSONSchemaProperty(type: "string", description: "Etichetta per numero di supporto secondario (opzionale)."),
                                    "extra_number": JSONSchemaProperty(type: "string", description: "Numero di supporto secondario (opzionale).")
                                ],
                                required: ["crisis_message"]
                            )
                        )
                    )
                    let result = try await OpenAIClient.shared.chatWithTools(messages: payload, model: model, temperature: 0.4, maxTokens: 800, tools: [tool])
                    switch result {
                    case .content(let text):
                        assistant.content = text
                    case .tool(let name, let argumentsJSON):
                        if name == "call_emergency_number" {
                            // Parse arguments
                            struct Args: Decodable { let crisis_message: String?; let number: String?; let extra_label: String?; let extra_number: String? }
                            if let data = argumentsJSON.data(using: .utf8), let args = try? JSONDecoder().decode(Args.self, from: data) {
                                crisisCustomMessage = args.crisis_message
                                crisisOverrideNumber = args.number
                                crisisOverrideExtraLabel = args.extra_label
                                crisisOverrideExtraNumber = args.extra_number
                            }
                            // Show overlay and stop
                            showCrisisOverlay = true
                            // Remove placeholder assistant message (keep conversation integrity minimal)
                            if let idx = conversation.messages.firstIndex(where: { $0.id == assistant.id }) {
                                conversation.messages.remove(at: idx)
                            }
                            try? context.save()
                            sending = false
                            streaming = false
                            return
                        } else {
                            assistant.content = ""
                        }
                    }
                } else {
                    let reply = try await provider.chat(messages: payload, model: model, temperature: 0.4, maxTokens: 800)
                    assistant.content = reply
                }
            } catch {
                // Fallback: retry without images
                do {
                    let textOnly = buildPayloadMessagesForLLM(includeImages: false)
                    let text = try await provider.chat(messages: textOnly, model: model, temperature: 0.4, maxTokens: 800)
                    assistant.content = text
                } catch {
                    // Fallback 2: prova altri modelli
                    let candidates = fallbackModels(current: model, provider: aiProvider)
                    var success = false
                    for candidate in candidates {
                        let allowVision = enableMultimodal && modelSupportsVision(model: candidate, provider: aiProvider)
                        let msg = buildPayloadMessagesForLLM(includeImages: allowVision)
                        do {
                            let text = try await provider.chat(messages: msg, model: candidate, temperature: 0.4, maxTokens: 800)
                            assistant.content = text
                            success = true
                            break
                        } catch { continue }
                    }
                    if !success {
                        assistant.content = "Errore durante la risposta. Verifica l'API key e il modello selezionato nelle Impostazioni."
                    }
                }
            }
            conversation.updatedAt = .now
            try? context.save()
            await maybeSummarize()
            sending = false
            streaming = false
        }
    }
    
    private func systemPrompt() -> String {
        storedSystemPrompt
    }

    private func currentModel() -> String {
        if aiProvider == "mistral" {
            return mistralModel
        } else if aiProvider == "groq" {
            return groqModel
        } else {
            return openaiModel
        }
    }
    
    private func maybeSummarize() async {
        // Esegui un riassunto ogni 12 messaggi utente+assistant (escludendo system)
        let msgs = conversation.messages.filter { $0.role != .system }
        let lastCount = msgs.count
        guard lastCount % 12 == 0 else { return }
        do {
            let contextPreview = msgs.suffix(60).map { "\($0.role == .user ? "Utente" : "Assistente"): \($0.content)" }.joined(separator: "\n")
            let prompt = storedSummaryPrompt + "\n\n" + contextPreview
            let provider = AIService.shared.provider()
            let model = currentModel()
            let summary = try await provider.chat(messages: [
                ProviderMessage(role: "system", content: "Sei un assistente che distilla conversazioni in riassunti utili e organizzati."),
                ProviderMessage(role: "user", content: prompt)
            ], model: model, temperature: 0.3, maxTokens: 600)
            let mem = MemorySummary(content: summary, messageCount: lastCount)
            mem.conversation = conversation
            conversation.memories.append(mem)
            try? context.save()
        } catch {
            print("Summarization error: \(error)")
        }
    }
}

extension SingleChatView {
    private func handlePhotoPickerItems() async {
        guard !photoItems.isEmpty else { return }
        let items = photoItems
        photoItems.removeAll()
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self), let ui = UIImage(data: data) {
                pendingImages.append(ui)
            }
        }
    }
    
    
    private func buildPayloadMessagesForLLM(includeImages: Bool) -> [ProviderMessage] {
        var result: [ProviderMessage] = []
        // system prompt
        result.append(ProviderMessage(role: "system", content: storedSystemPrompt))
        // memories
        let memories = conversation.memories.sorted(by: { $0.createdAt > $1.createdAt }).prefix(3)
        if !memories.isEmpty {
            let memText = memories.map { "- [\($0.createdAt.formatted())] \n\($0.content)" }.joined(separator: "\n\n")
            result.append(ProviderMessage(role: "system", content: "Memoria della conversazione (riassunti recenti):\n\n\(memText)"))
        }
        // dialogue
        for m in conversation.messages.sorted(by: { $0.createdAt < $1.createdAt }) where m.role != .system {
            var text = m.content
            if !m.attachments.isEmpty {
                let count = m.attachments.count
                let note = "[\(count) immagine\(count > 1 ? "i" : "")] allegata\(count > 1 ? "e" : "")."
                text = text.isEmpty ? note : text + "\n\n" + note
            }
            result.append(ProviderMessage(role: m.role.rawValue, content: text))
        }
        return result
    }
    private func exportConversation() {
        let text = generateMarkdown()
        let filename = "Serenity-\(conversation.title.replacingOccurrences(of: " ", with: "_"))-\(Int(Date().timeIntervalSince1970)).md"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try text.data(using: .utf8)?.write(to: url)
            exportURL = url
            showShare = true
        } catch {
            print("Export error: \(error)")
        }
    }
    
    private func generateMarkdown() -> String {
        var md = "# \(conversation.title)\n\n"
        md += "Creato: \(conversation.createdAt)\n\n"
        md += "## Conversazione\n\n"
        for msg in conversation.messages.sorted(by: { $0.createdAt < $1.createdAt }) {
            let who: String
            switch msg.role {
            case .user: who = "Utente"
            case .assistant: who = "Assistente"
            case .system: who = "Sistema"
            }
            if !msg.attachments.isEmpty {
                let list = msg.attachments.map { "- immagine: \($0.localPath)" }.joined(separator: "\n")
                md += "**\(who)**: (allegati)\n\(list)\n"
                if !msg.content.isEmpty { md += msg.content + "\n" }
                md += "\n"
            } else {
                md += "**\(who)**: \(msg.content)\n\n"
            }
        }
        if !conversation.memories.isEmpty {
            md += "## Memorie\n\n"
            for mem in conversation.memories.sorted(by: { $0.createdAt < $1.createdAt }) {
                md += "### \(mem.createdAt) — \(mem.messageCount) messaggi\n\n"
                md += mem.content + "\n\n"
            }
        }
        return md
    }
    
    private func fallbackModels(current: String, provider: String) -> [String] {
        let lower = current.lowercased()
        if provider == "openai" {
            let list = ModelCatalog.shared.openaiModels
            return list.filter { $0.lowercased() != lower }
        } else if provider == "mistral" {
            let list = ModelCatalog.shared.mistralModels
            return list.filter { $0.lowercased() != lower }
        } else {
            let list = ModelCatalog.shared.groqModels
            return list.filter { $0.lowercased() != lower }
        }
    }

    private func modelSupportsVision(model: String, provider: String) -> Bool {
        let lower = model.lowercased()
        if provider == "openai" {
            if lower.contains("vision") { return true }
            if lower.contains("4o") || lower.contains("4.1") || lower.contains("o4") { return true }
            if lower.contains("gpt-5") { return true }
        } else if provider == "mistral" {
            if lower.contains("pixtral") || lower.contains("vision") { return true }
        } else if provider == "groq" {
            // Groq attualmente non supporta immagini
            return false
        }
        return false
    }
}

extension SingleChatView {
    fileprivate func detectCrisis(in text: String) -> Bool {
        let t = text.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        let keywords = [
            "suicid", // suicidio, suicidarmi, suicidare
            "mi uccido", "uccidermi", "ammazzarmi", "mi ammazzo",
            "togliermi la vita",
            "non voglio piu vivere", "non voglio più vivere",
            "autoles", // autolesionismo
            "farmi del male", "farmi male", "ferirmi", "tagliarmi",
            "voglio morire", "vorrei morire", "sto per farmi del male"
        ]
        for k in keywords { if t.contains(k) { return true } }
        return false
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    var onImageTap: (UIImage) -> Void = { _ in }
    
    var isUser: Bool { message.role == .user }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 48) }
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Group {
                if hasImage(message) {
                    imageBubble(message)
                } else if message.content.isEmpty && !isUser {
                    HStack(spacing: 6) {
                        Circle().frame(width: 6, height: 6)
                        Circle().frame(width: 6, height: 6)
                        Circle().frame(width: 6, height: 6)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
                } else {
                    Text(message.content)
                        .foregroundStyle(isUser ? .white : .primary)
                        .textSelection(.enabled)
                }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(isUser ? Color.accentColor : Color(.secondarySystemBackground))
                .clipShape(ChatBubbleShape(isUser: isUser))
                Text(timeString(message.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(isUser ? .trailing : .leading, 6)
            }
            if !isUser { Spacer(minLength: 48) }
        }
        .contextMenu {
            if !message.content.isEmpty {
                Button(action: { UIPasteboard.general.string = message.content }) { Label("Copia", systemImage: "doc.on.doc") }
            }
        }
    }
    
    private func hasImage(_ msg: ChatMessage) -> Bool { !msg.attachments.isEmpty }
    
    @ViewBuilder
    private func imageBubble(_ msg: ChatMessage) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(msg.attachments) { att in
                if let ui = ImageStore.load(att.localPath) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: 280)
                        .clipped()
                        .cornerRadius(16)
                        .onTapGesture { onImageTap(ui) }
                }
            }
            if !msg.content.isEmpty {
                Text(msg.content)
                    .foregroundStyle(isUser ? .white : .primary)
            }
        }
    }
}

private func timeString(_ date: Date) -> String {
    let df = DateFormatter()
    df.locale = .current
    df.dateStyle = .none
    df.timeStyle = .short
    return df.string(from: date)
}

struct ChatBubbleShape: Shape {
    let isUser: Bool
    func path(in rect: CGRect) -> Path {
        var path = Path(roundedRect: rect, cornerSize: CGSize(width: 18, height: 18))
        // Tail effect could be added here if desired
        return path
    }
}

struct DateSeparator: View {
    let date: Date
    var body: some View {
        Text(label(for: date))
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
    }
    private func label(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Oggi" }
        if cal.isDateInYesterday(date) { return "Ieri" }
        let df = DateFormatter()
        df.locale = .current
        df.dateStyle = .medium
        df.timeStyle = .none
        return df.string(from: date)
    }
}

struct MemoriesView: View {
    @Environment(\.modelContext) private var context
    let conversation: Conversation
    @AppStorage("aiProvider") private var aiProvider: String = "openai"
    @AppStorage("openaiModel") private var openaiModel: String = "gpt-5-mini"
    @AppStorage("mistralModel") private var mistralModel: String = "mistral-large-latest"
    @AppStorage("groqModel") private var groqModel: String = "llama3-8b-8192"
    @AppStorage("summaryPrompt") private var storedSummaryPrompt: String = "Crea un riassunto strutturato e conciso della conversazione. Struttura obbligatoria: \n# Sintesi \n- punti chiave (3-6) \n# Stati Emotivi \n- osservazioni principali \n# Strategie Discusse \n- tecniche, esercizi, compiti \n# Prossimi Passi \n- azioni concrete per la prossima settimana. \nMantieni un tono professionale ed empatico. Conversazione:"
    
    var body: some View {
        List {
            ForEach(conversation.memories.sorted(by: { $0.createdAt > $1.createdAt })) { mem in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(mem.createdAt, style: .date)
                        Text(mem.createdAt, style: .time)
                        Spacer()
                        Text("\(mem.messageCount) messaggi").foregroundStyle(.secondary)
                    }.font(.subheadline)
                    Text(mem.content)
                }
                .padding(.vertical, 6)
            }
            .onDelete { idx in
                for i in idx { context.delete(conversation.memories.sorted(by: { $0.createdAt > $1.createdAt })[i]) }
                try? context.save()
            }
        }
        .navigationTitle("Memorie")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Aggiorna") { Task { await forceSummarize() } } } }
    }
    
    private func forceSummarize() async {
        let msgs = conversation.messages.filter { $0.role != .system }
        let contextPreview = msgs.suffix(60).map { "\($0.role == .user ? "Utente" : "Assistente"): \($0.content)" }.joined(separator: "\n")
        do {
            let prompt = storedSummaryPrompt + "\n\n" + contextPreview
            let provider = AIService.shared.provider()
            let model: String
            if aiProvider == "mistral" {
                model = mistralModel
            } else if aiProvider == "groq" {
                model = groqModel
            } else {
                model = openaiModel
            }
            let summary = try await provider.chat(messages: [
                ProviderMessage(role: "system", content: "Sei un assistente che distilla conversazioni in riassunti utili e organizzati."),
                ProviderMessage(role: "user", content: prompt)
            ], model: model, temperature: 0.3, maxTokens: 600)
            let mem = MemorySummary(content: summary, messageCount: msgs.count)
            mem.conversation = conversation
            conversation.memories.append(mem)
            try? context.save()
        } catch {
            print("Force summarize error: \(error)")
        }
    }
}
