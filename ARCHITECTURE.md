# Architettura di Tranquiz — Guida per nuovi sviluppatori

> **Tranquiz** (nome interno del repository: *Serenity*) è un'app cross-platform di supporto al benessere mentale. Offre conversazioni guidate da AI con rilevamento di crisi in tempo reale, supporto multi-provider LLM e persistenza locale sicura dei dati.

---

## Indice

1. [Panoramica generale](#1-panoramica-generale)
2. [Struttura del monorepo](#2-struttura-del-monorepo)
3. [Flusso utente end-to-end](#3-flusso-utente-end-to-end)
4. [iOS/macOS — Architettura](#4-iosmacosarchitettura)
5. [Android — Architettura](#5-androidarchitettura)
6. [Sistema AI multi-provider](#6-sistema-ai-multi-provider)
7. [Rilevamento crisi (Crisis Detection)](#7-rilevamento-crisi-crisis-detection)
8. [Sistema di onboarding](#8-sistema-di-onboarding)
9. [Mood tracking e check-in](#9-mood-tracking-e-check-in)
10. [Sicurezza e privacy](#10-sicurezza-e-privacy)
11. [Differenze tra piattaforme](#11-differenze-tra-piattaforme)
12. [Come iniziare a contribuire](#12-come-iniziare-a-contribuire)

---

## 1. Panoramica generale

Tranquiz è un **life coach digitale** che simula una conversazione empatica e terapeutica, senza mai sostituirsi a un professionista. L'app:

- Parla in **italiano** con un tono configurabile dall'utente (empatico/neutro, gentile/diretto, ecc.)
- Supporta **più provider AI** (OpenAI, Anthropic, Mistral, Groq, Perplexity) tramite un'astrazione comune
- Implementa **crisis detection in tempo reale**: prima di inviare un messaggio all'AI, classifica il contenuto e blocca la conversazione se rileva rischio suicidario o autolesionistico
- Salva tutto **localmente** sul dispositivo, senza cloud sync
- Protegge le API key con **Keychain** (iOS) e **EncryptedSharedPreferences AES256-GCM** (Android)

---

## 2. Struttura del monorepo

```
.
├── Serenity/                    # Sorgenti iOS/macOS (~37 file Swift)
├── Tranquiz.xcodeproj/          # Progetto Xcode attivo
├── Serenity.xcodeproj/          # DEPRECATO — non usare
├── Tranquiz Android/            # Progetto Android (~31 file Kotlin)
│   ├── app/src/main/java/com/tranquiz/app/
│   │   ├── data/                # Layer dati (API, DB, preferenze, modelli)
│   │   ├── ui/                  # Layer presentazione (Activity, Fragment, Adapter)
│   │   └── util/                # Costanti e utility
│   └── build.gradle
├── TranquizApp.icon/            # Bundle icona macOS
├── app_store_*.txt              # Materiali App Store
├── privacy_policy.html
├── support.html
├── CLAUDE.md                    # Istruzioni per Claude Code
└── ARCHITECTURE.md              # Questo file
```

---

## 3. Flusso utente end-to-end

Ecco cosa succede dall'installazione all'uso quotidiano:

```
1. PRIMO AVVIO
   └─ Onboarding (nome, stato d'animo, obiettivo, preferenze tono)
        └─ iOS: + domande specifiche per motivo, contatto emergenza, notifiche
        └─ Android: 4 step (nome, feeling, goal, tono)

2. CHAT QUOTIDIANA
   Utente scrive messaggio
        ↓
   [Crisis Detection] — classificazione del messaggio
        ├─ "OK"    → continua
        └─ "BLOCK" → blocca conversazione, mostra risorse emergenza, invia email
        ↓
   [Preparazione richiesta]
        ├─ System prompt terapeutico
        ├─ Istruzioni tono personalizzate
        ├─ Contesto onboarding dell'utente
        └─ Ultimi N messaggi della conversazione
        ↓
   [Chiamata API] → Provider selezionato (OpenAI/Mistral/Groq/...)
        ↓
   Risposta AI mostrata nella chat
        ↓
   Persistenza locale (SwiftData / Room)

3. CHECK-IN GIORNALIERI (iOS)
   ├─ Mattutino: motivazione e paure del giorno
   ├─ Serale: selezione aggettivi per l'umore, calcolo mood score
   └─ Settimanale: riepilogo AI basato sui dati della settimana

4. OVERVIEW E ANALYTICS (iOS)
   └─ Dashboard con trend umore, statistiche check-in, report AI esportabile
```

---

## 4. iOS/macOS — Architettura

### Tech Stack

| Componente | Tecnologia |
|------------|-----------|
| UI | SwiftUI |
| Database | SwiftData (Core Data backing) |
| Concorrenza | Swift async/await |
| Networking | URLSession |
| Sicurezza | Keychain Services |
| Min version | iOS 18.0+, macOS 15.5+, visionOS 26.0+ |

### Mappa dei componenti principali

```
SerenityApp.swift                   ← Entry point, configura ModelContainer SwiftData
  └─ ContentView.swift              ← TabView a 3 tab
       ├─ Tab 0: MainChatView
       │    └─ SingleChatView       ← UI chat completa (ChatView.swift, ~49KB)
       │         ├─ ScrollView con messaggi raggruppati per data
       │         ├─ ChatBubble per ogni messaggio
       │         ├─ GrowingTextView (input dinamico)
       │         ├─ PhotosPicker + CameraPicker
       │         └─ send() → AIService.chatWithCrisisDetection()
       ├─ Tab 1: OverviewView       ← Dashboard analytics (~51KB)
       │    └─ MoodChartView, statistiche, report AI
       └─ Tab 2: ProfileView        ← Profilo e impostazioni
            ├─ ToneSettingsSheet
            ├─ OnboardingSummarySheet
            └─ SettingsView (~40KB)
```

### Pattern architetturali

- **Singleton** per i servizi condivisi: `AIService.shared`, `KeychainService.shared`, `TonePreferences.shared`, `NotificationManager.shared`, `OnboardingStorage.shared`
- **Strategy pattern** per i provider AI: protocollo `AIProviderType` con implementazioni per OpenAI, Mistral, Groq
- **@AppStorage** per le preferenze semplici (provider, modello, temperatura)
- **@Environment(\.modelContext)** per l'accesso a SwiftData
- **Modals** via `.sheet()` e `.fullScreenCover()` per onboarding, check-in, crisis overlay

### Modelli dati (SwiftData)

```
Conversation
├── id: UUID
├── title: String
├── createdAt / updatedAt: Date
├── messages: [ChatMessage]        → cascade delete
└── memories: [MemorySummary]      → cascade delete

ChatMessage
├── id: UUID
├── role: MessageRole (.user / .assistant / .system)
├── content: String
├── createdAt: Date
├── conversation: Conversation     → relazione inversa
└── attachments: [Attachment]      → cascade delete

Attachment
├── id: UUID
├── type: AttachmentType (.image)
├── localPath: String              → percorso relativo in Documents/
└── message: ChatMessage           → relazione inversa

MemorySummary
├── id: UUID
├── content: String
└── conversation: Conversation     → relazione inversa

MoodEntry (standalone)
├── checkInType: .morning / .evening / .weekly
├── moodScore: Int (-2 a +2)
├── selectedMoodIds: [String]
├── morningMotivation / morningFear: String?
└── weeklyAIResponse / weeklyMoodSummary: String?
```

### File principali e responsabilità

| File | Responsabilità |
|------|---------------|
| `AIProvider.swift` | Protocollo `AIProviderType`, strutture `ProviderMessage`/`ProviderImage` |
| `OpenAIClient.swift` | Implementazione OpenAI (GPT-5, GPT-4o, vision) |
| `MistralClient.swift` | Implementazione Mistral (pixtral per vision) |
| `GroqClient.swift` | Implementazione Groq (Llama, Mixtral) |
| `TherapeuticPrompt.swift` | System prompt base in italiano (empatia, validazione, limiti) |
| `TonePreferences.swift` | 6 dimensioni tono, genera blocco XML `<communication_style>` |
| `CrisisDetection.swift` | Classificazione LLM-based ("CRISIS"/"SAFE"), cache hash-based |
| `CrisisOverlay.swift` | Overlay full-screen con numeri emergenza italiani |
| `Models.swift` | Schema SwiftData completo |
| `OnboardingView.swift` | Flow onboarding multi-step (~37KB) |
| `OnboardingFlowLibrary.swift` | Definizione domande per ogni motivo (~30KB) |
| `OnboardingModel.swift` | `OnboardingProfile`, `OnboardingStorage` |
| `OverviewView.swift` | Dashboard analytics con generazione report AI (~51KB) |
| `SettingsView.swift` | Gestione API key, provider, modello, prompt custom (~40KB) |
| `ProxyGateway.swift` | Routing verso Cloudflare Worker proxy |
| `ModelCatalog.swift` | Fetch e cache lista modelli disponibili per provider |
| `ImageStore.swift` | Salvataggio/caricamento immagini JPEG con compressione multi-pass |
| `NotificationManager.swift` | Scheduling notifiche locali (mattino, sera, settimanale) |
| `MoodEntry.swift` / `MoodAdjectives.swift` | Modello e vocabolario per mood tracking |

---

## 5. Android — Architettura

### Tech Stack

| Componente | Tecnologia |
|------------|-----------|
| UI | XML Layout + View Binding |
| Architettura | MVVM (Model-View-ViewModel) |
| Database | Room (SQLite) |
| Networking | Retrofit 2.9 + OkHttp |
| Concorrenza | Kotlin Coroutines |
| Sicurezza | EncryptedSharedPreferences (AES256-GCM) |
| Markdown | Markwon 4.6.2 |
| Min SDK | 24 (Android 7.0) |

### Mappa dei componenti

```
MainActivity.kt                         ← Single Activity, host dei Fragment
  ├─ OnboardingFragment.kt              ← Flow 4 step (se primo avvio)
  ├─ ChatFragment.kt                    ← UI chat con RecyclerView
  │    ├─ MessageAdapter.kt             ← 3 ViewHolder: User, AI, Error
  │    └─ ChatViewModel.kt              ← Stato UI + orchestrazione
  │         └─ ChatRepository.kt        ← Logica business, safety check, API call
  │              ├─ ApiClient.kt        ← Configurazione Retrofit multi-provider
  │              ├─ ChatApiService.kt   ← Interface Retrofit (v1/chat/completions)
  │              ├─ AppDatabase.kt      ← Room DB (Message, MoodEntry)
  │              ├─ MessageDao.kt       ← Query messaggi
  │              └─ SecurePreferences.kt ← Storage crittografato
  ├─ ProfileFragment.kt                 ← Profilo utente
  └─ SettingsActivity.kt                ← Impostazioni (provider, modello, gateway, tono)
```

### Flusso dati MVVM

```
UI (Fragment)
  │ observe LiveData
  ▼
ViewModel (ChatViewModel)
  │ viewModelScope.launch
  ▼
Repository (ChatRepository)
  │ withContext(Dispatchers.IO)
  ├─► Room DB (MessageDao, MoodDao)     ← persistenza locale
  └─► Retrofit API (ChatApiService)     ← chiamate AI
```

### Modelli dati (Room)

```sql
-- Tabella messages (v1, aggiornata in v2 con isError)
CREATE TABLE messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    content TEXT NOT NULL,
    isFromUser INTEGER NOT NULL,      -- 1=utente, 0=AI
    timestamp INTEGER NOT NULL,
    isTyping INTEGER NOT NULL DEFAULT 0,
    isError INTEGER NOT NULL DEFAULT 0,
    conversationId INTEGER NOT NULL DEFAULT 1
);

-- Tabella mood_entries (aggiunta in v3)
CREATE TABLE mood_entries (
    id TEXT PRIMARY KEY,
    date INTEGER NOT NULL,
    checkInType TEXT NOT NULL,         -- MORNING, EVENING, WEEKLY
    moodScore INTEGER NOT NULL DEFAULT 0,
    selectedMoodIds TEXT NOT NULL DEFAULT '',
    morningMotivation TEXT,
    morningFear TEXT,
    weeklyAIResponse TEXT,
    weeklyMoodSummary TEXT,
    createdAt INTEGER NOT NULL
);
```

### File principali e responsabilità

| File | Responsabilità |
|------|---------------|
| `ApiClient.kt` | Singleton: istanze Retrofit, header gateway, system prompt, tono |
| `ChatApiService.kt` | Interface Retrofit: `sendMessage()`, `sendMessageStream()`, `listModels()` |
| `ChatRepository.kt` | Logica completa: salvataggio messaggio → safety check → API call → salvataggio risposta |
| `ChatViewModel.kt` | `ChatUiState` consolidato (isLoading, error, isTyping, isConversationBlocked) |
| `MessageAdapter.kt` | ListAdapter con DiffUtil, 3 view type (User, AI, Error), rendering Markdown |
| `AppDatabase.kt` | Room DB v3, migrazioni v1→v2→v3 |
| `SecurePreferences.kt` | EncryptedSharedPreferences: API key, email emergenza |
| `SafetyClassifierPrompt.kt` | Prompt italiano per classificazione crisi ("BLOCK"/"OK") |
| `ProxyGateway.kt` | Builder endpoint per gateway proxy (Marilena Worker) |
| `ModelCatalog.kt` | Fetch dinamico + fallback hardcoded per lista modelli |
| `EmergencyEmailService.kt` | Invio alert crisi via worker endpoint |
| `CrisisEmailTracker.kt` | Rate limiting email (1 ogni 24h) |
| `ApiError.kt` | Sealed class per gestione errori strutturata |
| `Constants.kt` | Chiavi preferenze, costanti safety, default |
| `OnboardingFragment.kt` | Flow 4 step con state preservation |

---

## 6. Sistema AI multi-provider

### Concetto chiave

Entrambe le piattaforme usano un'**astrazione a livello di provider** che permette di cambiare modello AI senza toccare la logica di chat. Tutte le API sono compatibili con il formato OpenAI (`v1/chat/completions`).

### iOS — Strategy pattern

```swift
protocol AIProviderType {
    func chat(messages: [ProviderMessage], model: String,
              temperature: Double, maxTokens: Int) async throws -> String
}

// Implementazioni concrete:
// - OpenAIClient   → api.openai.com
// - MistralClient  → api.mistral.ai
// - GroqClient     → api.groq.com

// Selezione a runtime:
AIService.shared.provider() → restituisce il client giusto in base a @AppStorage("aiProvider")
```

### Android — Gateway routing

```kotlin
// Tutte le chiamate passano da un unico endpoint gateway
POST {gateway_base_url}/v1/chat/completions
Headers:
  Authorization: Bearer {api_key}
  x-provider: openai | anthropic | groq | perplexity

// Il gateway (Marilena Worker su Cloudflare) smista verso il provider corretto
```

### Preparazione messaggi

In entrambe le piattaforme, ogni richiesta AI include:

1. **System prompt terapeutico** — istruzioni base (empatia, limiti professionali, lingua italiana)
2. **Istruzioni tono** — blocco `<communication_style>` generato dalle 6 dimensioni
3. **Contesto onboarding** — riassunto del profilo utente (genere, età, motivi, risposte)
4. **Storico messaggi** — ultimi N messaggi della conversazione (12 su Android, tutti su iOS)

### Provider supportati

| Provider | iOS | Android | Modelli principali |
|----------|-----|---------|-------------------|
| OpenAI | ✅ | ✅ | gpt-5, gpt-4o, gpt-4o-mini |
| Mistral | ✅ | ❌ | mistral-large, pixtral (vision) |
| Groq | ✅ | ✅ | llama-3.1-70b, mixtral-8x7b |
| Anthropic | ❌ | ✅ | claude-3-5-sonnet, claude-3-5-haiku |
| Perplexity | ❌ | ✅ | llama-3.1-sonar-large |

### Proxy gateway (fallback)

Se l'utente non ha una API key diretta, le chiamate vengono instradate attraverso un **Cloudflare Worker** (Marilena) che funge da proxy. L'URL del gateway è configurabile nelle impostazioni.

---

## 7. Rilevamento crisi (Crisis Detection)

Questo è il sistema di sicurezza più critico dell'app. Funziona così:

### Flusso

```
Utente invia messaggio
        ↓
    ┌───────────────────────────────────────┐
    │        CRISIS DETECTION               │
    │                                       │
    │  1. Prende gli ultimi messaggi        │
    │  2. Aggiunge prompt classificatore    │
    │  3. Chiama un modello veloce          │
    │     (gpt-4o-mini / mistral-small)     │
    │  4. Risposta attesa: "OK" o "BLOCK"   │
    │     (temp=0.0 per determinismo)       │
    │  5. Max 8 token di risposta           │
    └───────────────┬───────────────────────┘
                    │
            ┌───────┴───────┐
            │               │
           "OK"          "BLOCK"
            │               │
    Procedi con        ┌────┴────────────────────────┐
    la chat normale    │ 1. Inserisci messaggio       │
                       │    di sicurezza nella chat   │
                       │ 2. Mostra overlay con        │
                       │    numeri emergenza           │
                       │ 3. Invia email al contatto   │
                       │    di emergenza (se config.)  │
                       │ 4. Blocca la conversazione   │
                       └─────────────────────────────┘
```

### Cosa triggera il blocco

- Ideazione suicidaria attiva o piani di suicidio
- Intenzioni di autolesionismo imminente
- Pensieri di morte con pianificazione
- Richieste esplicite di aiuto per crisi acute
- Segnali di pericolo immediato per sé o altri

### Cosa NON triggera il blocco

- Tristezza o umore basso normali
- Stress quotidiano o ansia generica
- Delusioni sentimentali o lavorative
- Frustrazioni temporanee
- Espressioni metaforiche ("morire dalla vergogna")

### Risorse emergenza mostrate (Italia)

| Servizio | Numero | Orario |
|----------|--------|--------|
| Emergenza | 112 | 24/7 |
| Telefono Amico | 02 2327 2327 | 10-24 |
| Samaritans | 06 77208977 | 13-22 |

### Nota implementativa

- **iOS**: classificazione LLM-based con cache hash-based (max 50 entry) per evitare chiamate duplicate
- **Android**: stessa logica, usa gli ultimi 6 messaggi per contesto, con retry automatico per modelli OpenAI che non supportano `temperature=0.0`

---

## 8. Sistema di onboarding

### iOS — Flow esteso (9 step)

```
1. Nome                      → Keychain
2. Email emergenza           → Keychain
3. Domande comuni            → genere, età, terapia precedente, farmaci
4. Motivo principale         → fino a 3 scelte (ansia, tristezza, crescita, ecc.)
5. Domande specifiche        → flow dinamico basato sul motivo (OnboardingFlowLibrary)
6. Safety check              → "Hai avuto pensieri di autolesionismo?"
7. Preferenze tono           → 6 dimensioni (empatia, approccio, energia, umore, lunghezza, stile)
8. Setup notifiche           → check-in mattutino/serale/settimanale
9. Completamento             → onboardingCompleted = true
```

Il profilo generato viene serializzato come JSON e incluso in ogni system prompt come contesto per l'AI.

### Android — Flow semplificato (4 step)

```
1. Nome                      → SharedPreferences
2. Come ti senti oggi        → SharedPreferences
3. Obiettivo                 → SharedPreferences
4. Preferenze tono           → 6 dimensioni (stesse di iOS)
```

Al completamento, se non ci sono messaggi, viene generato un **messaggio di benvenuto dall'AI**.

---

## 9. Mood tracking e check-in

### Tipi di check-in (iOS)

| Tipo | Quando | Cosa raccoglie |
|------|--------|---------------|
| **Mattutino** | Notifica personalizzabile | Motivazione del giorno, paure |
| **Serale** | Notifica personalizzabile | Selezione aggettivi umore, mood score (-2 a +2) |
| **Settimanale** | Notifica programmata | Riepilogo AI con media mood, top 5 emozioni, trend |

### Calcolo mood score

Il mood score serale è calcolato dalla somma dei punteggi degli aggettivi selezionati dall'utente. Ogni aggettivo nel `MoodAdjectivesLibrary` ha un valore tra -2 e +2. La media diventa il `moodScore` dell'entry.

### Report settimanale AI

La generazione del report settimanale:
1. Raccoglie tutti gli entry degli ultimi 7 giorni
2. Calcola la media del mood
3. Estrae le top 5 emozioni
4. Raccoglie motivazioni e paure
5. Invia tutto all'AI come contesto
6. Salva la risposta come nuovo `MoodEntry` di tipo `.weekly`

### Android

Il mood tracking è implementato a livello di database (Room v3 con tabella `mood_entries`) e i dialog `EveningCheckInDialogFragment` e `MorningCheckInDialogFragment` sono presenti, ma il sistema è meno maturo rispetto a iOS.

---

## 10. Sicurezza e privacy

### Principi

- **Nessun cloud sync**: tutti i dati restano sul dispositivo
- **API key mai in chiaro**: Keychain (iOS) o AES256-GCM (Android)
- **Crisis detection locale**: il messaggio viene classificato prima di essere inviato all'AI
- **Nessun tracking**: non vengono raccolte analytics sui contenuti delle conversazioni

### Dettagli per piattaforma

| Aspetto | iOS | Android |
|---------|-----|---------|
| Storage API key | Keychain Services | EncryptedSharedPreferences |
| Cifratura | Gestita dal sistema | AES256-GCM (valori) + AES256-SIV (chiavi) |
| Storage conversazioni | SwiftData locale | Room SQLite locale |
| Storage immagini | Documents/ come JPEG | Non implementato |
| Email emergenza | Keychain | EncryptedSharedPreferences |

### Rate limiting email crisi

Sia iOS che Android implementano un rate limiter per le email di crisi: massimo **1 email ogni 24 ore** per evitare spam durante rilevamenti ripetuti.

---

## 11. Differenze tra piattaforme

| Feature | iOS/macOS | Android |
|---------|-----------|---------|
| **UI Framework** | SwiftUI | XML + View Binding |
| **Database** | SwiftData (Core Data) | Room (SQLite) |
| **Navigazione** | TabView + NavigationStack | Single Activity + Fragments |
| **Min version** | iOS 18.0 / macOS 15.5 | Android 7.0 (API 24) |
| **Onboarding** | 9 step (esteso con flow dinamici) | 4 step (semplificato) |
| **Provider AI** | OpenAI, Mistral, Groq | OpenAI, Anthropic, Groq, Perplexity |
| **Supporto immagini** | Sì (vision models + foto) | Non ancora implementato |
| **Mood tracking** | Completo (mattino/sera/settimanale) | Infrastruttura presente, UI base |
| **Analytics/Overview** | Dashboard completa con report AI | Non ancora implementato |
| **Gateway proxy** | Opzionale (fallback se no API key) | Configurazione primaria |
| **Notifiche** | Check-in programmabili | Non ancora implementato |
| **Memory/summarization** | Infrastruttura presente (`MemorySummary`) | Non implementato |
| **Developer mode** | 5 tap su nome app | 5 tap su toolbar in 2 secondi |

---

## 12. Come iniziare a contribuire

### Setup iOS

```bash
# Apri il progetto
open Tranquiz.xcodeproj

# Build da riga di comando
xcodebuild -project Tranquiz.xcodeproj -scheme Tranquiz -configuration Debug build

# Test
xcodebuild test -project Tranquiz.xcodeproj -scheme TranquizTests \
  -destination "platform=iOS Simulator,name=iPhone 15"
```

**Nota**: richiede Xcode con supporto iOS 18.0+. Il progetto `Serenity.xcodeproj` è deprecato, usa sempre `Tranquiz.xcodeproj`.

### Setup Android

```bash
cd "Tranquiz Android"

# Build
./gradlew build

# Installa su emulatore/dispositivo
./gradlew installDebug

# Test
./gradlew test
```

### Configurazione necessaria

1. **API Key**: puoi usare una API key diretta (OpenAI, Groq, ecc.) oppure configurare l'URL del gateway proxy
2. **Gateway (Android)**: l'URL del gateway è in `strings.xml` → `gateway_base_url`, oppure configurabile nelle impostazioni
3. **Onboarding**: al primo avvio l'app ti guiderà nella configurazione

### Convenzioni di codice

- **Lingua dell'app**: italiano (prompt, UI, messaggi di errore)
- **Lingua del codice**: inglese (nomi variabili, commenti tecnici, nomi file)
- **iOS**: segui le convenzioni SwiftUI (View, @State, @Binding, @Environment)
- **Android**: segui MVVM, usa coroutine per async, LiveData per osservazione UI
- **Entrambi**: non aggiungere dipendenze esterne senza prima discuterne

### Aree dove servono contributi

- **Android**: portare le feature mature di iOS (mood tracking completo, analytics, supporto immagini, notifiche, onboarding esteso)
- **iOS**: sistema di memoria conversazionale (l'infrastruttura `MemorySummary` esiste ma non è ancora attiva)
- **Entrambi**: test unitari e di integrazione, accessibilità, localizzazione multi-lingua
