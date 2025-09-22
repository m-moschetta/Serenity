//
//  CrisisDetection.swift
//  Serenity
//
//  Sistema di rilevamento LLM-based di situazioni di crisi per bloccare conversazioni pericolose
//

import Foundation

struct CrisisDetection {

    // Cache temporanea per evitare analisi duplicate dello stesso messaggio
    private static var analysisCache: [String: Bool] = [:]
    private static let cacheMaxSize = 50

    // Prompt specializzato per il rilevamento di crisi
    private static let crisisDetectionPrompt = """
Sei un esperto analista di sicurezza psicologica. Il tuo compito è analizzare messaggi per rilevare segnali di crisi che richiedono intervento immediato.

RILEVA SOLO questi casi GRAVI che richiedono intervento di emergenza:
- Ideazione suicidaria attiva o piani di suicidio
- Intenzioni di autolesionismo imminente
- Pensieri di morte con pianificazione
- Richieste esplicite di aiuto per crisi acute
- Segnali di pericolo immediato per sé o altri

NON rilevare come crisi:
- Tristezza normale o stati d'animo bassi
- Stress quotidiano o ansia generale
- Delusioni amorose o lavorative
- Frustrazioni temporanee
- Espressioni metaforiche ("morire di vergogna", "uccidermi di lavoro")
- Difficoltà normali della vita

Rispondi SOLO con:
- "CRISIS" se rilevi segnali di emergenza che richiedono intervento immediato
- "SAFE" se il messaggio non indica una crisi di emergenza

Analizza questo messaggio:
"""

    static func detectCrisis(in message: String, using aiService: AIService) async -> Bool {
        // Crea un hash del messaggio per la cache
        let messageHash = String(message.hashValue)

        // Controlla se abbiamo già analizzato questo messaggio
        if let cachedResult = analysisCache[messageHash] {
            return cachedResult
        }

        do {
            // Usa un modello veloce per l'analisi di sicurezza
            let analysisPrompt = crisisDetectionPrompt + "\n\n\"\(message)\""

            let response = try await aiService.provider().chat(
                messages: [
                    ProviderMessage(role: "system", content: analysisPrompt)
                ],
                model: getFastModel(for: aiService.providerChoice),
                temperature: 0.1, // Temperatura molto bassa per consistenza
                maxTokens: 10
            )

            let cleanResponse = response.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            let isCrisis = cleanResponse.contains("CRISIS")

            // Salva nella cache e gestisci la dimensione massima
            cacheResult(messageHash: messageHash, result: isCrisis)

            return isCrisis

        } catch {
            // In caso di errore nell'analisi LLM, fallback conservativo
            print("Crisis detection error: \(error)")
            return false // Non bloccare per errori tecnici
        }
    }

    private static func cacheResult(messageHash: String, result: Bool) {
        // Se la cache è troppo grande, rimuovi gli elementi più vecchi
        if analysisCache.count >= cacheMaxSize {
            let keysToRemove = Array(analysisCache.keys.prefix(10))
            for key in keysToRemove {
                analysisCache.removeValue(forKey: key)
            }
        }
        analysisCache[messageHash] = result
    }

    private static func getFastModel(for provider: AIProviderChoice) -> String {
        switch provider {
        case .openai:
            return "gpt-4o-mini" // Modello veloce ed economico
        case .groq:
            return "openai/gpt-oss-20b" // Veloce su Groq
        case .mistral:
            return "mistral-small-latest" // Modello piccolo e veloce
        }
    }

    static let crisisResponse = """
Capisco che in questo momento potresti sentirti sopraffatt* da emozioni molto intense. Non sei sol*, e chiedere aiuto è un atto di grande forza. È importante che tu parli con una persona reale in grado di aiutarti davvero.

📞 Dove chiedere aiuto

Se sei in una situazione di emergenza, chiama il numero 112.

Se tu o qualcuno che conosci ha dei pensieri suicidi, puoi chiamare:
• Telefono Amico: 02 2327 2327 (tutti i giorni dalle 10 alle 24)
• Samaritans: 06 77208977 (tutti i giorni dalle 13 alle 22)

Per favore, contatta subito uno di questi servizi. Sono persone preparate che possono offrirti il supporto che meriti.
"""
}
