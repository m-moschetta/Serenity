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
    @State private var textEditorHeight: CGFloat = 32
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
        ZStack {
            ChatStyle.background
                .ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
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
                        .padding(.horizontal, 14)
                        .padding(.top, 8)
                        .padding(.bottom, 18)
                    }
                    .background(Color.clear)
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: conversation.messages.count) { _ in
                        if let last = conversation.messages.sorted(by: { $0.createdAt < $1.createdAt }).last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                    .onChange(of: photoItems) { _ in
                        Task { await handlePhotoPickerItems() }
                    }
                }
                // Removed direct composer here
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .safeAreaInset(edge: .bottom) {
            composerBackground
        }
        .navigationTitle(conversation.title)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
            // Il prompt di sistema è ora gestito automaticamente da AIService
            // Non è più necessario aggiungere manualmente un messaggio di sistema
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
    
    private var composer: some View {
        VStack(spacing: 10) {
            if !pendingImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(pendingImages.enumerated()), id: \.offset) { idx, img in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 70, height: 70)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                                Button {
                                    pendingImages.remove(at: idx)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(Color.white, Color.black.opacity(0.28))
                                        .padding(4)
                                }
                                .background(.ultraThinMaterial, in: Circle())
                                .offset(x: 8, y: -8)
                            }
                        }
                    }
                    .padding(.horizontal, 6)
                }
                .frame(height: 80)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            HStack(alignment: .bottom, spacing: 8) {
                Menu {
                    Button {
                        showPhotoPicker = true
                    } label: { Label("Libreria foto", systemImage: "photo") }
                    Button {
                        showCamera = true
                    } label: { Label("Fotocamera", systemImage: "camera") }
                } label: {
                    Image(systemName: "paperclip")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 34, height: 34)
                        .foregroundStyle(ChatStyle.accentPurpleDark)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(ChatStyle.composerBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(ChatStyle.composerStroke)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 2)
                ZStack(alignment: .topLeading) {
                    // Use a fixed dark text color to ensure readability on the always-white input background (especially in dark mode)
                    GrowingTextView(
                        text: $input,
                        minHeight: 32,
                        maxHeight: 100,
                        font: .systemFont(ofSize: 16),
                        textColor: UIColor.black,
                        textInset: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
                    ) { newHeight in
                        textEditorHeight = newHeight
                    }
                    .frame(height: textEditorHeight)

                    if input.isEmpty {
                        Text("Scrivi un messaggio…")
                            .foregroundStyle(Color.gray)
                            .font(.system(size: 16))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .allowsHitTesting(false)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.black.opacity(0.08))
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                Button(action: send) {
                    Image(systemName: sending ? "hourglass" : "paperplane.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 36, height: 36)
                        .foregroundStyle(Color.white)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(ChatStyle.sendButtonGradient)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 4)
                }
                .disabled(isSendDisabled)
                .opacity(isSendDisabled ? 0.4 : 1)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(ChatStyle.composerBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(ChatStyle.composerStroke)
                    )
            )
            .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 3)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
    
    private var composerBackground: some View {
        ZStack {
            // subtle top divider
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 0.5)
                .frame(maxWidth: .infinity, alignment: .top)
                .offset(y: -8)
            composer
        }
        .background(Color.clear)
    }

    private var outgoingBubbleColor: Color { ChatStyle.outgoingBubble }
    
    private var incomingBubbleColor: Color { ChatStyle.incomingBubble }
    
    private var isSendDisabled: Bool {
        sending || (input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && pendingImages.isEmpty)
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
        
        Task { @MainActor in
            // Create placeholder assistant message
            let assistant = ChatMessage(role: .assistant, content: "")
            assistant.conversation = conversation
            conversation.messages.append(assistant)
            conversation.updatedAt = .now
            try? context.save()

            let model = currentModel()
            let allowImages = enableMultimodal && modelSupportsVision(model: model, provider: aiProvider)
            let payload = buildPayloadMessagesForLLM(includeImages: allowImages)

            do {
                // Use the new AIService with integrated crisis detection and therapeutic prompt
                let reply = try await AIService.shared.chatWithCrisisDetection(messages: payload, model: model, temperature: 0.4, maxTokens: 800)

                // Check if the response is a crisis response (contains emergency numbers)
                if reply.contains("📞 Dove chiedere aiuto") || reply.contains("Telefono Amico") {
                    // This is a crisis response, show overlay instead of displaying the message
                    showCrisisOverlay = true
                    crisisCustomMessage = reply
                    // Remove placeholder assistant message
                    if let idx = conversation.messages.firstIndex(where: { $0.id == assistant.id }) {
                        conversation.messages.remove(at: idx)
                    }
                    try? context.save()
                    sending = false
                    streaming = false
                    return
                }

                assistant.content = reply
            } catch {
                // Fallback: retry without images
                do {
                    let textOnly = buildPayloadMessagesForLLM(includeImages: false)
                    let text = try await AIService.shared.chatWithCrisisDetection(messages: textOnly, model: model, temperature: 0.4, maxTokens: 800)
                    assistant.content = text
                } catch {
                    // Fallback 2: prova altri modelli
                    let candidates = fallbackModels(current: model, provider: aiProvider)
                    var success = false
                    for candidate in candidates {
                        let allowVision = enableMultimodal && modelSupportsVision(model: candidate, provider: aiProvider)
                        let msg = buildPayloadMessagesForLLM(includeImages: allowVision)
                        do {
                            let text = try await AIService.shared.chatWithCrisisDetection(messages: msg, model: candidate, temperature: 0.4, maxTokens: 800)
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
        TherapeuticPrompt.systemPrompt
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
            let model = currentModel()
            let summary = try await AIService.shared.provider().chat(messages: [
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
        // memories
        let memories = conversation.memories.sorted(by: { $0.createdAt > $1.createdAt }).prefix(3)
        if !memories.isEmpty {
            let memText = memories.map { "- [\($0.createdAt.formatted())] \n\($0.content)" }.joined(separator: "\n\n")
            result.append(ProviderMessage(role: "system", content: "Memoria della conversazione (riassunti recenti):\n\n\(memText)"))
        }
        // dialogue (excluding system messages as they're handled by AIService)
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

// Rilevamento di crisi ora gestito centralmente da CrisisDetection

struct ChatBubble: View {
    let message: ChatMessage
    var onImageTap: (UIImage) -> Void = { _ in }
    
    var isUser: Bool { message.role == .user }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if isUser { Spacer(minLength: 52) }
            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                bubbleContent
                    .padding(.vertical, hasImage(message) ? 8 : 10)
                    .padding(.horizontal, 12)
                    .background(bubbleBackground)
                    .overlay(
                        ChatBubbleShape(isUser: isUser)
                            .stroke(bubbleStrokeColor, lineWidth: 1)
                    )
                    .shadow(color: bubbleShadowColor, radius: 3, x: 0, y: 1)
                Text(timeString(message.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(isUser ? .trailing : .leading, 6)
            }
            if !isUser { Spacer(minLength: 52) }
        }
        .contextMenu {
            if !message.content.isEmpty {
                Button(action: { UIPasteboard.general.string = message.content }) { Label("Copia", systemImage: "doc.on.doc") }
            }
        }
    }
    
    @ViewBuilder
    private var bubbleContent: some View {
        if hasImage(message) {
            imageBubble(message)
        } else if message.content.isEmpty && !isUser {
            HStack(spacing: 6) {
                Circle().frame(width: 6, height: 6)
                Circle().frame(width: 6, height: 6)
                Circle().frame(width: 6, height: 6)
            }
            .foregroundStyle(.secondary)
            .padding(.vertical, 2)
        } else {
            Text(message.content)
                .foregroundStyle(textColor)
                .textSelection(.enabled)
        }
    }

    private var bubbleBackground: some View {
        ChatBubbleShape(isUser: isUser)
            .fill(isUser ? ChatStyle.outgoingBubble : ChatStyle.incomingBubble)
    }
    
    private var bubbleStrokeColor: Color {
        Color.black.opacity(0.08)
    }
    
    private var bubbleShadowColor: Color {
        Color.black.opacity(isUser ? 0.12 : 0.05)
    }
    
    private var textColor: Color {
        Color.black.opacity(0.87)
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
                        .frame(maxWidth: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.black.opacity(0.08), lineWidth: 0.8)
                        )
                        .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 6)
                        .onTapGesture { onImageTap(ui) }
                }
            }
            if !msg.content.isEmpty {
                Text(msg.content)
                    .foregroundStyle(textColor)
            }
        }
    }
}

fileprivate enum ChatStyle {
    // Purple gradient background with good contrast
    static let background: LinearGradient = LinearGradient(
        colors: [
            Color(red: 82/255, green: 36/255, blue: 154/255),   // deep purple
            Color(red: 140/255, green: 82/255, blue: 255/255)   // vivid purple
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Accents tuned for contrast on purple
    static let accentPurpleLight: Color = Color(red: 190/255, green: 160/255, blue: 255/255)
    static let accentPurpleDark: Color = Color(red: 120/255, green: 60/255, blue: 220/255)

    static let sendButtonGradient: LinearGradient = LinearGradient(
        colors: [accentPurpleLight, accentPurpleDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Bubble colors: ensure strong contrast with text
    static let outgoingBubble: Color = Color.white // user messages on white with dark text
    static let incomingBubble: Color = Color.white.opacity(0.9) // assistant slightly tinted but still high contrast

    // Composer container background on purple
    static let composerBackground: Color = Color.white.opacity(0.95)
    static let composerStroke: Color = Color.black.opacity(0.06)
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
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color.white.opacity(0.9))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.15), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.25))
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
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
            let model: String
            if aiProvider == "mistral" {
                model = mistralModel
            } else if aiProvider == "groq" {
                model = groqModel
            } else {
                model = openaiModel
            }
            let summary = try await AIService.shared.provider().chat(messages: [
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

