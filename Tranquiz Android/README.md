# Tranquiz - AI Life Coach Assistant

Tranquiz è un'applicazione Android che fornisce supporto psicologico e life coaching attraverso un assistente AI. L'app offre un'interfaccia chat simile a WhatsApp/Telegram per conversazioni naturali con un LLM specializzato nel benessere mentale.

## Caratteristiche

- 🤖 **Assistente AI specializzato** in life coaching e supporto psicologico
- 💬 **Interfaccia chat moderna** simile a WhatsApp/Telegram
- 💾 **Persistenza locale** delle conversazioni con Room Database
- 🔄 **Indicatori di typing** per un'esperienza realistica
- 🎨 **Design Material** con tema personalizzato
- 🔒 **Sicurezza** - nessun dato sensibile salvato in cloud

## Tecnologie Utilizzate

- **Kotlin** - Linguaggio di programmazione principale
- **Android Architecture Components** - ViewModel, LiveData, Room
- **Retrofit** - Client HTTP per API calls
- **Room Database** - Persistenza locale
- **Material Design** - UI/UX moderna
- **Coroutines** - Programmazione asincrona

## Setup e Installazione

## 🚀 Setup Rapido

### Opzione 1: Setup Automatico (Raccomandato)
1. **Configura il Gateway/Worker (Marilena)**:
   - Apri `app/src/main/res/values/strings.xml`
   - Imposta `gateway_base_url` con l'URL del tuo worker (es. `https://your-marilena-worker.example.com/`)
   - Imposta `gateway_api_key` con il token del worker (se richiesto)

2. **Esegui lo script di setup**:
   ```cmd
   setup_java.bat
   ```
   Questo script configurerà automaticamente Java e compilerà il progetto.

### Opzione 2: Usa Android Studio (Più Semplice)
1. **Configura il Gateway/Worker** (come sopra)
2. **Apri il progetto**:
   - Apri Android Studio
   - Seleziona "Open an existing project"
   - Naviga alla cartella `Tranquiz`
3. **Compila ed esegui**:
   - Clicca su "Build" → "Make Project"
   - Connetti un dispositivo Android o avvia un emulatore
   - Clicca su "Run" (▶️)

📖 **Per istruzioni dettagliate e risoluzione problemi**: Vedi [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md)

### Prerequisiti
- Android Studio Arctic Fox (2020.3.1) o versioni successive
- Android SDK API 24 (Android 7.0) o superiore
- Java/JDK 17 o superiore
- URL del Worker/Gateway (Marilena) e token, oppure chiavi provider se non usi il worker

<!--
<?xml version="1.0" encoding="utf-8"?>
<resources>
    ISTRUZIONI PER LA CONFIGURAZIONE:
    1. Copia questo file e rinominalo in "api_keys.xml"
    2. Sostituisci "YOUR_OPENAI_API_KEY_HERE" con la tua vera chiave API di OpenAI
    3. Ottieni la tua chiave API da: https://platform.openai.com/api-keys
    
    IMPORTANTE: Non condividere mai la tua chiave API!
    Il file api_keys.xml è già incluso nel .gitignore per la sicurezza.

    <string name="openai_api_key">YOUR_OPENAI_API_KEY_HERE</string>
</resources>
-->

## Struttura del Progetto

```
app/src/main/java/com/tranquiz/app/
├── data/
│   ├── api/           # Servizi API e client Retrofit
│   ├── database/      # Room database e DAO
│   ├── model/         # Modelli dati
│   └── repository/    # Repository pattern per gestione dati
├── ui/
│   ├── adapter/       # Adapter per RecyclerView
│   ├── viewmodel/     # ViewModel per logica UI
│   └── MainActivity   # Activity principale
└── res/
    ├── layout/        # Layout XML
    ├── drawable/      # Icone e drawable
    ├── values/        # Colori, stringhe, temi
    └── menu/          # Menu XML
```

## Personalizzazione

### Modifica del Prompt AI

Per personalizzare il comportamento dell'assistente AI, modifica la costante `SYSTEM_PROMPT` in `ChatApiService.kt`:

```kotlin
const val SYSTEM_PROMPT = """
    Il tuo prompt personalizzato qui...
"""
```

### Cambio Provider LLM

Con il worker Marilena, puoi cambiare provider direttamente dall'app (impostazioni/selector). L'app invia al worker un payload OpenAI‑compatibile con il campo `provider` e il worker instrada verso OpenAI, Anthropic, Perplexity o Groq.

Se non usi il worker:
1. Imposta i `provider_*_base_url` e le `*_api_key` in `strings.xml`
2. Aggiorna il provider corrente in `current_provider`
3. La chiamata avverrà direttamente ai provider (meno sicuro: chiavi nel client)

### Personalizzazione UI

- **Colori**: Modifica `colors.xml`
- **Temi**: Modifica `themes.xml`
- **Layout messaggi**: Modifica i file in `res/layout/item_message_*`

## Funzionalità Principali

### Chat Interface

- Messaggi dell'utente allineati a destra (verde)
- Messaggi AI allineati a sinistra (bianco) con avatar
- Indicatore di typing durante le risposte
- Timestamp per ogni messaggio
- Scroll automatico ai nuovi messaggi

### Gestione Dati

- **Persistenza locale**: Tutte le conversazioni salvate con Room
- **Cronologia**: Mantiene gli ultimi 10 messaggi per contesto
- **Cancellazione**: Opzione per pulire la conversazione

### Sicurezza

- Nessun dato salvato in cloud
- Chiavi API non incluse nel codice sorgente
- Backup escluso per dati sensibili

## Limitazioni Attuali

- ⚠️ **Non è un sostituto per terapia professionale**
- 🔑 Richiede chiave API OpenAI (a pagamento)
- 📱 Solo una conversazione alla volta
- 🌐 Richiede connessione internet per le risposte AI

## Sviluppi Futuri

- [ ] Supporto per multiple conversazioni
- [ ] Configurazione API key dall'app
- [ ] Modalità offline con risposte predefinite
- [ ] Esportazione conversazioni
- [ ] Notifiche e promemoria
- [ ] Integrazione con altri provider LLM
- [ ] Supporto per allegati (immagini, audio)

## Contributi

I contributi sono benvenuti! Per contribuire:

1. Fork del repository
2. Crea un branch per la tua feature
3. Commit delle modifiche
4. Push al branch
5. Apri una Pull Request

## Licenza

Questo progetto è rilasciato sotto licenza MIT. Vedi il file `LICENSE` per dettagli.

## Supporto

Per problemi o domande:
- Apri un issue su GitHub
- Controlla la documentazione Android
- Verifica la configurazione della chiave API

## Disclaimer

Tranquiz è uno strumento di supporto e non sostituisce l'aiuto di professionisti qualificati della salute mentale. In caso di problemi gravi, consulta sempre un professionista.