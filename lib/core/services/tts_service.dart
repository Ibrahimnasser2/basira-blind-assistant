import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'settings_service.dart';

class TtsService {
  TtsService(this._settings);

  final SettingsService _settings;
  final FlutterTts _flutterTts = FlutterTts();
  static const MethodChannel _nativeTtsChannel = MethodChannel('basira/native_tts');
  bool _initialized = false;
  bool _available = true;
  String? _lastLanguageCode;
  double? _lastSpeechRate;

  Future<void> init() async {
    final shouldReconfigure = !_initialized ||
        _lastLanguageCode != _settings.languageCode ||
        _lastSpeechRate != _settings.speechRate;
    if (!shouldReconfigure) return;

    try {
      await _flutterTts.awaitSpeakCompletion(false);
      await _flutterTts.setSpeechRate(_settings.speechRate);
      await _configureLanguageAndVoice(_settings.languageCode);
      _initialized = true;
      _available = true;
      _lastLanguageCode = _settings.languageCode;
      _lastSpeechRate = _settings.speechRate;
    } catch (_) {
      // Engine may fail on some devices/emulators.
      _available = false;
    }
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    if (_settings.languageCode == 'en' && Platform.isAndroid) {
      final nativeSpoken = await _tryNativeEnglishSpeak(text);
      if (nativeSpoken) return;
    }

    await init();
    if (!_available) {
      // Retry once to recover after temporary engine failure.
      _initialized = false;
      await init();
      if (!_available) return;
    }
    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (_) {
      _available = false;
    }
  }

  Future<void> stop() async {
    if (_settings.languageCode == 'en' && Platform.isAndroid) {
      try {
        await _nativeTtsChannel.invokeMethod<bool>('stopEnglish');
      } catch (_) {}
    }
    if (!_available) return;
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }

  Future<void> _configureLanguageAndVoice(String languageCode) async {
    try {
      if (Platform.isAndroid) {
        // Prefer Google TTS engine on Android for better Arabic/English voices.
        try {
          await _flutterTts.setEngine('com.google.android.tts');
        } catch (_) {}
      }

      if (languageCode == 'ar') {
        final langOk = await _trySetLanguage('ar-EG');
        if (!langOk) {
          await _trySetLanguage('ar-SA');
        }
        await _pickVoiceByLocalePrefix('ar');
        return;
      }

      // Force English voice selection; if unavailable keep language in English anyway.
      final enUsOk = await _trySetLanguage('en-US');
      final picked = await _pickVoiceByLocalePrefix('en');
      if (!picked || !enUsOk) {
        final enGbOk = await _trySetLanguage('en-GB');
        if (!enGbOk) {
          // If English voice is unavailable on device, fallback to Arabic to keep TTS usable.
          await _trySetLanguage('ar-EG');
          await _pickVoiceByLocalePrefix('ar');
          if (_settings.languageCode != 'ar') {
            await _settings.setLanguageCode('ar');
          }
        }
      }
    } catch (_) {
      // Do not throw here; keep TTS usable with best-effort language.
      try {
        await _flutterTts.setLanguage(languageCode == 'ar' ? 'ar-EG' : 'en-US');
      } catch (_) {}
    }
  }

  Future<bool> _trySetLanguage(String locale) async {
    try {
      final result = await _flutterTts.setLanguage(locale);
      if (result is int) {
        return result == 1;
      }
      if (result is bool) {
        return result;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _pickVoiceByLocalePrefix(String localePrefix) async {
    try {
      final voices = await _flutterTts.getVoices;
      if (voices is! List) return false;

      for (final voice in voices) {
        if (voice is! Map) continue;
        final locale = (voice['locale'] ?? '').toString().toLowerCase();
        if (!locale.startsWith(localePrefix)) continue;
        if (voice['name'] == null || voice['locale'] == null) continue;

        await _flutterTts.setVoice({
          'name': voice['name'],
          'locale': voice['locale'],
        });
        return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  Future<bool> _tryNativeEnglishSpeak(String text) async {
    try {
      final result = await _nativeTtsChannel.invokeMethod<bool>(
        'speakEnglish',
        <String, dynamic>{
          'text': text,
          'speechRate': _settings.speechRate,
        },
      );
      return result == true;
    } catch (_) {
      return false;
    }
  }
}
