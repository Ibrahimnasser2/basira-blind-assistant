import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';

import 'settings_service.dart';

class GeminiService {
  GeminiService(this._settings);

  final SettingsService _settings;

  Future<String> describeImage(File file, String prompt) async {
    if (_settings.geminiApiKey.isEmpty) {
      return 'مفتاح Gemini غير مُعد في الإعدادات.';
    }
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _settings.geminiApiKey,
    );
    final response = await model.generateContent([
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', await file.readAsBytes()),
      ])
    ]);
    return response.text ?? 'تعذر الحصول على وصف.';
  }

  Future<String> extractTextFromImage(File file) async {
    if (_settings.geminiApiKey.isEmpty) {
      return 'مفتاح Gemini غير مُعد في الإعدادات.';
    }
    const prompt =
        'استخرج النص الظاهر في الصورة كما هو بدون شرح. ادعم العربية والإنجليزية، '
        'وحافظ على ترتيب الأسطر.';
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _settings.geminiApiKey,
    );
    final response = await model.generateContent([
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', await file.readAsBytes()),
      ])
    ]);
    final text = (response.text ?? '').trim();
    return text.isEmpty ? 'تعذر استخراج النص من الصورة.' : text;
  }

  Future<String?> translateShortLabelToArabic(String englishLabel) async {
    if (_settings.geminiApiKey.isEmpty) return null;

    final prompt =
        'Translate this object label to Arabic with ONE short noun only and no explanation: "$englishLabel".';

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _settings.geminiApiKey,
    );
    final response = await model.generateContent([
      Content.text(prompt),
    ]);
    final text = (response.text ?? '').trim();
    if (text.isEmpty) return null;
    // Remove extra punctuation/newlines from short-label responses.
    return text.replaceAll('\n', ' ').replaceAll('"', '').trim();
  }
}
