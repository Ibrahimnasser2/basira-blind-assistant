import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/feature_catalog.dart';
import '../../core/demo/demo_mode.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/feature_scaffold.dart';
import '../../core/widgets/voice_close_listener.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  static const routeName = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _apiController;
  bool _showKey = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsService>();
    _apiController = TextEditingController(
      text: kDemoMode && settings.geminiApiKey.isEmpty ? 'demo-key-0000000000000000' : settings.geminiApiKey,
    );
  }

  @override
  void dispose() {
    _apiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final feature = FeatureCatalog.byRoute(SettingsScreen.routeName);
    return VoiceCloseListener(
      child: Scaffold(
        appBar: FeatureAppBar(feature: feature),
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _Section(
                icon: Icons.translate_rounded,
                title: 'اللغة',
                subtitle: 'LANGUAGE',
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    selectedBackgroundColor: AppColors.gold,
                    selectedForegroundColor: const Color(0xFF1A1204),
                    side: const BorderSide(color: AppColors.border),
                    textStyle: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  segments: const [
                    ButtonSegment(value: 'ar', label: Text('العربية')),
                    ButtonSegment(value: 'en', label: Text('English')),
                  ],
                  selected: {settings.languageCode},
                  onSelectionChanged: (value) => settings.setLanguageCode(value.first),
                ),
              ),
              const SizedBox(height: 14),
              _Section(
                icon: Icons.record_voice_over_rounded,
                title: 'سرعة الصوت',
                subtitle: 'SPEECH RATE',
                trailing: Text(
                  settings.speechRate.toStringAsFixed(2),
                  style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 18),
                ),
                child: Column(
                  children: [
                    Slider(value: settings.speechRate, min: 0.2, max: 0.7, onChanged: settings.setSpeechRate),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('بطيء', style: TextStyle(color: AppColors.textMuted)),
                          Text('سريع', style: TextStyle(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _Section(
                icon: Icons.key_rounded,
                title: 'مفتاح الذكاء الاصطناعي',
                subtitle: 'GEMINI API KEY',
                child: TextField(
                  controller: _apiController,
                  obscureText: !_showKey,
                  decoration: InputDecoration(
                    hintText: 'Gemini API Key',
                    prefixIcon: const Icon(Icons.lock_rounded),
                    suffixIcon: IconButton(
                      tooltip: _showKey ? 'إخفاء' : 'إظهار',
                      icon: Icon(_showKey ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                      onPressed: () => setState(() => _showKey = !_showKey),
                    ),
                  ),
                  onSubmitted: (value) => settings.setGeminiApiKey(value),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  await settings.setGeminiApiKey(_apiController.text);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حفظ الإعدادات', style: TextStyle(fontFamily: AppTheme.fontFamily)),
                    ),
                  );
                  await context.read<TtsService>().speak('تم حفظ الإعدادات');
                },
                icon: const Icon(Icons.check_circle_rounded, size: 26),
                label: const Text('حفظ الإعدادات'),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'BASIRA AI  •  v1.0.0',
                  style: TextStyle(color: AppColors.textMuted, letterSpacing: 2, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.subtitle, required this.child, this.trailing});

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(icon: icon, color: AppColors.gold, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.6,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
