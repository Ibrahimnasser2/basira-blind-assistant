import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const _languageKey = 'languageCode';
  static const _speechRateKey = 'speechRate';
  static const _geminiApiKeyKey = 'geminiApiKey';

  String _languageCode = 'ar';
  double _speechRate = 0.45;
  String _geminiApiKey = '';

  String get languageCode => _languageCode;
  double get speechRate => _speechRate;
  String get geminiApiKey => _geminiApiKey;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    // Force Arabic as startup default for now.
    _languageCode = 'ar';
    await prefs.setString(_languageKey, _languageCode);
    _speechRate = prefs.getDouble(_speechRateKey) ?? 0.45;
    _geminiApiKey = prefs.getString(_geminiApiKeyKey) ?? '';
  }

  Future<void> setLanguageCode(String value) async {
    _languageCode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, value);
  }

  Future<void> setSpeechRate(double value) async {
    _speechRate = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_speechRateKey, value);
  }

  Future<void> setGeminiApiKey(String value) async {
    _geminiApiKey = value.trim();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiApiKeyKey, _geminiApiKey);
  }
}
