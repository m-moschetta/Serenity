package com.tranquiz.app.ui.onboarding

import com.tranquiz.app.ui.onboarding.model.OnboardingOption
import com.tranquiz.app.ui.onboarding.model.OnboardingQuestion
import com.tranquiz.app.ui.onboarding.model.OnboardingQuestionKind
import com.tranquiz.app.ui.onboarding.model.OnboardingReason

object OnboardingFlowLibrary {
    val commonQuestions = listOf(
        OnboardingQuestion(
            id = "q0_gender",
            title = "Qual è il tuo genere?",
            kind = OnboardingQuestionKind.SingleChoice,
            options = listOf(
                OnboardingOption(id = "f", title = "Donna"),
                OnboardingOption(id = "m", title = "Uomo"),
                OnboardingOption(id = "nb", title = "Non binario"),
                OnboardingOption(id = "na", title = "Preferisco non rispondere"),
                OnboardingOption(id = "other", title = "Altro / lo descriverei diversamente")
            )
        ),
        OnboardingQuestion(
            id = "q0_age",
            title = "Qual è la tua fascia d’età?",
            kind = OnboardingQuestionKind.SingleChoice,
            options = listOf(
                OnboardingOption(id = "<14", title = "< 14"),
                OnboardingOption(id = "14-17", title = "14–17"),
                OnboardingOption(id = "18-25", title = "18–25"),
                OnboardingOption(id = "26-39", title = "26–39"),
                OnboardingOption(id = "40-50", title = "40–50"),
                OnboardingOption(id = ">50", title = "> 50")
            )
        ),
        OnboardingQuestion(
            id = "q0_history",
            title = "Hai già fatto percorsi psicologici?",
            kind = OnboardingQuestionKind.SingleChoice,
            options = listOf(
                OnboardingOption(id = "done_before", title = "Ho già fatto un percorso psicologico"),
                OnboardingOption(id = "in_therapy", title = "Sono in terapia in questo momento"),
                OnboardingOption(id = "none", title = "Non ho mai fatto percorsi psicologici")
            )
        ),
        OnboardingQuestion(
            id = "q0_meds",
            title = "Assumi farmaci prescritti per ansia, umore, sonno o simili?",
            kind = OnboardingQuestionKind.SingleChoice,
            options = listOf(
                OnboardingOption(id = "yes", title = "Assumo farmaci prescritti per ansia, umore, sonno o simili"),
                OnboardingOption(id = "no", title = "Non assumo farmaci di questo tipo"),
                OnboardingOption(id = "skip", title = "Preferisco non rispondere")
            )
        )
    )

    val rootQuestion: OnboardingQuestion = run {
        val opts = OnboardingReason.entries.map { reason ->
            OnboardingOption(id = reason.name.lowercase(), title = reason.label)
        }
        OnboardingQuestion(
            id = "q1_root",
            title = "Semplificando, perché sei qui oggi?",
            subtitle = "Puoi scegliere fino a 3 motivi",
            kind = OnboardingQuestionKind.MultiChoice(max = 3),
            options = opts
        )
    }

    val safetyQuestion = OnboardingQuestion(
        id = "safety_check",
        title = "Negli ultimi tempi ti è capitato di pensare di farti del male o di non voler più vivere?",
        subtitle = "Se hai dubbi o senti urgenza, contatta subito i numeri di emergenza.",
        kind = OnboardingQuestionKind.SingleChoice,
        options = listOf(
            OnboardingOption(id = "often", title = "Sì, spesso"),
            OnboardingOption(id = "sometimes", title = "Qualche volta"),
            OnboardingOption(id = "never", title = "Mai")
        )
    )

