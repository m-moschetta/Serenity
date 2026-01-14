# Specifiche Feature: Personalizzazione Tono di Voce

Documento per lo sviluppatore iOS per replicare la feature di personalizzazione del tono dell'assistente.

---

## 1. Overview

La feature permette agli utenti di personalizzare come l'assistente Tranquiz comunica con loro attraverso 6 parametri configurabili:

| Parametro | Chiave | Opzione A | Opzione B | Default |
|-----------|--------|-----------|-----------|---------|
| Empatia | `tone_empathy` | `empathetic` | `neutral` | `empathetic` |
| Approccio | `tone_approach` | `gentle` | `direct` | `gentle` |
| Energia | `tone_energy` | `calm` | `energetic` | `calm` |
| Tono | `tone_mood` | `serious` | `light` | `serious` |
| Lunghezza | `tone_length` | `brief` | `detailed` | `brief` |
| Stile | `tone_style` | `intimate` | `professional` | `intimate` |

---

## 2. Flusso Utente

### 2.1 Onboarding (4 step)

L'onboarding ora ha **4 step** invece di 3:

```
Step 0: Nome utente (opzionale)
Step 1: Come ti senti oggi?
Step 2: Obiettivo con Tranquiz
Step 3: Preferenze tono (NUOVO)
```

### 2.2 Settings

Nuova sezione nelle impostazioni "Tono dell'assistente" con 6 preferenze modificabili in qualsiasi momento.

---

## 3. UI - Step 4 Onboarding

### 3.1 Layout

Lo step 4 mostra:
- Titolo: "Come preferisci che ti parli?"
- 6 gruppi di selezione (uno per parametro)
- Ogni gruppo ha 2 opzioni mutualmente esclusive (chip/toggle)
- ScrollView per contenere tutti i gruppi
- Pulsante "Fine" in basso

### 3.2 Struttura UI per ogni parametro

```
[Label del parametro]
[ Opzione A (selezionata) ] [ Opzione B ]
```

Esempio:
```
Empatia
[ Empatico ✓ ] [ Neutro ]

Approccio
[ Gentile ✓ ] [ Diretto ]

Energia
[ Calmo ✓ ] [ Energico ]

Tono
[ Serio ✓ ] [ Leggero ]

Lunghezza risposte
[ Brevi ✓ ] [ Dettagliate ]

Stile
[ Intimo ✓ ] [ Professionale ]
```

### 3.3 Progress Dots

Aggiungere un 4° dot agli indicatori di progresso:
- 4 dot totali
- Il dot attivo è colorato (primary color)
- I dot inattivi sono grigi

---

## 4. Stringhe Localizzate (Italiano)

### 4.1 Onboarding Step 4

```
onboarding_tone_title = "Come preferisci che ti parli?"
onboarding_tone_subtitle = "Personalizza lo stile di comunicazione"
```

### 4.2 Labels dei parametri

```
tone_empathy_label = "Empatia"
tone_approach_label = "Approccio"
tone_energy_label = "Energia"
tone_mood_label = "Tono"
tone_length_label = "Lunghezza risposte"
tone_style_label = "Stile"
```

### 4.3 Opzioni dei parametri

```
// Empatia
tone_empathetic = "Empatico"
tone_neutral = "Neutro"

// Approccio
tone_gentle = "Gentile"
tone_direct = "Diretto"

// Energia
tone_calm = "Calmo"
tone_energetic = "Energico"

// Tono
tone_serious = "Serio"
tone_light = "Leggero"

// Lunghezza
tone_brief = "Brevi"
tone_detailed = "Dettagliate"

// Stile
tone_intimate = "Intimo"
tone_professional = "Professionale"
```

### 4.4 Settings

```
pref_tone_category_title = "Tono dell'assistente"

pref_tone_empathy_title = "Empatia"
pref_tone_empathy_summary = "Quanto vuoi che sia comprensivo"

pref_tone_approach_title = "Approccio"
pref_tone_approach_summary = "Gentile o diretto"

pref_tone_energy_title = "Energia"
pref_tone_energy_summary = "Calmo o motivante"

pref_tone_mood_title = "Tono"
pref_tone_mood_summary = "Serio o leggero"

pref_tone_length_title = "Lunghezza risposte"
pref_tone_length_summary = "Brevi o dettagliate"

pref_tone_style_title = "Stile"
pref_tone_style_summary = "Intimo o professionale"
```

