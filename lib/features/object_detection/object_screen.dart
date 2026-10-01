import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:translator/translator.dart';

import '../../core/demo/demo_mode.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/widgets/feature_scaffold.dart';

class ObjectScreen extends StatefulWidget {
  const ObjectScreen({super.key});
  static const routeName = '/objects';

  @override
  State<ObjectScreen> createState() => _ObjectScreenState();
}

class _ObjectScreenState extends State<ObjectScreen> {
  late final ObjectDetector _detector;
  late final ImageLabeler _labeler;
  final GoogleTranslator _translator = GoogleTranslator();
  final Map<String, String> _translationCache = {};
  Timer? _timer;
  bool _busy = false;
  String _status = 'سيبدأ اكتشاف الأشياء تلقائياً.';
  String _lastAnnouncedStatus = '';

  @override
  void initState() {
    super.initState();
    _detector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: true,
      ),
    );
    _labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.55),
    );
    _init();
  }

  Future<void> _init() async {
    if (kDemoMode) return _startDemo();
    final cameraService = context.read<CameraService>();
    await Permission.camera.request();
    await cameraService.initialize();
    if (!mounted) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _detect());
    setState(() {});
  }

  Future<void> _detect() async {
    final isArabic = context.read<SettingsService>().languageCode == 'ar';
    final shot = await context.read<CameraService>().takePicture();
    if (shot == null) return;
    final input = InputImage.fromFilePath(shot.path);
    final objects = await _detector.processImage(input);
    if (objects.isEmpty) {
      final fallback = await _detectByImageLabels(input, isArabic: isArabic);
      if (fallback == null) return;
      _status = 'تم اكتشاف $fallback';
      if (!mounted) return;
      setState(() {});
      if (_status != _lastAnnouncedStatus) {
        _lastAnnouncedStatus = _status;
        await context.read<TtsService>().speak(_status);
      }
      return;
    }

    final names = <String>[];
    for (final object in objects.take(3)) {
      final name = await _bestObjectName(object, input, isArabic: isArabic);
      names.add(name);
    }
    if (names.isEmpty) return;

    _status = 'تم اكتشاف ${names.join('، ')}';
    if (!mounted) return;
    setState(() {});
    if (_status != _lastAnnouncedStatus) {
      _lastAnnouncedStatus = _status;
      await context.read<TtsService>().speak(_status);
    }
  }

  Future<String> _bestObjectName(
    DetectedObject object,
    InputImage image, {
    required bool isArabic,
  }) async {
    if (object.labels.isNotEmpty) {
      final raw = object.labels.first.text.trim().toLowerCase();
      return _translateName(raw, object.labels.first.text, isArabic: isArabic);
    }

    // Fallback: use general image labeling when object detector has no class.
    final labels = await _labeler.processImage(image);
    if (labels.isNotEmpty) {
      final raw = labels.first.label.trim().toLowerCase();
      return _translateName(raw, labels.first.label, isArabic: isArabic);
    }
    return 'عائق أمامك';
  }

  Future<String?> _detectByImageLabels(
    InputImage image, {
    required bool isArabic,
  }) async {
    final labels = await _labeler.processImage(image);
    if (labels.isEmpty) return null;
    final raw = labels.first.label.trim().toLowerCase();
    return _translateName(raw, labels.first.label, isArabic: isArabic);
  }

  Future<String> _translateName(
    String raw,
    String fallback, {
    required bool isArabic,
  }) async {
    if (!isArabic) return fallback;

    const translations = <String, String>{
      'person': 'شخص',
      'human': 'إنسان',
      'face': 'وجه',
      'man': 'رجل',
      'woman': 'امرأة',
      'child': 'طفل',
      'car': 'سيارة',
      'bus': 'حافلة',
      'truck': 'شاحنة',
      'train': 'قطار',
      'airplane': 'طائرة',
      'motor': 'دراجة نارية',
      'motorbike': 'دراجة نارية',
      'bicycle': 'دراجة',
      'motorcycle': 'دراجة نارية',
      'chair': 'كرسي',
      'table': 'طاولة',
      'desk': 'مكتب',
      'laptop': 'حاسوب محمول',
      'computer': 'حاسوب',
      'mobile phone': 'هاتف',
      'phone': 'هاتف',
      'cell phone': 'هاتف',
      'bottle': 'زجاجة',
      'cup': 'كوب',
      'glass': 'كوب',
      'book': 'كتاب',
      'pen': 'قلم',
      'pencil': 'قلم',
      'door': 'باب',
      'window': 'نافذة',
      'wall': 'حائط',
      'stairs': 'درج',
      'step': 'درجة',
      'floor': 'أرضية',
      'road': 'طريق',
      'sidewalk': 'رصيف',
      'bag': 'حقيبة',
      'backpack': 'حقيبة ظهر',
      'handbag': 'حقيبة يد',
      'suitcase': 'حقيبة سفر',
      'shoe': 'حذاء',
      'hat': 'قبعة',
      'traffic light': 'إشارة مرور',
      'stop sign': 'علامة توقف',
      'tree': 'شجرة',
      'plant': 'نبات',
      'dog': 'كلب',
      'cat': 'قطة',
      'food': 'طعام',
    };

    final normalized = raw.trim().toLowerCase();
    if (translations.containsKey(normalized)) {
      return translations[normalized]!;
    }

    for (final entry in translations.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        return entry.value;
      }
    }

    final fallbackNormalized = fallback.trim().toLowerCase();
    for (final entry in translations.entries) {
      if (fallbackNormalized.contains(entry.key)) {
        return entry.value;
      }
    }

    // Dynamic translation fallback via Gemini (cached per label).
    final cached = _translationCache[fallbackNormalized];
    if (cached != null && cached.isNotEmpty) return cached;

    final translated = await _translateUnknownLabelWithLibrary(fallbackNormalized);
    if (translated != null && translated.isNotEmpty) {
      _translationCache[fallbackNormalized] = translated;
      return translated;
    }

    // Last fallback: keep original label if translation service unavailable.
    return fallback;
  }

  Future<String?> _translateUnknownLabelWithLibrary(String englishLabel) async {
    try {
      final translated = await _translator.translate(
        englishLabel,
        from: 'en',
        to: 'ar',
      );
      final text = translated.text.trim();
      if (text.isEmpty) return null;
      return text.replaceAll('\n', ' ').replaceAll('"', '').trim();
    } catch (_) {
      return null;
    }
  }

  Future<void> _startDemo() => runDemoScript(
        const [
          'تم اكتشاف حاسوب محمول، كوب، زجاجة',
          'تم اكتشاف كرسي، طاولة، نبات',
        ],
        isMounted: () => mounted,
        onBusy: (busy) => setState(() => _busy = busy),
        onResult: (result) => setState(() => _status = result),
      );

  @override
  void dispose() {
    _timer?.cancel();
    if (!kDemoMode) {
      _detector.close();
      _labeler.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = context.watch<CameraService>();
    return FeatureScaffold(
      route: ObjectScreen.routeName,
      camera: camera.controller,
      demoImage: DemoAssets.objects,
      result: _status,
      busy: _busy,
      actionLabel: 'اكتشاف فوري',
      actionIcon: Icons.center_focus_strong_rounded,
      onAction: kDemoMode ? _startDemo : _detect,
    );
  }
}
