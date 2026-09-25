import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/settings_service.dart';
import '../../core/services/tts_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  static const routeName = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _apiController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsService>();
    _apiController = TextEditingController(text: settings.geminiApiKey);
  }

  @override
  void dispose() {
    _apiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('اللغة'),
          DropdownButton<String>(
            value: settings.languageCode,
            items: const [
              DropdownMenuItem(value: 'ar', child: Text('العربية')),
              DropdownMenuItem(value: 'en', child: Text('English')),
            ],
            onChanged: (value) {
              if (value != null) settings.setLanguageCode(value);
            },
          ),
          const SizedBox(height: 16),
          Text('سرعة الصوت: ${settings.speechRate.toStringAsFixed(2)}'),
          Slider(
            value: settings.speechRate,
            min: 0.2,
            max: 0.7,
            onChanged: settings.setSpeechRate,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiController,
            decoration: const InputDecoration(
              labelText: 'Gemini API Key',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) => settings.setGeminiApiKey(value),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              await settings.setGeminiApiKey(_apiController.text);
              if (!context.mounted) return;
              await context.read<TtsService>().speak('تم حفظ الإعدادات');
            },
            child: const Text('حفظ الإعدادات'),
          )
        ],
      ),
    );
  }
}