    fun getFlow(reason: OnboardingReason): List<OnboardingQuestion> {
        return when (reason) {
            OnboardingReason.ANXIETY -> anxietyFlow
            OnboardingReason.SADNESS -> sadnessFlow
            OnboardingReason.PARENTING -> parentingFlow
            OnboardingReason.GROWTH -> growthFlow
            OnboardingReason.RELATIONSHIP -> relationshipFlow
            OnboardingReason.GENDER_IDENTITY -> genderFlow
            OnboardingReason.SEXUALITY -> sexualityFlow
            OnboardingReason.LIFE_EVENT -> lifeEventFlow
            OnboardingReason.WORK_STUDY -> workStudyFlow
            OnboardingReason.FOOD_BODY -> foodFlow
            OnboardingReason.OTHER -> otherFlow
        }
    }

    private val anxietyFlow = listOf(
        OnboardingQuestion(
            id = "a1_duration",
            title = "Da quanto tempo senti ansia?",
            kind = OnboardingQuestionKind.SingleChoice,
            options = listOf(
                OnboardingOption(id = "days", title = "Da qualche giorno"),
                OnboardingOption(id = "weeks", title = "Da almeno due settimane"),
                OnboardingOption(id = "month", title = "Da circa un mese"),
                OnboardingOption(id = "months", title = "Da qualche mese"),
                OnboardingOption(id = "six_plus", title = "Da più di sei mesi")
            ),
            reason = OnboardingReason.ANXIETY
        ),
        OnboardingQuestion(
            id = "a2_feel",
            title = "Come descriveresti la tua ansia?",
            subtitle = "Puoi scegliere fino a 3 opzioni",
            kind = OnboardingQuestionKind.MultiChoice(max = 3),
            options = listOf(
                OnboardingOption(id = "physical", title = "Sento sintomi fisici intensi (battito accelerato, sudorazione, tremori)", triggersSafety = true),
                OnboardingOption(id = "situation", title = "È legata a una situazione precisa che è successa o potrebbe succedere"),
                OnboardingOption(id = "worry", title = "È legata a preoccupazioni che so essere esagerate ma non riesco a fermare"),
                OnboardingOption(id = "panic", title = "Arriva all’improvviso, in modo molto intenso e breve", triggersSafety = true),
                OnboardingOption(id = "places", title = "Mi è difficile uscire di casa o stare in alcuni luoghi", triggersSafety = true),
                OnboardingOption(id = "obsessions", title = "Ho pensieri ripetitivi e ossessivi che mi agitano", triggersSafety = true),
                OnboardingOption(id = "change", title = "È legata a un cambiamento che sto affrontando"),
                OnboardingOption(id = "other", title = "La descriverei in un altro modo")
            ),
            reason = OnboardingReason.ANXIETY
        ),
        OnboardingQuestion(
            id = "a3_self",
            title = "Ti riconosci in una di queste frasi?",
            kind = OnboardingQuestionKind.MultiChoice(max = 3),
            options = listOf(
                OnboardingOption(id = "first_time", title = "È la prima volta che provo ansia in questo modo"),
                OnboardingOption(id = "past", title = "Ho già provato ansia in passato"),
                OnboardingOption(id = "work_impair", title = "L’ansia sta compromettendo il mio lavoro o lo studio", triggersSafety = true),
                OnboardingOption(id = "rel_impair", title = "L’ansia sta compromettendo le mie relazioni", triggersSafety = true),
                OnboardingOption(id = "none", title = "No, non mi ritrovo in nessuna frase")
            ),
            reason = OnboardingReason.ANXIETY
        ),
        OnboardingQuestion(
            id = "a4_impact",
            title = "Quanto sta influenzando la tua vita?",
            kind = OnboardingQuestionKind.SingleChoice,
            options = listOf(
                OnboardingOption(id = "low", title = "Poco"),
                OnboardingOption(id = "mid", title = "Abbastanza"),
                OnboardingOption(id = "high", title = "Molto", triggersSafety = true),
                OnboardingOption(id = "extreme", title = "Tantissimo, faccio fatica a gestire la quotidianità", triggersSafety = true)
            ),
            reason = OnboardingReason.ANXIETY
        )
    )

