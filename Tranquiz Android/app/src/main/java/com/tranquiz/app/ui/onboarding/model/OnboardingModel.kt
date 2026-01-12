package com.tranquiz.app.ui.onboarding.model

import java.util.Date

sealed class OnboardingQuestionKind {
    object SingleChoice : OnboardingQuestionKind()
    data class MultiChoice(val max: Int) : OnboardingQuestionKind()
    data class FreeText(val placeholder: String? = null) : OnboardingQuestionKind()
    data class Scale(val options: List<String>) : OnboardingQuestionKind()
}

data class OnboardingOption(
    val id: String,
    val title: String,
    val detail: String? = null,
    val triggersSafety: Boolean = false
)

data class OnboardingQuestion(
    val id: String,
    val title: String,
    val subtitle: String? = null,
    val kind: OnboardingQuestionKind,
    val options: List<OnboardingOption> = emptyList(),
    val reason: OnboardingReason? = null
) {
    val maxSelection: Int = when (kind) {
        is OnboardingQuestionKind.MultiChoice -> kind.max
        else -> 1
    }
}

enum class OnboardingReason(val label: String) {
    ANXIETY("Provo spesso stati d’ansia"),
    SADNESS("Mi sento triste e giù di morale"),
    PARENTING("Ho difficoltà con mio figlio / mia figlia"),
    GROWTH("Voglio crescere come persona"),
    RELATIONSHIP("Ho difficoltà con la mia relazione"),
    GENDER_IDENTITY("Voglio esplorare la mia identità di genere"),
    SEXUALITY("Riguarda la sfera sessuale"),
    LIFE_EVENT("È successa una cosa che mi ha cambiato"),
    WORK_STUDY("Sto avendo problemi con il lavoro o lo studio"),
    FOOD_BODY("Penso di avere un problema con il cibo"),
    OTHER("Per un motivo diverso");

    companion object {
        fun fromId(id: String): OnboardingReason? {
            return values().find { it.name.lowercase() == id.lowercase() }
        }
    }
}

data class OnboardingAnswer(
    val questionId: String,
    val question: String,
    val answers: List<String>,
    val reason: OnboardingReason?,
    val isSafetyRelated: Boolean
)

data class OnboardingProfile(
    val createdAt: Date,
    val answers: List<OnboardingAnswer>,
    val primaryReason: OnboardingReason?,
    val otherReasons: List<OnboardingReason>,
    val safetyFlag: Boolean
) {
    fun summaryText(): String {
        val lines = mutableListOf<String>()
        lines.add("Profilo onboarding (usa queste informazioni per contestualizzare tono e suggerimenti, non per fare diagnosi):")

        val commonKeys = setOf("q0_gender", "q0_age", "q0_history", "q0_meds")
        val common = answers.filter { commonKeys.contains(it.questionId) }
        for (ans in common) {
            ans.answers.firstOrNull()?.let {
                lines.add("- ${ans.question}: $it")
            }
        }

        primaryReason?.let { main ->
            val others = otherReasons.map { it.label }
            val otherText = if (others.isEmpty()) "" else " | Altri: ${others.joinToString(", ")}"
            lines.add("- Motivo principale: ${main.label}$otherText")
        }

        val grouped = answers.filter { !commonKeys.contains(it.questionId) && it.questionId !in listOf("q1_root", "safety_check") }
            .groupBy { it.reason }

        grouped.entries.sortedBy { it.key?.label ?: "" }.forEach { (reason, entries) ->
            reason?.let {
                val joined = entries.joinToString(" | ") { "${it.question}: ${it.answers.joinToString(", ")}" }
                if (joined.isNotEmpty()) {
                    lines.add("- ${it.label}: $joined")
                }
            }
        }

        if (safetyFlag) {
            lines.add("- Segnali di forte compromissione emersi in onboarding: SÌ (mantieni attenzione e valuta tono più protettivo).")
        }

        return lines.joinToString("\n")
    }
}
