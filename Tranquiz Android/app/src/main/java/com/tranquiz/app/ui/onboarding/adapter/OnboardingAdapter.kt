package com.tranquiz.app.ui.onboarding.adapter

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.RecyclerView
import com.tranquiz.app.R
import com.tranquiz.app.databinding.ItemOnboardingOptionBinding
import com.tranquiz.app.ui.onboarding.model.OnboardingOption
import com.tranquiz.app.ui.onboarding.model.OnboardingQuestionKind

class OnboardingAdapter(
    private val onOptionSelected: (OnboardingOption) -> Unit
) : RecyclerView.Adapter<OnboardingAdapter.ViewHolder>() {

    private var options: List<OnboardingOption> = emptyList()
    private var selectedIds: MutableSet<String> = mutableSetOf()
    private var questionKind: OnboardingQuestionKind = OnboardingQuestionKind.SingleChoice

    fun submitList(
        newOptions: List<OnboardingOption>,
        currentSelections: Set<String>,
        kind: OnboardingQuestionKind
    ) {
        options = newOptions
        selectedIds = currentSelections.toMutableSet()
        questionKind = kind
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val binding = ItemOnboardingOptionBinding.inflate(
            LayoutInflater.from(parent.context),
            parent,
            false
        )
        return ViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.bind(options[position])
    }

    override fun getItemCount(): Int = options.size

    inner class ViewHolder(private val binding: ItemOnboardingOptionBinding) :
        RecyclerView.ViewHolder(binding.root) {

        fun bind(option: OnboardingOption) {
            binding.tvOptionTitle.text = option.title
            
            if (option.detail != null) {
                binding.tvOptionDetail.visibility = View.VISIBLE
                binding.tvOptionDetail.text = option.detail
            } else {
                binding.tvOptionDetail.visibility = View.GONE
            }

            if (option.triggersSafety) {
                binding.tvOptionSafetyWarning.visibility = View.VISIBLE
            } else {
                binding.tvOptionSafetyWarning.visibility = View.GONE
            }

            val isSelected = selectedIds.contains(option.id)
            
            // UI state based on selection
            if (isSelected) {
                binding.cardOption.setCardBackgroundColor(
                    ContextCompat.getColor(binding.root.context, R.color.user_message_background)
                )
                binding.cardOption.strokeColor = ContextCompat.getColor(binding.root.context, R.color.primary_color)
                binding.iv_option_check.visibility = View.VISIBLE
            } else {
                binding.cardOption.setCardBackgroundColor(
                    ContextCompat.getColor(binding.root.context, R.color.ai_message_background)
                )
                binding.cardOption.strokeColor = ContextCompat.getColor(binding.root.context, R.color.message_border)
                binding.iv_option_check.visibility = View.INVISIBLE
            }

            // Counter for multi-choice
            if (questionKind is OnboardingQuestionKind.MultiChoice) {
                binding.tvOptionCounter.visibility = View.VISIBLE
                binding.tvOptionCounter.text = "${selectedIds.size}/${(questionKind as OnboardingQuestionKind.MultiChoice).max}"
            } else {
                binding.tvOptionCounter.visibility = View.GONE
            }

            binding.root.setOnClickListener {
                onOptionSelected(option)
            }
        }
    }
}