    private val sadnessFlow = listOf(
        OnboardingQuestion(
            id = "b1_duration",
            title = "Da quanto tempo ti senti così?",
            kind = OnboardingQuestionKind.SingleChoice,
            options = listOf(
                OnboardingOption(id = "under_2w", title = "Meno di due settimane"),
                OnboardingOption(id = "2-4w", title = "2–4 settimane"),
                OnboardingOption(id = "1-3m", title = "1–3 mesi"),
                OnboardingOption(id = "3-6m", title = "3–6 mesi"),
                OnboardingOption(id = "6m_plus", title = "Più di sei mesi")
            ),
            reason = OnboardingReason.SADNESS
        ),
        OnboardingQuestion(
            id = "b2_feel",
            title = "Come descriveresti quello che provi?",
            subtitle = "Puoi scegliere fino a 3 opzioni",
            kind = OnboardingQuestionKind.MultiChoice(max = 3),
            options = listOf(
                OnboardingOption(id = "sad", title = "Mi sento spesso triste o vuoto"),
                OnboardingOption(id = "anhedonia", title = "Faccio fatica a provare interesse o piacere nelle cose che mi piacevano"),
                OnboardingOption(id = "tired", title = "Sono più stancə del solito, anche per le piccole cose"),
                OnboardingOption(id = "guilt", title = "Mi sento inutile o molto in colpa", triggersSafety = true),
                OnboardingOption(id = "bed", title = "Faccio fatica ad alzarmi dal letto o a portare avanti le attività quotidiane", triggersSafety = true),
                OnboardingOption(id = "focus", title = "Ho difficoltà a concentrarmi"),
                OnboardingOption(id = "sleep", title = "Dormo molto meno / molto più del solito"),
                OnboardingOption(id = "food", title = "Mangio molto meno / molto più del solito"),
                OnboardingOption(id = "other", title = "La descriverei diversamente")
            ),
            reason = OnboardingReason.SADNESS
        ),
        OnboardingQuestion(
            id = "b3_impact",
            title = "Quanto incide sulla tua vita?",
            kind = OnboardingQuestionKind.SingleChoice,
            options = listOf(
                OnboardingOption(id = "low", title = "Poco"),
                OnboardingOption(id = "mid", title = "Abbastanza"),
                OnboardingOption(id = "high", title = "Molto", triggersSafety = true),
                OnboardingOption(id = "lost_self", title = "Mi sembra di non riconoscermi più", triggersSafety = true)
            ),
            reason = OnboardingReason.SADNESS
        )
    )

    private val parentingFlow = listOf(
        OnboardingQuestion(
            id = "c1_age",
            title = "Quanti anni ha tuo figlio / tua figlia?",
            kind = OnboardingQuestionKind.SingleChoice,
            options = listOf(
                OnboardingOption(id = "0-3", title = "0–3"),
                OnboardingOption(id = "4-10", title = "4–10"),
                OnboardingOption(id = "11-17", title = "11–17"),
                OnboardingOption(id = "18+", title = "18 o più")
            ),
            reason = OnboardingReason.PARENTING
        ),
        OnboardingQuestion(
            id = "c2_issue",
            title = "Di che tipo di difficoltà si tratta?",
            subtitle = "Puoi scegliere fino a 3 opzioni",
            kind = OnboardingQuestionKind.MultiChoice(max = 3),
            options = listOf(
                OnboardingOption(id = "behavior", title = "Comportamenti difficili da gestire (scatti di rabbia, oppositività, chiusura totale)"),
                OnboardingOption(id = "mood", title = "Preoccupazioni per il suo umore o la sua ansia"),
                OnboardingOption(id = "school", title = "Difficoltà scolastiche o di rendimento"),
                OnboardingOption(id = "change", title = "Difficoltà legate a separazioni, cambiamenti familiari o di città/scuola"),
                OnboardingOption(id = "communication", title = "Fatica a comunicare o conflitti continui"),
                OnboardingOption(id = "other", title = "Altra difficoltà")
            ),
            reason = OnboardingReason.PARENTING
        ),
        OnboardingQuestion(
            id = "c3_you",
            title = "In che modo questa situazione influenza te?",
            kind = OnboardingQuestionKind.MultiChoice(max = 3),
            options = listOf(
                OnboardingOption(id = "inadequate", title = "Mi sento spesso inadeguatə come genitore"),
                OnboardingOption(id = "lost", title = "Ho l’impressione di non sapere più come aiutarlə"),
                OnboardingOption(id = "tension", title = "Ci sono forti tensioni in famiglia"),
                OnboardingOption(id = "tired", title = "Mi sento molto stanco/a e sotto pressione"),
                OnboardingOption(id = "other", title = "Altro")
            ),
            reason = OnboardingReason.PARENTING
        )
    )

