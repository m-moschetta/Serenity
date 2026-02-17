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
import com.tranquiz.app.databinding.DialogMorningCheckInBinding

class MorningCheckInDialogFragment : DialogFragment() {
    
    private var _binding: DialogMorningCheckInBinding? = null
    private val binding get() = _binding!!
    
    private var onSaveListener: ((String, String?) -> Unit)? = null

    private val motivationOptions = listOf(
        "energy" to "Avere energia",
        "focus" to "Restare concentrato",
        "relationships" to "Curare le relazioni",
        "growth" to "Crescita personale",
        "health" to "Salute e benessere",
        "gratitude" to "Gratitudine"
    )

    private val fearOptions = listOf(
        "stress" to "Stress",
        "anxiety" to "Ansia",
        "uncertainty" to "Incertezza",
        "loneliness" to "Solitudine",
        "tiredness" to "Stanchezza",
        "none" to "Nessuna in particolare"
    )
    
    fun setOnSaveListener(listener: (String, String?) -> Unit) {
        onSaveListener = listener
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setStyle(STYLE_NORMAL, com.google.android.material.R.style.ThemeOverlay_Material3_MaterialAlertDialog)
    }
    
    @Suppress("DEPRECATION")
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
        _binding = DialogMorningCheckInBinding.inflate(inflater, container, false)
        return binding.root
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        setupMotivationChips()
        setupFearChips()

        binding.chipGroupMotivation.setOnCheckedStateChangeListener { _, checkedIds ->
            if (checkedIds.isNotEmpty()) {
                binding.tvErrorMotivation.visibility = View.GONE
            }
        }

        binding.chipGroupFear.setOnCheckedStateChangeListener { _, checkedIds ->
            if (checkedIds.isNotEmpty()) {
                binding.tvErrorFear.visibility = View.GONE
            }
        }

        binding.btnSave.setOnClickListener {
            val motivationId = binding.chipGroupMotivation.checkedChipId
            val fearId = binding.chipGroupFear.checkedChipId

            val selectedMotivation = binding.chipGroupMotivation
                .findViewById<Chip>(motivationId)
                ?.tag as? String
            val selectedFear = binding.chipGroupFear
                .findViewById<Chip>(fearId)
                ?.tag as? String

            val hasMotivation = !selectedMotivation.isNullOrBlank()
            val hasFear = !selectedFear.isNullOrBlank()

            if (!hasMotivation) {
                binding.tvErrorMotivation.visibility = View.VISIBLE
                binding.tvErrorMotivation.text = "Seleziona una motivazione"
            }

            if (!hasFear) {
                binding.tvErrorFear.visibility = View.VISIBLE
                binding.tvErrorFear.text = "Seleziona una risposta"
            }

            if (hasMotivation && hasFear) {
                val normalizedFear = if (selectedFear == "none") null else selectedFear
                onSaveListener?.invoke(selectedMotivation!!, normalizedFear)
                dismiss()
            }
        }
        
        binding.btnCancel.setOnClickListener {
            dismiss()
        }
    }

    private fun setupMotivationChips() {
        motivationOptions.forEach { (id, label) ->
            val chip = Chip(requireContext(), null, com.google.android.material.R.attr.chipStyle)
            chip.id = View.generateViewId()
            chip.text = label
            chip.tag = id
            chip.isCheckable = true
            binding.chipGroupMotivation.addView(chip)
        }
    }

    private fun setupFearChips() {
        fearOptions.forEach { (id, label) ->
            val chip = Chip(requireContext(), null, com.google.android.material.R.attr.chipStyle)
            chip.id = View.generateViewId()
            chip.text = label
            chip.tag = id
            chip.isCheckable = true
            binding.chipGroupFear.addView(chip)
        }
    }
    
    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
