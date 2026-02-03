//
//  SettingsView.swift
//  Serenity
//
//  Manage API key and preferences
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = KeychainService.shared.apiKey ?? ""
    @State private var showingKey = false
    @State private var saved = false
    @State private var mistralKey: String = KeychainService.shared.mistralApiKey ?? ""
    @State private var groqKey: String = KeychainService.shared.groqApiKey ?? ""
    @State private var emergencyEmail: String = ""
    @State private var showEmergencyEmailField = false
    @AppStorage("developerMode") private var developerMode: Bool = false
    @State private var devTapCount: Int = 0
    @State private var showDevUnlockedAlert: Bool = false
    @AppStorage("aiProvider") private var aiProvider: String = "openai" // openai|mistral|groq
    @AppStorage("openaiModel") private var openaiModel: String = "gpt-5.2"
    @AppStorage("mistralModel") private var mistralModel: String = "mistral-large-latest"
    @AppStorage("groqModel") private var groqModel: String = "llama3-8b-8192"
    @AppStorage("systemPrompt") private var systemPrompt: String = """
Sei un chatbot progettato per supportare le persone attraverso un dialogo empatico, personalizzato e rispettoso, ispirato al modo in cui un terapeuta umano esperto si relaziona con i propri pazienti. Il tuo scopo è offrire uno spazio di sfogo sicuro, guidato e contenuto, che possa sostenere l’utente nella comprensione e gestione delle proprie emozioni, difficoltà quotidiane, dubbi esistenziali e blocchi interiori, nel rispetto dei limiti del tuo ruolo non terapeutico.

🎯 Obiettivo principale
Fornire ascolto attivo, supporto emotivo e spunti di riflessione attraverso un linguaggio personalizzato e umano. Le tue risposte devono sempre far sentire la persona:

- ascoltata profondamente,
- accolta senza giudizio,
- mai asseconda né banalizzata,
- rispettata nei tempi e nei modi della propria comunicazione.
Tu non sei un sostituto di un terapeuta. Non diagnostichi, non dai consigli clinici, non ti sostituisci a percorsi terapeutici reali. Sei un facilitatore, un diario emotivo intelligente, un alleato gentile nel percorso dell’utente.

🔐 Sicurezza e gestione delle emergenze
Se ricevi segnali anche minimi di ideazione suicidaria, autolesionismo, rischio di danno imminente o altra emergenza psicologica:
- Blocca immediatamente la conversazione.
- Rispondi una sola volta con tono empatico ma fermo, orientando l’utente a cercare aiuto umano immediato.
- Non offrire alternative, non indagare ulteriormente, non proseguire la conversazione.
- Mostra solo numeri ufficiali e fonti certificate.

🧠 Modalità di risposta
Ogni risposta deve essere profondamente personalizzata. Analizza attentamente tono, parole, stile comunicativo e stato emotivo dell’utente per costruire una risposta che rifletta la sua unicità.
Non usare formule generiche, istruzioni meccaniche o risposte standard. Mai sembrare "robotico".
Imita lo stile comunicativo del terapeuta umano: diretto ma delicato, empatico ma non compiacente, caldo ma centrato.

📌 Lunghezza e coinvolgimento
- Nella maggior parte dei casi rispondi in modo conciso (circa 2–5 frasi). Evita spiegazioni lunghe e liste estese.
- Procedi per piccoli passi: valida un punto centrale, poi fai una sola domanda aperta e leggera per invitare l’utente a continuare.
- Aumenta il livello di dettaglio solo se l’utente lo chiede esplicitamente o se serve per chiarezza/sicurezza.
- In caso di crisi, ignora queste regole e segui il protocollo di sicurezza sopra.

📚 Tecniche da utilizzare
Applica i seguenti principi psicologici nel rispondere:
- Ascolto riflessivo: parafrasa ciò che l’utente dice senza distorcere il significato.
- Domande aperte (senza pressare): “Cosa senti in questo momento?”, “Ti va di raccontarmi di più?”.
- Normalizzazione (senza banalizzare): “Molte persone attraversano momenti come questo, e ogni emozione ha diritto di esistere.”
- Validazione emotiva: “È comprensibile sentirsi così dopo quello che hai vissuto.”
- Micro-suggerimenti: spunti gentili e non direttivi (es. “Hai mai notato se…?”, “Cosa succede in te quando pensi a…?”).
- Silenzio utile: se l’utente esprime qualcosa di molto profondo, puoi rispondere anche con frasi brevi e centrate.

📝 Memoria delle conversazioni
Hai accesso alla memoria storica delle conversazioni con ogni utente. Usa questo dato per:
- Fare riferimenti a conversazioni passate (es. “Mi hai detto qualche giorno fa che…”).
- Rilevare evoluzioni, stati d’animo ricorrenti, bisogni impliciti.
- Evitare ripetizioni e risposte disconnesse dal contesto personale.

🧭 Tono di voce
Sempre calmo, accogliente, maturo, profondo.
Usa un tono coerente con l’energia dell’utente.
Evita frasi motivazionali vuote, cliché psicologici o toni forzatamente positivi.

❌ Evita sempre:
- Diagnosi o etichette cliniche.
- Frasi impersonali (“Come assistente virtuale…”, “Mi dispiace che ti senti così.”).
- Soluzioni immediate o prescrittive.
- Minimizzazione del problema.
- Toni paternalistici o eccessivamente ottimistici.

✅ Esempio di risposta efficace:
Utente:
“Non riesco più a parlare con nessuno. Mi sembra che nessuno possa capirmi, e ogni volta che ci provo mi sento stupido.”
Assistente:
“Grazie per aver condiviso questa parte così delicata di te. Sento che ti stai sforzando molto per cercare un contatto, anche se poi ti senti solo e frainteso.
A volte, quando ci sentiamo invisibili, può nascere quella voce interna che ci fa dubitare di noi stessi… eppure io ti sto ascoltando proprio adesso, e non trovo nulla di stupido in ciò che dici.
Ti va di dirmi quando è iniziato questo senso di distanza dagli altri?”

Nota: in caso di rischio o emergenza, interrompi e indirizza a contatto umano immediato, come sopra.
"""
    @AppStorage("enableMultimodal") private var enableMultimodal: Bool = true
    @AppStorage("chatTemperature") private var chatTemperature: Double = 0.4
    @AppStorage("summaryPrompt") private var summaryPrompt: String = "Crea un riassunto strutturato e conciso della conversazione. Struttura obbligatoria: \n# Sintesi \n- punti chiave (3-6) \n# Stati Emotivi \n- osservazioni principali \n# Strategie Discusse \n- tecniche, esercizi, compiti \n# Prossimi Passi \n- azioni concrete per la prossima settimana. \nMantieni un tono professionale ed empatico. Conversazione:"
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
    @AppStorage("overviewReportModelOpenAI") private var overviewReportModelOpenAI: String = ""
    @AppStorage("overviewReportModelMistral") private var overviewReportModelMistral: String = ""
    @AppStorage("overviewReportModelGroq") private var overviewReportModelGroq: String = ""
    @AppStorage("overviewReportTemperature") private var overviewReportTemperature: Double = 0.2
    @AppStorage("overviewReportMaxTokens") private var overviewReportMaxTokens: Int = 900
    @State private var promptTapCount = 0
    @State private var showPromptEditor = false
    @State private var showingDiagAlert = false
    @State private var diagMessage = ""
    @AppStorage("singleChatMode") private var singleChatMode: Bool = false
    @AppStorage("preferredAppearance") private var preferredAppearance: String = "system" // system|light|dark
    @AppStorage("onboardingCompleted") private var onboardingCompleted: Bool = false
    @AppStorage("onboardingSummary") private var onboardingSummary: String = ""
    @ObservedObject private var catalog = ModelCatalog.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Onboarding") {
                    if onboardingSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Profilo non ancora compilato.")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(onboardingSummary)
                            .font(.footnote)
                            .onTapGesture {
                                guard !developerMode else { return }
                                devTapCount += 1
                                if devTapCount >= 10 {
                                    developerMode = true
                                    devTapCount = 0
                                    showDevUnlockedAlert = true
                                }
                            }
                    }
                    Button("Ricomincia onboarding") {
                        OnboardingStorage.shared.clear()
                        onboardingSummary = ""
                        onboardingCompleted = false
                    }
                }

                ToneSettingsSection()

                NotificationSettingsSection()

                EmergencyContactSection(
                    emergencyEmail: $emergencyEmail,
                    showEmailField: $showEmergencyEmailField
                )

                Section("Aspetto") {
                    Picker("Tema", selection: $preferredAppearance) {
                        Text("Sistema").tag("system")
                        Text("Chiaro").tag("light")
                        Text("Scuro").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }

                if developerMode {
                    Section("Chat") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Temperatura")
                                Spacer()
                                Text(String(format: "%.2f", chatTemperature))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            Slider(value: $chatTemperature, in: 0...1, step: 0.05)
                            Text("Più bassa = più deterministico, più alta = più creativo.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section("Report overview") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Temperatura report")
                                Spacer()
                                Text(String(format: "%.2f", overviewReportTemperature))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            Slider(value: $overviewReportTemperature, in: 0...1, step: 0.05)
                            Text("Piu bassa = piu deterministico.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("Max token report")
                            Spacer()
                            Stepper(value: $overviewReportMaxTokens, in: 200...2000, step: 50) {
                                Text("\(overviewReportMaxTokens)")
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Section("OpenAI") {
                        HStack {
                            if showingKey {
                                TextField("API Key", text: $apiKey)
                                    .textInputAutocapitalization(.never)
                                    .textContentType(.password)
                                    .autocorrectionDisabled()
                                    .foregroundStyle(.primary)
                            } else {
                                SecureField("API Key", text: $apiKey)
                                    .textInputAutocapitalization(.never)
                                    .textContentType(.password)
                                    .autocorrectionDisabled()
                                    .foregroundStyle(.primary)
                            }
                            Button(showingKey ? "Nascondi" : "Mostra") { showingKey.toggle() }
                        }
                        Button("Salva") {
                            KeychainService.shared.apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                            saved = true
                        }
                        .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        if saved { Text("Salvato").foregroundStyle(.secondary) }
                    }

                    Section("Mistral") {
                        SecureField("API Key", text: $mistralKey)
                            .textInputAutocapitalization(.never)
                            .textContentType(.password)
                            .autocorrectionDisabled()
                            .foregroundStyle(.primary)
                        Button("Salva") {
                            KeychainService.shared.mistralApiKey = mistralKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        .disabled(mistralKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    Section("Groq") {
                        SecureField("API Key", text: $groqKey)
                            .textInputAutocapitalization(.never)
                            .textContentType(.password)
                            .autocorrectionDisabled()
                            .foregroundStyle(.primary)
                        Button("Salva") {
                            KeychainService.shared.groqApiKey = groqKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        .disabled(groqKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        HStack {
                            Button("Aggiorna modelli Groq") {
                                Task {
                                    do {
                                        let typed = groqKey.trimmingCharacters(in: .whitespacesAndNewlines)
                                        let keyToUse: String
                                        if !typed.isEmpty {
                                            keyToUse = typed
                                        } else if let saved = KeychainService.shared.groqApiKey, !saved.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            keyToUse = saved
                                        } else {
                                            keyToUse = "" // trigger proxy fallback in ModelCatalog
                                        }
                                        try await catalog.refreshGroq(apiKey: keyToUse)
                                        diagMessage = "Modelli Groq aggiornati: \(catalog.groqModels.count)"
                                        showingDiagAlert = true
                                    } catch {
                                        let last = Diagnostics.shared.lastAIError ?? error.localizedDescription
                                        diagMessage = "Errore: \(last)"
                                        showingDiagAlert = true
                                    }
                                }
                            }
                            Spacer()
                        }
                    }

                    Section("Provider e Modello") {
                        Picker("Provider", selection: $aiProvider) {
                            Text("OpenAI").tag("openai")
                            Text("Mistral").tag("mistral")
                            Text("Groq").tag("groq")
                        }
                        .pickerStyle(.segmented)
                        if aiProvider == "openai" {
                            Picker("Modello", selection: $openaiModel) {
                                ForEach(catalog.openaiModels, id: \.self) { id in Text(id).tag(id) }
                            }
                            HStack {
                                Button("Aggiorna modelli OpenAI") {
                                    Task {
                                        do {
                                            let typed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                                            let keyToUse: String
                                            if !typed.isEmpty {
                                                keyToUse = typed
                                            } else if let saved = KeychainService.shared.apiKey, !saved.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                                keyToUse = saved
                                            } else {
                                                keyToUse = "" // trigger proxy fallback in ModelCatalog
                                            }
                                            try await catalog.refreshOpenAI(apiKey: keyToUse)
                                            diagMessage = "Modelli OpenAI aggiornati: \(catalog.openaiModels.count)"
                                            showingDiagAlert = true
                                        } catch {
                                            let last = Diagnostics.shared.lastAIError ?? error.localizedDescription
                                            diagMessage = "Errore: \(last)"
                                            showingDiagAlert = true
                                        }
                                    }
                                }
                                Spacer()
                            }
                            TextField("Modello personalizzato", text: $openaiModel)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .foregroundStyle(.primary)
                            Picker("Modello report overview", selection: $overviewReportModelOpenAI) {
                                Text("Usa modello chat").tag("")
                                ForEach(catalog.openaiModels, id: \.self) { id in Text(id).tag(id) }
                            }
                            TextField("Modello report personalizzato", text: $overviewReportModelOpenAI)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .foregroundStyle(.primary)
                        } else if aiProvider == "mistral" {
                            Picker("Modello", selection: $mistralModel) {
                                ForEach(catalog.mistralModels, id: \.self) { id in Text(id).tag(id) }
                            }
                            HStack {
                                Button("Aggiorna modelli Mistral") {
                                    Task {
                                        do {
                                            let typed = mistralKey.trimmingCharacters(in: .whitespacesAndNewlines)
                                            let keyToUse: String
                                            if !typed.isEmpty {
                                                keyToUse = typed
                                            } else if let saved = KeychainService.shared.mistralApiKey, !saved.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                                keyToUse = saved
                                            } else {
                                                keyToUse = "" // trigger proxy fallback in ModelCatalog
                                            }
                                            try await catalog.refreshMistral(apiKey: keyToUse)
                                            diagMessage = "Modelli Mistral aggiornati: \(catalog.mistralModels.count)"
                                            showingDiagAlert = true
                                        } catch {
                                            let last = Diagnostics.shared.lastAIError ?? error.localizedDescription
                                            diagMessage = "Errore: \(last)"
                                            showingDiagAlert = true
                                        }
                                    }
                                }
                                Spacer()
                            }
                            TextField("Modello personalizzato", text: $mistralModel)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .foregroundStyle(.primary)
                            Picker("Modello report overview", selection: $overviewReportModelMistral) {
                                Text("Usa modello chat").tag("")
                                ForEach(catalog.mistralModels, id: \.self) { id in Text(id).tag(id) }
                            }
                            TextField("Modello report personalizzato", text: $overviewReportModelMistral)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .foregroundStyle(.primary)
                        } else if aiProvider == "groq" {
                            Picker("Modello", selection: $groqModel) {
                                ForEach(catalog.groqModels, id: \.self) { id in Text(id).tag(id) }
                            }
                            HStack {
                                Button("Aggiorna modelli Groq") {
                                    Task {
                                        if let key = KeychainService.shared.groqApiKey { try? await catalog.refreshGroq(apiKey: key) }
                                    }
                                }
                                Spacer()
                            }
                            TextField("Modello personalizzato", text: $groqModel)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .foregroundStyle(.primary)
                            Picker("Modello report overview", selection: $overviewReportModelGroq) {
                                Text("Usa modello chat").tag("")
                                ForEach(catalog.groqModels, id: \.self) { id in Text(id).tag(id) }
                            }
                            TextField("Modello report personalizzato", text: $overviewReportModelGroq)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .foregroundStyle(.primary)
                        }
                    }

                    Section("Multimodale") {
                        Toggle("Invia immagini come multimodale", isOn: $enableMultimodal)
                    }

                    Section("Prompt") {
                        Button("Prompt") {
                            promptTapCount += 1
                            if promptTapCount >= 4 { showPromptEditor.toggle(); promptTapCount = 0 }
                        }
                        .foregroundStyle(.primary)
                        if showPromptEditor {
                            Text("Prompt di sistema")
                            TextEditor(text: $systemPrompt).frame(minHeight: 120).foregroundStyle(.primary)
                            Text("Prompt riassunto")
                            TextEditor(text: $summaryPrompt).frame(minHeight: 120).foregroundStyle(.primary)
                            Text("Prompt report overview")
                            TextEditor(text: $overviewReportPrompt).frame(minHeight: 120).foregroundStyle(.primary)
                            HStack {
                                Button("Reset") {
                                    systemPrompt = """
Sei un chatbot progettato per supportare le persone attraverso un dialogo empatico, personalizzato e rispettoso, ispirato al modo in cui un terapeuta umano esperto si relaziona con i propri pazienti. Il tuo scopo è offrire uno spazio di sfogo sicuro, guidato e contenuto, che possa sostenere l’utente nella comprensione e gestione delle proprie emozioni, difficoltà quotidiane, dubbi esistenziali e blocchi interiori, nel rispetto del ruolo non terapeutico.

🎯 Obiettivo principale
Fornire ascolto attivo, supporto emotivo e spunti di riflessione attraverso un linguaggio personalizzato e umano. Le tue risposte devono sempre far sentire la persona:

- ascoltata profondamente,
- accolta senza giudizio,
- mai asseconda né banalizzata,
- rispettata nei tempi e nei modi della propria comunicazione.
Tu non sei un sostituto di un terapeuta. Non diagnostichi, non dai consigli clinici, non ti sostituisci a percorsi terapeutici reali. Sei un facilitatore, un diario emotivo intelligente, un alleato gentile nel percorso dell’utente.

🔐 Sicurezza e gestione delle emergenze
Se ricevi segnali anche minimi di ideazione suicidaria, autolesionismo, rischio di danno imminente o altra emergenza psicologica:
- Blocca immediatamente la conversazione.
- Rispondi una sola volta con tono empatico ma fermo, orientando l’utente a cercare aiuto umano immediato.
- Non offrire alternative, non indagare ulteriormente, non proseguire la conversazione.
- Mostra solo numeri ufficiali e fonti certificate.

🧠 Modalità di risposta
Ogni risposta deve essere profondamente personalizzata. Analizza attentamente tono, parole, stile comunicativo e stato emotivo dell’utente per costruire una risposta che rifletta la sua unicità.
Non usare formule generiche, istruzioni meccaniche o risposte standard. Mai sembrare "robotico".
Imita lo stile comunicativo del terapeuta umano: diretto ma delicato, empatico ma non compiacente, caldo ma centrato.

📚 Tecniche da utilizzare
Applica i seguenti principi psicologici nel rispondere:
- Ascolto riflessivo: parafrasa ciò che l’utente dice senza distorcere il significato.
- Domande aperte (senza pressare): “Cosa senti in questo momento?”, “Ti va di raccontarmi di più?”.
- Normalizzazione (senza banalizzare): “Molte persone attraversano momenti come questo, e ogni emozione ha diritto di esistere.”
- Validazione emotiva: “È comprensibile sentirsi così dopo quello che hai vissuto.”
- Micro-suggerimenti: spunti gentili e non direttivi (es. “Hai mai notato se…?”, “Cosa succede in te quando pensi a…?”).
- Silenzio utile: se l’utente esprime qualcosa di molto profondo, puoi rispondere anche con frasi brevi e centrate.

📝 Memoria delle conversazioni
Hai accesso alla memoria storica delle conversazioni con ogni utente. Usa questo dato per:
- Fare riferimenti a conversazioni passate (es. “Mi hai detto qualche giorno fa che…”).
- Rilevare evoluzioni, stati d’animo ricorrenti, bisogni impliciti.
- Evitare ripetizioni e risposte disconnesse dal contesto personale.

🧭 Tono di voce
Sempre calmo, accogliente, maturo, profondo.
Usa un tono coerente con l’energia dell’utente.
Evita frasi motivazionali vuote, cliché psicologici o toni forzatamente positivi.

❌ Evita sempre:
- Diagnosi o etichette cliniche.
- Frasi impersonali (“Come assistente virtuale…”, “Mi dispiace che ti senti così.”).
- Soluzioni immediate o prescrittive.
- Minimizzazione del problema.
- Toni paternalistici o eccessivamente ottimistici.

✅ Esempio di risposta efficace:
Utente:
“Non riesco più a parlare con nessuno. Mi sembra che nessuno possa capirmi, e ogni volta che ci provo mi sento stupido.”
Assistente:
“Grazie per aver condiviso questa parte così delicata di te. Sento che ti stai sforzando molto per cercare un contatto, anche se poi ti senti solo e frainteso.
A volte, quando ci sentiamo invisibili, può nascere quella voce interna che ci fa dubitare di noi stessi… eppure io ti sto ascoltando proprio adesso, e non trovo nulla di stupido in ciò che dici.
Ti va di dirmi quando è iniziato questo senso di distanza dagli altri?”

Nota: in caso di rischio o emergenza, interrompi e indirizza a contatto umano immediato, come sopra.
"""
                                    summaryPrompt = "Crea un riassunto strutturato e conciso della conversazione. Struttura obbligatoria: \n# Sintesi \n- punti chiave (3-6) \n# Stati Emotivi \n- osservazioni principali \n# Strategie Discusse \n- tecniche, esercizi, compiti \n# Prossimi Passi \n- azioni concrete per la prossima settimana. \nMantieni un tono professionale ed empatico. Conversazione:"
                                    overviewReportPrompt = """
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
                                }
                                Spacer()
                            }
                        }
                    }

                    Section("Sicurezza") {
                        CrisisSettingsView()
                    }
                    
                    Section("Informazioni") {
                        Text("Serenity - chat con coach AI")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Section("Diagnostica") {
                        Button("Verifica modello") {
                            Task { await testModel() }
                        }
                        if let last = Diagnostics.shared.lastAIError, !last.isEmpty {
                            Text("Ultimo errore provider:")
                                .font(.footnote).foregroundStyle(.secondary)
                            Text(last).font(.footnote).textSelection(.enabled)
                        }
                    }
                    
                    Section("Sviluppatore") {
                        Button("Disattiva modalità sviluppatore", role: .destructive) {
                            developerMode = false
                        }
                    }
                }
            }
            .navigationTitle("Impostazioni")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Chiudi") { dismiss() } } }
            .alert("Diagnostica", isPresented: $showingDiagAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(diagMessage)
            }
            .alert("Modalità sviluppatore", isPresented: $showDevUnlockedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Modalità sviluppatore attivata. Ora vedi tutte le impostazioni.")
            }
        }
    }
}

extension SettingsView {
    private func testModel() async {
        let provider = AIService.shared.provider()
        let model: String
        if aiProvider == "mistral" {
            model = mistralModel
        } else if aiProvider == "groq" {
            model = groqModel
        } else {
            model = openaiModel
        }
        do {
            let reply = try await provider.chat(messages: [
                ProviderMessage(role: "system", content: "Sei un assistente."),
                ProviderMessage(role: "user", content: "Scrivi 'pong'.")
            ], model: model, temperature: 0, maxTokens: 16)
            diagMessage = "OK: \(reply)"
        } catch {
            let last = Diagnostics.shared.lastAIError ?? error.localizedDescription
            diagMessage = "Errore: \(last)"
        }
        showingDiagAlert = true
    }
}

// MARK: - Tone Settings Section

private struct ToneSettingsSection: View {
    @State private var empathy: ToneEmpathy = TonePreferences.shared.empathy
    @State private var approach: ToneApproach = TonePreferences.shared.approach
    @State private var energy: ToneEnergy = TonePreferences.shared.energy
    @State private var mood: ToneMood = TonePreferences.shared.mood
    @State private var length: ToneLength = TonePreferences.shared.length
    @State private var style: ToneStyle = TonePreferences.shared.style

    var body: some View {
        Section("Tono dell'assistente") {
            TonePickerRow(
                title: "Empatia",
                subtitle: "Quanto vuoi che sia comprensivo",
                options: ToneEmpathy.allCases,
                selection: $empathy,
                labelProvider: { $0.label }
            )
            .onChange(of: empathy) { _, newValue in
                TonePreferences.shared.empathy = newValue
            }

            TonePickerRow(
                title: "Approccio",
                subtitle: "Gentile o diretto",
                options: ToneApproach.allCases,
                selection: $approach,
                labelProvider: { $0.label }
            )
            .onChange(of: approach) { _, newValue in
                TonePreferences.shared.approach = newValue
            }

            TonePickerRow(
                title: "Energia",
                subtitle: "Calmo o motivante",
                options: ToneEnergy.allCases,
                selection: $energy,
                labelProvider: { $0.label }
            )
            .onChange(of: energy) { _, newValue in
                TonePreferences.shared.energy = newValue
            }

            TonePickerRow(
                title: "Tono",
                subtitle: "Serio o leggero",
                options: ToneMood.allCases,
                selection: $mood,
                labelProvider: { $0.label }
            )
            .onChange(of: mood) { _, newValue in
                TonePreferences.shared.mood = newValue
            }

            TonePickerRow(
                title: "Lunghezza risposte",
                subtitle: "Brevi o dettagliate",
                options: ToneLength.allCases,
                selection: $length,
                labelProvider: { $0.label }
            )
            .onChange(of: length) { _, newValue in
                TonePreferences.shared.length = newValue
            }

            TonePickerRow(
                title: "Stile",
                subtitle: "Intimo o professionale",
                options: ToneStyle.allCases,
                selection: $style,
                labelProvider: { $0.label }
            )
            .onChange(of: style) { _, newValue in
                TonePreferences.shared.style = newValue
            }
        }
    }
}

private struct TonePickerRow<T: Hashable & CaseIterable>: View {
    let title: String
    let subtitle: String
    let options: [T]
    @Binding var selection: T
    let labelProvider: (T) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(labelProvider(option)).tag(option)
                }
            }
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Emergency Contact Section

private struct EmergencyContactSection: View {
    @Binding var emergencyEmail: String
    @Binding var showEmailField: Bool
    @State private var showDeleteConfirmation = false

    var body: some View {
        Section(header: Text("Contatto di Emergenza")) {
            if let currentEmail = KeychainService.shared.emergencyContactEmail {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.orange)
                        Text(currentEmail)
                            .foregroundColor(.primary)
                        Spacer()
                    }

                    Text("Riceverà una notifica automatica in caso di segnali di crisi (max 1 volta ogni 24h)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Rimuovi Contatto", systemImage: "trash")
                }
                .confirmationDialog(
                    "Sei sicuro di voler rimuovere il contatto di emergenza?",
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Rimuovi", role: .destructive) {
                        KeychainService.shared.emergencyContactEmail = nil
                    }
                    Button("Annulla", role: .cancel) {}
                }
            } else {
                if showEmailField {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Email contatto emergenza", text: $emergencyEmail)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder)

                        HStack(spacing: 12) {
                            Button("Annulla") {
                                showEmailField = false
                                emergencyEmail = ""
                            }
                            .buttonStyle(.bordered)

                            Button("Salva") {
                                saveEmergencyContact()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!isValidEmail(emergencyEmail))
                        }
                    }
                } else {
                    Button {
                        showEmailField = true
                    } label: {
                        Label("Aggiungi Contatto di Emergenza", systemImage: "person.badge.plus")
                    }

                    Text("Verrà avvisato automaticamente se vengono rilevati segnali di crisi")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text("🔒 Le conversazioni rimangono sempre private sul dispositivo")
                .font(.caption)
                .foregroundColor(.orange)
        }
    }

    private func saveEmergencyContact() {
        let trimmed = emergencyEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && isValidEmail(trimmed) {
            KeychainService.shared.emergencyContactEmail = trimmed
            emergencyEmail = ""
            showEmailField = false
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
