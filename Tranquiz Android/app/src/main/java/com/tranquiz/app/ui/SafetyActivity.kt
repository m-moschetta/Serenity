package com.tranquiz.app.ui

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.tranquiz.app.databinding.ActivitySafetyBinding

class SafetyActivity : AppCompatActivity() {

    private lateinit var binding: ActivitySafetyBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivitySafetyBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // Mostra messaggio di sicurezza completo
        binding.tvSafetyMessage.text = getString(com.tranquiz.app.R.string.safety_block_message)

        // Opzionale: pulsante per chiudere la schermata (la conversazione resta bloccata)
        binding.btnClose.setOnClickListener {
            finish()
        }
    }
}