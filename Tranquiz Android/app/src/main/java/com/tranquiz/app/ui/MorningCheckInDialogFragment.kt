package com.tranquiz.app.ui

import android.app.Dialog
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import androidx.fragment.app.DialogFragment
import com.google.android.material.textfield.TextInputEditText
import com.tranquiz.app.R
import com.tranquiz.app.databinding.DialogMorningCheckInBinding

class MorningCheckInDialogFragment : DialogFragment() {
    
    private var _binding: DialogMorningCheckInBinding? = null
    private val binding get() = _binding!!
    
    private var onSaveListener: ((String, String?) -> Unit)? = null
    
    fun setOnSaveListener(listener: (String, String?) -> Unit) {
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
        _binding = DialogMorningCheckInBinding.inflate(inflater, container, false)
        return binding.root
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        binding.btnSave.setOnClickListener {
            val motivation = binding.etMotivation.text?.toString()?.trim() ?: ""
            val fear = binding.etFear.text?.toString()?.trim()?.takeIf { it.isNotEmpty() }
            
            if (motivation.isNotEmpty()) {
                onSaveListener?.invoke(motivation, fear)
                dismiss()
            } else {
                binding.tilMotivation.error = "Campo obbligatorio"
            }
        }
        
        binding.btnCancel.setOnClickListener {
            dismiss()
        }
    }
    
    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
