package com.tranquiz.app.ui

import android.app.Dialog
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import androidx.fragment.app.DialogFragment
import com.google.android.material.chip.Chip
import com.tranquiz.app.R
import com.tranquiz.app.databinding.DialogEveningCheckInBinding

class EveningCheckInDialogFragment : DialogFragment() {
    
    private var _binding: DialogEveningCheckInBinding? = null
    private val binding get() = _binding!!
    
    private var onSaveListener: ((List<String>) -> Unit)? = null
    
    private val moodAdjectives = listOf(
        "very_happy" to "Molto felice",
        "happy" to "Felice",
        "calm" to "Calmo",
        "peaceful" to "Sereno",
        "grateful" to "Gratificato",
        "hopeful" to "Speranzoso",
        "content" to "Contento",
        "motivated" to "Motivato",
        "loved" to "Amato",
        "confident" to "Sicuro",
        "neutral" to "Neutrale",
        "tired" to "Stanco",
        "anxious" to "Ansioso",
        "stressed" to "Stressato",
        "frustrated" to "Frustrato",
        "uncertain" to "Incertezza",
        "lonely" to "Solo",
        "sad" to "Triste",
        "very_sad" to "Molto triste",
        "overwhelmed" to "Sopraffatto"
    )
    
    fun setOnSaveListener(listener: (List<String>) -> Unit) {
        onSaveListener = listener
    }
    
    override fun onCreateDialog(savedInstanceState: Bundle?): Dialog {
        return super.onCreateDialog(savedInstanceState).apply {
            window?.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE)
        }
    }
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = DialogEveningCheckInBinding.inflate(inflater, container, false)
        return binding.root
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        setupMoodChips()
        
        binding.btnSave.setOnClickListener {
            val selectedIds = binding.chipGroupMoods.checkedChipIds.map { id ->
                binding.chipGroupMoods.findViewById<Chip>(id)?.tag as? String
            }.filterNotNull()
            
            if (selectedIds.isNotEmpty()) {
                onSaveListener?.invoke(selectedIds)
                dismiss()
            } else {
                binding.tvError.visibility = View.VISIBLE
                binding.tvError.text = "Seleziona almeno un aggettivo"
            }
        }
        
        binding.btnCancel.setOnClickListener {
            dismiss()
        }
    }
    
    private fun setupMoodChips() {
        moodAdjectives.forEach { (id, label) ->
            val chip = Chip(requireContext())
            chip.text = label
            chip.tag = id
            chip.isCheckable = true
            chip.chipBackgroundColor = resources.getColorStateList(R.color.profile_card_amber, null)
            binding.chipGroupMoods.addView(chip)
        }
    }
    
    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
