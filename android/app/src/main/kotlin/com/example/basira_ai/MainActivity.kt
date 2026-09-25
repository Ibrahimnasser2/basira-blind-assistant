package com.example.basira_ai

import android.speech.tts.TextToSpeech
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity(), TextToSpeech.OnInitListener {
    private var nativeTts: TextToSpeech? = null
    private var nativeTtsReady = false
    private val channelName = "basira/native_tts"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        nativeTts = TextToSpeech(this, this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "speakEnglish" -> {
                        val text = call.argument<String>("text") ?: ""
                        val speechRate = call.argument<Double>("speechRate") ?: 0.45
                        if (text.isBlank()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        if (!nativeTtsReady) {
                            result.success(false)
                            return@setMethodCallHandler
                        }

                        nativeTts?.setSpeechRate(speechRate.toFloat())
                        val setLang = nativeTts?.setLanguage(Locale.US) ?: TextToSpeech.LANG_NOT_SUPPORTED
                        if (setLang == TextToSpeech.LANG_MISSING_DATA || setLang == TextToSpeech.LANG_NOT_SUPPORTED) {
                            result.success(false)
                            return@setMethodCallHandler
                        }

                        nativeTts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "basira_native_en")
                        result.success(true)
                    }

                    "stopEnglish" -> {
                        nativeTts?.stop()
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    override fun onInit(status: Int) {
        nativeTtsReady = status == TextToSpeech.SUCCESS
    }

    override fun onDestroy() {
        nativeTts?.stop()
        nativeTts?.shutdown()
        nativeTts = null
        nativeTtsReady = false
        super.onDestroy()
    }
}