    private val growthFlow = listOf(
        OnboardingQuestion(
            id = "d1_focus",
            title = "Su cosa ti piacerebbe lavorare principalmente?",
            subtitle = "Puoi scegliere fino a 3 opzioni",
            kind = OnboardingQuestionKind.MultiChoice(max = 3),
            options = listOf(
                OnboardingOption(id = "self_esteem", title = "Autostima e immagine di me stessə"),
                OnboardingOption(id = "emotions", title = "Gestione delle emozioni"),
                OnboardingOption(id = "decisions", title = "Capacità di prendere decisioni"),
                OnboardingOption(id = "boundaries", title = "Confini e assertività nelle relazioni"),
                OnboardingOption(id = "time", title = "Gestione del tempo e delle priorità"),
                OnboardingOption(id = "values", title = "Conoscenza di me e dei miei valori"),
                OnboardingOption(id = "other", title = "Altro")
            ),
            reason = OnboardingReason.GROWTH
        ),
        OnboardingQuestion(
            id = "d2_trigger",
            title = "C’è stato qualcosa di recente che ti ha fatto desiderare questo cambiamento?",
            kind = OnboardingQuestionKind.SingleChoice,
            options = listOf(
                OnboardingOption(id = "life_change", title = "Un cambiamento importante della mia vita (lavoro, città, relazione)"),
                OnboardingOption(id = "feedback", title = "Un feedback ricevuto da qualcuno"),
                OnboardingOption(id = "block", title = "Una sensazione generale di blocco"),
                OnboardingOption(id = "none", title = "Nessun evento preciso, è un desiderio che ho da tempo")
            ),
            reason = OnboardingReason.GROWTH
        ),
        OnboardingQuestion(
            id = "d3_priority",
            title = "Quanto è urgente per te iniziare questo percorso?",
            kind = OnboardingQuestionKind.SingleChoice,
            options = listOf(
                OnboardingOption(id = "interest", title = "È un interesse generale"),
                OnboardingOption(id = "important", title = "È importante ma non urgente"),
                OnboardingOption(id = "urgent", title = "È molto importante e vorrei iniziare presto")
            ),
            reason = OnboardingReason.GROWTH
        )
    )

