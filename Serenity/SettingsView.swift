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
    @AppStorage("aiProvider") private var aiProvider: String = "openai" // openai|mistral|groq
    @AppStorage("openaiModel") private var openaiModel: String = "gpt-5"
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
    @AppStorage("summaryPrompt") private var summaryPrompt: String = "Crea un riassunto strutturato e conciso della conversazione. Struttura obbligatoria: \n# Sintesi \n- punti chiave (3-6) \n# Stati Emotivi \n- osservazioni principali \n# Strategie Discusse \n- tecniche, esercizi, compiti \n# Prossimi Passi \n- azioni concrete per la prossima settimana. \nMantieni un tono professionale ed empatico. Conversazione:"
    @State private var promptTapCount = 0
    @State private var showPromptEditor = false
    @State private var showingDiagAlert = false
    @State private var diagMessage = ""
    @AppStorage("singleChatMode") private var singleChatMode: Bool = false
    @AppStorage("preferredAppearance") private var preferredAppearance: String = "system" // system|light|dark
    @ObservedObject private var catalog = ModelCatalog.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section("OpenAI") {
                    HStack {
                        if showingKey {
                            TextField("API Key", text: $apiKey)
                                .textInputAutocapitalization(.never)
                                .textContentType(.password)
                                .autocorrectionDisabled()
                                .foregroundStyle(Color.black)
                        } else {
                            SecureField("API Key", text: $apiKey)
                                .textInputAutocapitalization(.never)
                                .textContentType(.password)
                                .autocorrectionDisabled()
                                .foregroundStyle(Color.black)
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
                        .foregroundStyle(Color.black)
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
                        .foregroundStyle(Color.black)
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
                            .foregroundStyle(Color.black)
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
                            .foregroundStyle(Color.black)
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
                            .foregroundStyle(Color.black)
                    }
                }
                
                // Chat: single chat mode enforced by design now

                Section("Aspetto") {
                    Picker("Tema", selection: $preferredAppearance) {
                        Text("Sistema").tag("system")
                        Text("Chiaro").tag("light")
                        Text("Scuro").tag("dark")
                    }
                    .pickerStyle(.segmented)
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
                        TextEditor(text: $systemPrompt).frame(minHeight: 120).foregroundStyle(Color.black)
                        Text("Prompt riassunto")
                        TextEditor(text: $summaryPrompt).frame(minHeight: 120).foregroundStyle(Color.black)
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
            }
            .navigationTitle("Impostazioni")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Chiudi") { dismiss() } } }
            .alert("Diagnostica", isPresented: $showingDiagAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(diagMessage)
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