### 4.5 Opzioni per picker/lista nelle Settings

```
// Empatia
["Empatico", "Neutro/Pratico"] → ["empathetic", "neutral"]

// Approccio
["Gentile", "Diretto"] → ["gentle", "direct"]

// Energia
["Calmo/Riflessivo", "Energico/Motivante"] → ["calm", "energetic"]

// Tono
["Serio", "Leggero/Ironico"] → ["serious", "light"]

// Lunghezza
["Risposte brevi", "Risposte dettagliate"] → ["brief", "detailed"]

// Stile
["Intimo/Amichevole", "Professionale"] → ["intimate", "professional"]
```

---

## 5. Persistenza Dati

### 5.1 Chiavi UserDefaults/Preferences

```swift
// Chiavi per salvare le preferenze tono
let TONE_EMPATHY = "pref_tone_empathy"      // String: "empathetic" | "neutral"
let TONE_APPROACH = "pref_tone_approach"    // String: "gentle" | "direct"
let TONE_ENERGY = "pref_tone_energy"        // String: "calm" | "energetic"
let TONE_MOOD = "pref_tone_mood"            // String: "serious" | "light"
let TONE_LENGTH = "pref_tone_length"        // String: "brief" | "detailed"
let TONE_STYLE = "pref_tone_style"          // String: "intimate" | "professional"
```

### 5.2 Valori Default

Se non impostati, usare questi default:
```swift
toneEmpathy = "empathetic"
toneApproach = "gentle"
toneEnergy = "calm"
toneMood = "serious"
toneLength = "brief"
toneStyle = "intimate"
```

### 5.3 Salvataggio

- **Onboarding**: Salvare tutte le 6 preferenze quando l'utente completa lo step 4
- **Settings**: Salvare singolarmente ogni preferenza quando viene modificata

---

## 6. Integrazione System Prompt

### 6.1 Dove inserire le istruzioni

Le istruzioni di tono vanno aggiunte al system prompt DOPO il prompt base e PRIMA del contesto utente.

Struttura finale del system prompt:
```
[Prompt base di Tranquiz]

<communication_style>
[Istruzioni di tono generate dinamicamente]
</communication_style>

Contesto utente:
Nome: [nome]
Oggi si sente: [feeling]
Obiettivo: [goal]
```

### 6.2 Funzione di generazione istruzioni tono

```swift
func buildToneInstructions() -> String {
    var instructions: [String] = []

    // Empatia
    switch UserDefaults.toneEmpathy {
    case "empathetic":
        instructions.append("Sii empatico, comprensivo e accogliente")
    case "neutral":
        instructions.append("Sii neutro, oggettivo e pratico")
    default:
        instructions.append("Sii empatico, comprensivo e accogliente")
    }

    // Approccio
    switch UserDefaults.toneApproach {
    case "gentle":
        instructions.append("Usa un approccio gentile e delicato")
    case "direct":
        instructions.append("Sii diretto e vai al punto")
    default:
        instructions.append("Usa un approccio gentile e delicato")
    }

    // Energia
    switch UserDefaults.toneEnergy {
    case "calm":
        instructions.append("Mantieni un tono calmo e riflessivo")
    case "energetic":
        instructions.append("Sii energico, motivante e incoraggiante")
    default:
        instructions.append("Mantieni un tono calmo e riflessivo")
    }

    // Tono
    switch UserDefaults.toneMood {
    case "serious":
        instructions.append("Mantieni un tono serio e professionale")
    case "light":
        instructions.append("Puoi essere leggero e usare un po' di ironia quando appropriato")
    default:
        instructions.append("Mantieni un tono serio e professionale")
    }

    // Lunghezza
    switch UserDefaults.toneLength {
    case "brief":
        instructions.append("Dai risposte concise e mirate")
    case "detailed":
        instructions.append("Fornisci risposte dettagliate e approfondite")
    default:
        instructions.append("Dai risposte concise e mirate")
    }

    // Stile
    switch UserDefaults.toneStyle {
    case "intimate":
        instructions.append("Usa uno stile intimo e amichevole, come un amico fidato")
    case "professional":
        instructions.append("Mantieni uno stile professionale e formale")
    default:
        instructions.append("Usa uno stile intimo e amichevole, come un amico fidato")
    }

    return "<communication_style>\n" + instructions.joined(separator: "\n") + "\n</communication_style>"
}
```