    private val relationshipFlow = listOf(
        OnboardingQuestion(
            id = "e1_type",
            title = "Che tipo di relazione stai vivendo?",
            kind = OnboardingQuestionKind.SingleChoice,
            options = listOf(
                OnboardingOption(id = "stable", title = "Relazione di coppia stabile"),
                OnboardingOption(id = "new", title = "Relazione appena iniziata"),
                OnboardingOption(id = "closed", title = "Relazione chiusa di recente"),
                OnboardingOption(id = "undef", title = "Non saprei definirla")
            ),
            reason = OnboardingReason.RELATIONSHIP
        ),
        OnboardingQuestion(
            id = "e2_happening",
            title = "Cosa sta succedendo tra voi?",
            subtitle = "Puoi scegliere fino a 3 opzioni",
            kind = OnboardingQuestionKind.MultiChoice(max = 3),
            options = listOf(
                OnboardingOption(id = "fights", title = "Litighiamo spesso o discutiamo in modo acceso"),
                OnboardingOption(id = "communication", title = "Facciamo fatica a comunicare"),
                OnboardingOption(id = "doubts", title = "Non riesco a capire se è la persona con cui voglio stare"),
                OnboardingOption(id = "trust", title = "Ho dubbi sul suo amore o sulla sua fedeltà"),
                OnboardingOption(id = "event_change", title = "Il rapporto è cambiato dopo un evento (lutto, tradimento, gravidanza, nascita, ecc.)"),
                OnboardingOption(id = "parenting", title = "Abbiamo modi molto diversi di vedere l’educazione dei figli"),
                OnboardingOption(id = "suffering", title = "Questa relazione mi fa soffrire e non so come uscirne", triggersSafety = true),
                OnboardingOption(id = "insults", title = "Abbiamo avuto discussioni sfociate in insulti gravi o umiliazioni", triggersSafety = true),
                OnboardingOption(id = "violence", title = "Abbiamo avuto episodi di violenza fisica o minacce", triggersSafety = true),
                OnboardingOption(id = "other", title = "Altro")
            ),
            reason = OnboardingReason.RELATIONSHIP
        ),
        OnboardingQuestion(
            id = "e3_impact",
            title = "In quali modi questa situazione influenza la tua vita?",
            kind = OnboardingQuestionKind.MultiChoice(max = 3),
            options = listOf(
                OnboardingOption(id = "heavy", title = "Vivo come sempre, ma con pesantezza e turbamento"),
                OnboardingOption(id = "irritable", title = "Sono più irritabile del solito"),
                OnboardingOption(id = "no_moments", title = "Non riusciamo a ritagliarci momenti sereni insieme"),
                OnboardingOption(id = "breakup_thoughts", title = "Sto pensando di chiudere la relazione"),
                OnboardingOption(id = "separation", title = "Non viviamo più insieme o ci stiamo separando"),
                OnboardingOption(id = "avoidance", title = "Evitiamo parenti e amici per paura di discutere in pubblico"),
                OnboardingOption(id = "no_impact", title = "Non influenza più di tanto la mia vita"),
                OnboardingOption(id = "other", title = "In un altro modo")
            ),
            reason = OnboardingReason.RELATIONSHIP
        ),
        OnboardingQuestion(
            id = "e4_duration",
            title = "Da quanto tempo va avanti questa situazione?",
            kind = OnboardingQuestionKind.SingleChoice,
            options = listOf(
                OnboardingOption(id = "under_1m", title = "Meno di un mese"),
                OnboardingOption(id = "1-3m", title = "1–3 mesi"),
                OnboardingOption(id = "3-6m", title = "3–6 mesi"),
                OnboardingOption(id = "6m_plus", title = "Più di 6 mesi")
            ),
            reason = OnboardingReason.RELATIONSHIP
        )
    )

    private val genderFlow = listOf(
        OnboardingQuestion(
            id = "f1_stage",
            title = "A che punto senti di essere nel tuo percorso?",
            kind = OnboardingQuestionKind.SingleChoice,
            options = listOf(
                OnboardingOption(id = "start", title = "Sto iniziando ora a farmi domande sul mio genere"),
                OnboardingOption(id = "exploring", title = "Sono già da tempo in esplorazione"),
                OnboardingOption(id = "known", title = "Sento di avere un’identità di genere chiara ma l’ambiente attorno a me la fatica ad accettarla"),
                OnboardingOption(id = "other", title = "Altro")
            ),
            reason = OnboardingReason.GENDER_IDENTITY
        ),
        OnboardingQuestion(
            id = "f2_focus",
            title = "Su cosa vorresti lavorare soprattutto?",
            subtitle = "Puoi scegliere fino a 3 opzioni",
            kind = OnboardingQuestionKind.MultiChoice(max = 3),
            options = listOf(
                OnboardingOption(id = "understand", title = "Capire meglio come mi sento rispetto al mio genere"),
                OnboardingOption(id = "talk", title = "Parlare con qualcuno che non mi giudichi"),
                OnboardingOption(id = "family", title = "Gestire la reazione di famiglia, amicə o partner"),
                OnboardingOption(id = "coming_out", title = "Decidere se e come fare coming out in alcuni contesti"),
                OnboardingOption(id = "discrimination", title = "Affrontare eventuali discriminazioni o microaggressioni"),
                OnboardingOption(id = "other", title = "Altro")
            ),
            reason = OnboardingReason.GENDER_IDENTITY
        ),
        OnboardingQuestion(
            id = "f3_support",
            title = "Con chi ti senti più liberə di parlare di questi temi?",
            kind = OnboardingQuestionKind.SingleChoice,
            options = listOf(
                OnboardingOption(id = "none", title = "Nessuno in particolare"),
                OnboardingOption(id = "friends", title = "Con alcuni amici"),
                OnboardingOption(id = "family", title = "Con partner / famiglia"),
                OnboardingOption(id = "community", title = "Con una community o gruppo"),
                OnboardingOption(id = "skip", title = "Preferisco non dirlo")
            ),
            reason = OnboardingReason.GENDER_IDENTITY
        )
    )

