# Istruzioni di Setup per Tranquiz

## Prerequisiti

### 1. Installazione Android Studio
1. Scarica Android Studio da [developer.android.com](https://developer.android.com/studio)
2. Installa Android Studio seguendo la procedura guidata
3. Durante l'installazione, assicurati di installare:
   - Android SDK
   - Android SDK Platform-Tools
   - Android SDK Build-Tools
   - Android Emulator (opzionale, per testare senza dispositivo fisico)

### 2. Configurazione Java/JDK

⚠️ **IMPORTANTE**: Se ricevi l'errore "JAVA_HOME is not set", segui questi passaggi:

**Opzione A: Usa il JDK di Android Studio (Raccomandato)**
1. Apri Android Studio
2. Vai su File → Settings → Build, Execution, Deployment → Build Tools → Gradle
3. In "Gradle JDK", seleziona il JDK integrato di Android Studio
4. Per la riga di comando, trova il percorso JDK:
   - File → Project Structure → SDK Location → JDK location
   - Copia il percorso (es: `C:\Program Files\Android\Android Studio\jbr`)

5. **Configura JAVA_HOME su Windows**:
   - Premi `Win + R`, digita `sysdm.cpl` e premi Invio
   - Vai su "Avanzate" → "Variabili d'ambiente"
   - In "Variabili di sistema", clicca "Nuova"
   - Nome: `JAVA_HOME`
   - Valore: il percorso copiato sopra
   - Aggiungi anche `%JAVA_HOME%\bin` alla variabile PATH
   - **Riavvia il terminale** dopo aver impostato le variabili

**Opzione B: Installa JDK separatamente**
1. Scarica OpenJDK 17 da [adoptium.net](https://adoptium.net/)
2. Installa e configura JAVA_HOME come sopra

**Verifica configurazione**:
Apri un nuovo terminale e digita:
```cmd
java -version
echo %JAVA_HOME%
```

### 3. Configurazione Gateway/Worker (Marilena)
Con Marilena puoi centralizzare le chiavi dei provider in un worker/gateway (es. Cloudflare Worker) e chiamarlo dall'app.

1. Ottieni l'URL pubblico del tuo worker (es. `https://your-marilena-worker.example.com/`)
2. Ottieni o genera il token di accesso (se richiesto)
3. Apri `app/src/main/res/values/strings.xml` e imposta:
   - `gateway_base_url` con l'URL del worker
   - `gateway_api_key` con il token del worker
4. (Opzionale) Imposta `current_provider` in `strings.xml` tra: `openai`, `anthropic`, `perplexity`, `groq`

Il payload inviato è OpenAI‑compatibile (`/v1/chat/completions`) con il campo `provider` incluso.
Il worker instrada la richiesta al provider selezionato, gestendo modelli e header.

## Apertura del Progetto

### Metodo 1: Android Studio (Raccomandato)
1. Apri Android Studio
2. Seleziona "Open an existing project"
3. Naviga alla cartella `Tranquiz` e selezionala
4. Attendi che Android Studio sincronizzi il progetto
5. Se richiesto, accetta di scaricare le dipendenze mancanti

### Metodo 2: Riga di Comando
1. Apri un terminale nella cartella del progetto
2. Esegui: `.\gradlew.bat assembleDebug`
3. La prima volta scaricherà tutte le dipendenze (può richiedere tempo)

## Risoluzione Problemi Comuni

### Errore "JAVA_HOME is not set"
- Segui le istruzioni di configurazione Java sopra
- Riavvia il terminale dopo aver impostato le variabili d'ambiente

### Errore "android.useAndroidX property is not enabled"
✅ **RISOLTO**: Ho già creato il file `gradle.properties` con la configurazione corretta.
Se l'errore persiste:
- Verifica che il file `gradle.properties` esista nella root del progetto
- Assicurati che contenga la riga: `android.useAndroidX=true`
- Esegui: `.\gradlew.bat clean build`

### Errore "Duplicate class android.support.v4..." 
✅ **RISOLTO**: Ho aggiornato il `build.gradle` per escludere le vecchie librerie di supporto.
Questo errore si verifica quando ci sono conflitti tra AndroidX e le vecchie librerie `com.android.support`.
Le soluzioni implementate:
- Aggiunto `android.enableJetifier=true` in `gradle.properties`
- Configurato esclusioni globali per le vecchie librerie di supporto
- Aggiunto esclusioni specifiche per ogni dipendenza problematica

Se l'errore persiste:
- Esegui: `.\gradlew.bat clean build`
- In Android Studio: Build → Clean Project → Rebuild Project

### Errore "resource mipmap/ic_launcher not found"
✅ **RISOLTO**: Ho creato tutte le icone launcher mancanti.
Questo errore si verifica quando mancano le icone dell'app referenziate nel `AndroidManifest.xml`.
Le icone create:
- `app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`
- `app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml`
- `app/src/main/res/drawable/ic_launcher_background.xml`
- `app/src/main/res/drawable/ic_launcher_foreground.xml`

Le icone hanno un design tematico con chat bubble, punto interrogativo e sparkles AI.

### Errore "SDK location not found"
- Apri il progetto in Android Studio
- Vai su File → Project Structure → SDK Location
- Imposta il percorso dell'Android SDK

### Errori di sincronizzazione Gradle
- In Android Studio: File → Sync Project with Gradle Files
- Da terminale: `.\gradlew.bat clean build`

### App si blocca all'avvio
- Verifica di aver configurato correttamente `gateway_base_url` e `gateway_api_key`
- Controlla i log in Android Studio (Logcat)

## Test dell'App

### Su Emulatore
1. In Android Studio, crea un AVD (Android Virtual Device)
2. Avvia l'emulatore
3. Esegui l'app con il pulsante "Run" (freccia verde)

### Su Dispositivo Fisico
1. Abilita "Opzioni sviluppatore" sul dispositivo:
   - Vai su Impostazioni → Info telefono
   - Tocca "Numero build" 7 volte
2. Abilita "Debug USB" nelle Opzioni sviluppatore
3. Collega il dispositivo al PC
4. Autorizza il debug quando richiesto
5. Esegui l'app da Android Studio

## Struttura del Progetto

```
Tranquiz/
├── app/
│   ├── src/main/
│   │   ├── java/com/tranquiz/app/
│   │   │   ├── data/          # Modelli, database, API
│   │   │   └── ui/            # Activity, adapter, ViewModel
│   │   ├── res/               # Risorse (layout, drawable, values)
│   │   └── AndroidManifest.xml
│   ├── build.gradle           # Configurazione modulo app
│   └── proguard-rules.pro     # Regole di offuscamento
├── build.gradle               # Configurazione progetto
├── settings.gradle            # Impostazioni Gradle
└── README.md                  # Documentazione principale
```

## Prossimi Passi

1. **Personalizzazione**: Modifica i colori, stringhe e layout in `app/src/main/res/`
2. **Prompt AI**: Personalizza il prompt di sistema in `ApiConstants.kt`
3. **Provider LLM**: Cambia provider modificando `ChatApiService.kt` e `ApiClient.kt`
4. **Funzionalità**: Aggiungi nuove funzionalità estendendo il ViewModel e Repository

## Supporto

Se incontri problemi:
1. Controlla questa guida per soluzioni comuni
2. Verifica i log di Android Studio (Logcat)
3. Assicurati che tutte le dipendenze siano aggiornate
4. Prova a pulire e ricompilare: Build → Clean Project → Rebuild Project

Buon sviluppo! 🚀