### 6.3 Esempio output generato

Con i default:
```
<communication_style>
Sii empatico, comprensivo e accogliente
Usa un approccio gentile e delicato
Mantieni un tono calmo e riflessivo
Mantieni un tono serio e professionale
Dai risposte concise e mirate
Usa uno stile intimo e amichevole, come un amico fidato
</communication_style>
```

Con selezioni personalizzate (neutral, direct, energetic, light, detailed, professional):
```
<communication_style>
Sii neutro, oggettivo e pratico
Sii diretto e vai al punto
Sii energico, motivante e incoraggiante
Puoi essere leggero e usare un po' di ironia quando appropriato
Fornisci risposte dettagliate e approfondite
Mantieni uno stile professionale e formale
</communication_style>
```

---

## 7. Comportamento UI

### 7.1 Onboarding Step 4

1. Quando l'utente arriva allo step 4:
   - Nascondere il campo di input testuale (usato negli step 0-2)
   - Mostrare il container con i 6 gruppi di selezione
   - Pre-selezionare i valori default

2. Le selezioni sono **mutualmente esclusive** per ogni gruppo (solo una opzione attiva)

3. Quando l'utente preme "Fine":
   - Leggere tutte le selezioni correnti
   - Salvare in UserDefaults/Preferences
   - Completare l'onboarding

### 7.2 Settings

1. Ogni parametro è una lista/picker con 2 opzioni
2. Mostrare il valore corrente come summary/subtitle
3. Salvare immediatamente quando l'utente cambia una selezione

### 7.3 Navigazione

- Step 4 ha pulsante "Indietro" per tornare allo step 3
- Pulsante "Salta" salta tutto l'onboarding (usa i default)
- Da Settings si può modificare in qualsiasi momento

---

## 8. Note Implementative

### 8.1 State Management (Onboarding)

Durante l'onboarding, mantenere lo stato locale delle 6 selezioni:
```swift
var toneEmpathy: String = "empathetic"
var toneApproach: String = "gentle"
var toneEnergy: String = "calm"
var toneMood: String = "serious"
var toneLength: String = "brief"
var toneStyle: String = "intimate"
```

Salvare in UserDefaults solo al completamento.

### 8.2 State Restoration

Se l'utente esce e rientra nell'onboarding (es. rotazione schermo, background):
- Ripristinare lo step corrente
- Ripristinare le selezioni temporanee

### 8.3 Consistenza Settings ↔ Onboarding

Le preferenze salvate in Settings e Onboarding usano le **stesse chiavi**. Se l'utente modifica le settings dopo l'onboarding, le nuove preferenze sovrascrivono quelle dell'onboarding.

---

## 9. Testing Checklist

- [ ] Onboarding step 4 mostra tutti i 6 parametri
- [ ] Selezioni mutualmente esclusive funzionano
- [ ] Default pre-selezionati correttamente
- [ ] Pulsante "Fine" salva tutte le preferenze
- [ ] Settings mostra categoria "Tono dell'assistente"
- [ ] Ogni preferenza Settings ha 2 opzioni
- [ ] Modifiche Settings salvate immediatamente
- [ ] System prompt include istruzioni tono
- [ ] Cambio preferenze riflesso nel prossimo messaggio AI

---

## 10. Riferimenti File Android

Per riferimento, ecco i file modificati su Android:

| File | Descrizione |
|------|-------------|
| `Constants.kt` | Chiavi preferenze |
| `strings.xml` | Tutte le stringhe |
| `fragment_onboarding.xml` | Layout step 4 con ChipGroups |
| `OnboardingFragment.kt` | Logica onboarding 4 step |
| `preferences.xml` | Definizione UI Settings |
| `ApiClient.kt` | buildToneInstructions() |

---

*Documento creato il 2026-01-06*