    private val sexualityFlow = listOf(
        OnboardingQuestion(
            id = "g1_focus",
            title = "Che tipo di difficoltà senti più presente?",
            subtitle = "Puoi scegliere fino a 3 opzioni",
            kind = OnboardingQuestionKind.MultiChoice(max = 3),
            options = listOf(
                OnboardingOption(id = "desire", title = "Difficoltà nel desiderio sessuale (troppo basso / troppo alto rispetto a come vorrei)"),
                OnboardingOption(id = "orgasm", title = "Difficoltà a raggiungere l’orgasmo o provare piacere"),
                OnboardingOption(id = "pain", title = "Dolore o disagio fisico durante i rapporti", triggersSafety = true),
                OnboardingOption(id = "difference", title = "Differenze di desiderio o preferenze con il partner"),
                OnboardingOption(id = "orientation", title = "Preoccupazioni legate alla mia orientazione o fantasie"),
                OnboardingOption(id = "trauma", title = "Esperienze sessuali negative o non desiderate che mi influenzano ancora", triggersSafety = true),
                OnboardingOption(id = "other", title = "Altro")
            ),
            reason = OnboardingReason.SEXUALITY
        ),
        OnboardingQuestion(
            id = "g2_duration",
            title = "Da quanto tempo è presente questa difficoltà?",
            kind = OnboardingQuestionKind.SingleChoice,
            options = listOf(
                OnboardingOption(id = "recent", title = "Da poco (meno di 3 mesi)"),
                OnboardingOption(id = "mid", title = "Da 3–12 mesi"),
                OnboardingOption(id = "long", title = "Da più di un anno")
            ),
            reason = OnboardingReason.SEXUALITY
        ),
        OnboardingQuestion(
            id = "g3_impact",
            title = "Quanto sta influenzando la tua vita o la relazione?",
            kind = OnboardingQuestionKind.SingleChoice,
            options = listOf(
                OnboardingOption(id = "low", title = "Poco"),
                OnboardingOption(id = "mid", title = "Abbastanza"),
                OnboardingOption(id = "high", title = "Molto", triggersSafety = true)
            ),
            reason = OnboardingReason.SEXUALITY
        )
    )

