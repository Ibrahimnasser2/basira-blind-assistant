import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/services/haptic_service.dart';
import '../../core/services/tts_service.dart';
import '../color_detection/color_screen.dart';
import '../currency_detection/currency_screen.dart';
import '../face_recognition/face_screen.dart';
import '../object_detection/object_screen.dart';
import '../product_scanner/barcode_screen.dart';
import '../navigation_assistant/navigation_screen.dart';
import '../scene_description/scene_screen.dart';
import '../settings/settings_screen.dart';
import '../text_reader/ocr_screen.dart';
import '../time_location/time_location_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final HapticService _haptic = HapticService();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TtsService>().speak('مرحباً بك في بصيرة. انقر على أي زر للبدء');
    });
  }

  Future<void> _go(BuildContext context, String route, String name) async {
    final tts = context.read<TtsService>();
    await _haptic.tap();
    await tts.speak(name);
    if (!context.mounted) return;
    await Navigator.pushNamed(context, route);
  }

  Future<void> _speakDesc(String desc) async {
    final tts = context.read<TtsService>();
    await _haptic.tap();
    await tts.speak(desc);
  }

  Future<void> _listenForCommand() async {
    final tts = context.read<TtsService>();
    final enabled = await _speech.initialize();
    if (!enabled) {
      await tts.speak('تعذر تفعيل الأوامر الصوتية الآن.');
      return;
    }

    setState(() => _isListening = true);
    await _speech.listen(
      localeId: 'ar_EG',
      onResult: (result) async {
        final words = result.recognizedWords.toLowerCase();
        if (words.isEmpty) return;

        final commands = <({String keyword, String route, String label})>[
          (keyword: 'مشهد', route: SceneScreen.routeName, label: 'وصف المشهد'),
          (keyword: 'عملة', route: CurrencyScreen.routeName, label: 'تعرف على العملة'),
          (keyword: 'نص', route: OcrScreen.routeName, label: 'قراءة النصوص'),
          (keyword: 'اشياء', route: ObjectScreen.routeName, label: 'اكتشاف الأشياء'),
          (keyword: 'وجوه', route: FaceScreen.routeName, label: 'اكتشاف الوجوه'),
          (keyword: 'الوان', route: ColorScreen.routeName, label: 'تعرف على الألوان'),
          (keyword: 'باركود', route: BarcodeScreen.routeName, label: 'مسح الباركود'),
          (keyword: 'سير', route: NavigationScreen.routeName, label: 'مساعد السير'),
          (keyword: 'تنقل', route: NavigationScreen.routeName, label: 'مساعد السير'),
          (keyword: 'وقت', route: TimeLocationScreen.routeName, label: 'الوقت والمكان'),
          (keyword: 'تاريخ', route: TimeLocationScreen.routeName, label: 'الوقت والمكان'),
          (keyword: 'مكان', route: TimeLocationScreen.routeName, label: 'الوقت والمكان'),
          (keyword: 'اعدادات', route: SettingsScreen.routeName, label: 'الإعدادات'),
        ];

        for (final entry in commands) {
          if (words.contains(entry.keyword)) {
            await tts.speak('فتح ${entry.label}');
            if (!mounted) return;
            Navigator.pushNamed(context, entry.route);
            break;
          }
        }
      },
    );

    await Future<void>.delayed(const Duration(seconds: 4));
    await _speech.stop();
    if (mounted) setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    final buttons = [
      _FeatureButtonData(Icons.photo_camera, 'وصف المشهد', 'Scene', SceneScreen.routeName, 'وصف سريع للمشهد الحالي بالصوت.'),
      _FeatureButtonData(Icons.payments, 'تعرف على العملة', 'Currency', CurrencyScreen.routeName, 'التعرف على فئة العملة المصرية.'),
      _FeatureButtonData(Icons.text_fields, 'قراءة النصوص', 'Text Reader', OcrScreen.routeName, 'قراءة النصوص العربية والإنجليزية.'),
      _FeatureButtonData(Icons.search, 'اكتشاف الأشياء', 'Objects', ObjectScreen.routeName, 'كشف العوائق والأشياء أمامك.'),
      _FeatureButtonData(Icons.face, 'اكتشاف الوجوه', 'Faces', FaceScreen.routeName, 'عدّ الوجوه وإعطاء تنبيه صوتي.'),
      _FeatureButtonData(Icons.palette, 'تعرف على الألوان', 'Colors', ColorScreen.routeName, 'تحديد اللون الغالب في المشهد.'),
      _FeatureButtonData(Icons.qr_code_scanner, 'مسح الباركود', 'Barcode', BarcodeScreen.routeName, 'قراءة الباركود والتعريف بالمنتج.'),
      _FeatureButtonData(Icons.directions_walk, 'مساعد السير', 'Navigation', NavigationScreen.routeName, 'اكتشاف السلالم والحواجز والحائط والمطبات والتنبيه الفوري.'),
      _FeatureButtonData(Icons.access_time, 'الوقت والمكان', 'Time & Place', TimeLocationScreen.routeName, 'معرفة اليوم والساعة والتاريخ والموقع الحالي.'),
      _FeatureButtonData(Icons.settings, 'الإعدادات', 'Settings', SettingsScreen.routeName, 'تغيير اللغة والسرعة وإعدادات الصوت.'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('بصيرة | BASIRA AI')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: buttons.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, i) {
            final b = buttons[i];
            return Semantics(
              label: b.arLabel,
              button: true,
              child: ElevatedButton(
                onPressed: () => _go(context, b.route, b.arLabel),
                onLongPress: () => _speakDesc(b.description),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(b.icon, size: 38),
                    const SizedBox(height: 8),
                    Text(b.arLabel, textAlign: TextAlign.center),
                    const SizedBox(height: 2),
                    Text(b.enLabel, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _listenForCommand,
        icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
        label: Text(_isListening ? 'استماع...' : 'أمر صوتي'),
      ),
    );
  }
}

class _FeatureButtonData {
  const _FeatureButtonData(this.icon, this.arLabel, this.enLabel, this.route, this.description);

  final IconData icon;
  final String arLabel;
  final String enLabel;
  final String route;
  final String description;
}