    private val lifeEventFlow = listOf(
        OnboardingQuestion(
            id = "h1_when",
            title = "Quando è successo l’evento?",
            kind = OnboardingQuestionKind.SingleChoice,
            options = listOf(
                OnboardingOption(id = "2w", title = "Meno di due settimane fa"),
                OnboardingOption(id = "1m", title = "Meno di un mese fa"),
                OnboardingOption(id = "3m", title = "Meno di tre mesi fa"),
                OnboardingOption(id = "6m", title = "Meno di sei mesi fa"),
                OnboardingOption(id = "6m_plus", title = "Più di sei mesi fa")
            ),
            reason = OnboardingReason.LIFE_EVENT
        ),
        OnboardingQuestion(
            id = "h2_type",
            title = "L’episodio rientra in qualcuna di queste categorie?",
            subtitle = "Puoi scegliere più opzioni",
            kind = OnboardingQuestionKind.MultiChoice(max = 4),
            options = listOf(
                OnboardingOption(id = "breakup", title = "Fine di una relazione importante, separazione o divorzio"),
                OnboardingOption(id = "loss", title = "Perdita di una persona cara o interruzione di gravidanza", triggersSafety = true),
                OnboardingOption(id = "own_danger", title = "Situazioni in cui ho temuto per la mia vita (incidenti, aggressioni, disastri)", triggersSafety = true),
                OnboardingOption(id = "other_danger", title = "Situazioni in cui ho visto un’altra persona rischiare seriamente la vita", triggersSafety = true),
                OnboardingOption(id = "sexual", title = "Esperienze nella sfera sessuale non desiderate o non consensuali", triggersSafety = true),
                OnboardingOption(id = "change", title = "Grandi cambiamenti (nuovo lavoro, trasferimento, cambiamento importante di ruolo)"),
                OnboardingOption(id = "other", title = "Altro"),
                OnboardingOption(id = "none", title = "Nessuna di queste")
            ),
            reason = OnboardingReason.LIFE_EVENT
        ),
        OnboardingQuestion(
            id = "h3_feel",
            title = "Da allora, cosa senti più spesso?",
            subtitle = "Puoi scegliere fino a 4 opzioni",
            kind = OnboardingQuestionKind.MultiChoice(max = 4),
            options = listOf(
                OnboardingOption(id = "anxiety", title = "Provo spesso ansia intensa", triggersSafety = true),
                OnboardingOption(id = "sadness", title = "Tendo a essere giù di morale"),
                OnboardingOption(id = "changed", title = "Mi sembra di non essere più la stessa persona"),
                OnboardingOption(id = "rumination", title = "Non riesco a smettere di pensarci"),
                OnboardingOption(id = "rage", title = "Provo emozioni molto intense come rabbia o tristezza"),
                OnboardingOption(id = "avoidance", title = "Evito luoghi o persone legate all’evento"),
                OnboardingOption(id = "panic", title = "Quando ci ripenso vado in panico", triggersSafety = true),
                OnboardingOption(id = "relive", title = "Spesso rivivo mentalmente quella situazione", triggersSafety = true),
                OnboardingOption(id = "no_bonds", title = "Non ho più voglia di coltivare rapporti affettivi"),
                OnboardingOption(id = "none", title = "Nette di tutto questo")
            ),
            reason = OnboardingReason.LIFE_EVENT
        )
    )

    private val workStudyFlow = listOf(
        OnboardingQuestion(
            id = "i1_context",
            title = "Qual è il contesto principale?",
            kind = OnboardingQuestionKind.SingleChoice,
            options = listOf(
                OnboardingOption(id = "job", title = "Lavoro"),
                OnboardingOption(id = "university", title = "Università"),
                OnboardingOption(id = "school", title = "Scuola"),
                OnboardingOption(id = "other", title = "Altro")
            ),
            reason = OnboardingReason.WORK_STUDY
        ),
        OnboardingQuestion(
            id = "i2_issue",
            title = "In cosa consistono le difficoltà?",
            subtitle = "Puoi scegliere fino a 3 opzioni",
            kind = OnboardingQuestionKind.MultiChoice(max = 3),
            options = listOf(
                OnboardingOption(id = "overload", title = "Mi sento sopraffattə da compiti e responsabilità", triggersSafety = true),
                OnboardingOption(id = "focus", title = "Ho difficoltà di concentrazione o memoria"),
                OnboardingOption(id = "fear", title = "Ho paura di non essere abbastanza o di sbagliare"),
                OnboardingOption(id = "conflicts", title = "Ho conflitti con colleghi / superiori / compagni"),
                OnboardingOption(id = "quit", title = "Penso spesso di mollare tutto"),
                OnboardingOption(id = "burnout", title = "Mi sembra di essere in burnout", triggersSafety = true),
                OnboardingOption(id = "other", title = "Altro")
            ),
            reason = OnboardingReason.WORK_STUDY
        ),
        OnboardingQuestion(
            id = "i3_impact",
            title = "Quanto influisce sulla tua vita fuori dal lavoro / studio?",
            kind = OnboardingQuestionKind.SingleChoice,
            options = listOf(
                OnboardingOption(id = "low", title = "Poco"),
                OnboardingOption(id = "mid", title = "Abbastanza"),
                OnboardingOption(id = "high", title = "Molto, ne parlo continuamente o ci penso sempre", triggersSafety = true)
            ),
            reason = OnboardingReason.WORK_STUDY
        )
    )

    private val foodFlow = listOf(
        OnboardingQuestion(
            id = "j1_issue",
            title = "In cosa senti che c’è un problema?",
            subtitle = "Puoi scegliere fino a 3 opzioni",
            kind = OnboardingQuestionKind.MultiChoice(max = 3),
            options = listOf(
                OnboardingOption(id = "binge", title = "Ho spesso episodi in cui mangio molto più del previsto e mi sento fuori controllo", triggersSafety = true),
                OnboardingOption(id = "restrict", title = "Mi capita spesso di limitare molto il cibo o saltare i pasti", triggersSafety = true),
                OnboardingOption(id = "body", title = "Mi preoccupo molto del mio peso o del mio corpo"),
                OnboardingOption(id = "comfort", title = "Uso spesso il cibo per consolarmi o calmarmi"),
                OnboardingOption(id = "compensate", title = "Mi capita di usare pratiche per compensare (per esempio vomito autoindotto, uso di lassativi, esercizio fisico eccessivo)", triggersSafety = true),
                OnboardingOption(id = "other", title = "Altro")
            ),
            reason = OnboardingReason.FOOD_BODY
        ),
        OnboardingQuestion(
            id = "j2_frequency",
            title = "Quanto spesso succedono queste cose?",
            kind = OnboardingQuestionKind.SingleChoice,
            options = listOf(
                OnboardingOption(id = "monthly", title = "Una o due volte al mese"),
                OnboardingOption(id = "weekly", title = "Una o più volte alla settimana", triggersSafety = true),
                OnboardingOption(id = "daily", title = "Quasi ogni giorno", triggersSafety = true)
            ),
            reason = OnboardingReason.FOOD_BODY
        ),
        OnboardingQuestion(
            id = "j3_weight",
            title = "Negli ultimi tre mesi il tuo peso…",
            kind = OnboardingQuestionKind.SingleChoice,
            options = listOf(
                OnboardingOption(id = "stable", title = "È rimasto più o meno stabile"),
                OnboardingOption(id = "up", title = "È aumentato molto"),
                OnboardingOption(id = "down", title = "È diminuito molto", triggersSafety = true),
                OnboardingOption(id = "skip", title = "Preferisco non rispondere")
            ),
            reason = OnboardingReason.FOOD_BODY
        )
    )

    private val otherFlow = listOf(
        OnboardingQuestion(
            id = "k1_free",
            title = "In poche parole, su cosa ti piacerebbe lavorare?",
            kind = OnboardingQuestionKind.FreeText(placeholder = "Scrivi una frase su ciò che ti porta qui"),
            reason = OnboardingReason.OTHER
        ),
        OnboardingQuestion(
            id = "k2_area",
            title = "In quale area ti sembra rientri di più?",
            kind = OnboardingQuestionKind.SingleChoice,
            options = listOf(
                OnboardingOption(id = "anxiety", title = "Ansia e preoccupazioni"),
                OnboardingOption(id = "mood", title = "Umore e tristezza"),
                OnboardingOption(id = "relationships", title = "Relazioni affettive o familiari"),
                OnboardingOption(id = "work", title = "Lavoro / studio"),
                OnboardingOption(id = "identity", title = "Identità, genere o orientamento"),
                OnboardingOption(id = "other", title = "Altro / non saprei")
            ),
            reason = OnboardingReason.OTHER
        )
    )
}
