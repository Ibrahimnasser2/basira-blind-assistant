import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/demo/demo_mode.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/widgets/feature_scaffold.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});
  static const routeName = '/navigation';

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  late final ObjectDetector _objectDetector;
  late final ImageLabeler _imageLabeler;
  final HapticService _haptic = HapticService();

  Timer? _timer;
  bool _isRunning = false;
  bool _busy = false;
  String _status = 'جاري تهيئة مساعد السير...';
  String _lastAlert = '';
  DateTime _lastAlertAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _objectDetector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: true,
      ),
    );
    _imageLabeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.55));
    _init();
  }

  Future<void> _init() async {
    if (kDemoMode) {
      _status = 'تم تشغيل مساعد السير. سيتم الفحص تلقائياً.';
      return _startDemo();
    }
    final cameraService = context.read<CameraService>();
    await Permission.camera.request();
    await cameraService.initialize();
    if (!mounted) return;

    _status = 'تم تشغيل مساعد السير. سيتم الفحص تلقائياً.';
    setState(() {});

    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _analyzeFrame());
    await _analyzeFrame();
  }

  Future<void> _analyzeFrame() async {
    if (_isRunning) return;
    _isRunning = true;

    try {
      final shot = await context.read<CameraService>().takePicture();
      if (shot == null) return;

      final input = InputImage.fromFilePath(shot.path);
      final objects = await _objectDetector.processImage(input);
      final labels = await _imageLabeler.processImage(input);

      final detection = _detectRisk(objects, labels);
      _status = detection?.message ?? 'المسار يبدو آمنًا الآن.';
      if (mounted) setState(() {});

      if (detection != null) {
        await _announceRisk(detection.message);
      }
    } finally {
      _isRunning = false;
    }
  }

  _RiskDetection? _detectRisk(List<DetectedObject> objects, List<ImageLabel> labels) {
    final words = <String>{};

    for (final object in objects) {
      for (final label in object.labels) {
        words.add(label.text.toLowerCase());
      }
    }
    for (final label in labels) {
      words.add(label.label.toLowerCase());
    }

    bool hasAny(List<String> keys) {
      for (final key in keys) {
        for (final word in words) {
          if (word == key || word.contains(key) || key.contains(word)) {
            return true;
          }
        }
      }
      return false;
    }

    final largeCenterObstacle = objects.any((o) {
      final width = (o.boundingBox.right - o.boundingBox.left).abs();
      final height = (o.boundingBox.bottom - o.boundingBox.top).abs();
      final area = width * height;
      final centerX = o.boundingBox.left + width / 2;
      final centerY = o.boundingBox.top + height / 2;
      final nearCenter = centerX > 180 && centerX < 460 && centerY > 180 && centerY < 500;
      return area > 90000 && nearCenter;
    });

    if (hasAny(['stairs', 'staircase', 'step', 'steps'])) {
      return const _RiskDetection('تحذير: يوجد سلالم أمامك. تحرك بحذر.');
    }
    if (hasAny(['barrier', 'fence', 'guard rail', 'rail', 'handrail', 'railing'])) {
      return const _RiskDetection('تحذير: يوجد حاجز أمامك.');
    }
    if (hasAny(['wall', 'brick wall', 'concrete wall'])) {
      return const _RiskDetection('تحذير: يوجد حائط قريب أمامك.');
    }
    if (largeCenterObstacle) {
      return const _RiskDetection('.تحذير: يوجد عائق كبير قريب أمامك، قد يكون حائطًااو جسما ما');
    }
    if (hasAny(['speed bump', 'bump', 'road hump', 'curb'])) {
      return const _RiskDetection('تحذير: يوجد مطب أو حافة في الطريق.');
    }

    return null;
  }

  Future<void> _announceRisk(String message) async {
    final tts = context.read<TtsService>();
    final now = DateTime.now();
    final secondsSinceLast = now.difference(_lastAlertAt).inSeconds;

    if (message == _lastAlert && secondsSinceLast < 4) return;

    _lastAlert = message;
    _lastAlertAt = now;

    await _haptic.success();
    await tts.speak(message);
  }

  Future<void> _startDemo() => runDemoScript(
        const [
          'تحذير: يوجد سلالم أمامك. تحرك بحذر.',
          'تحذير: يوجد حاجز على يمينك. يمكنك الاستناد إلى الدرابزين.',
        ],
        isMounted: () => mounted,
        onBusy: (busy) => setState(() => _busy = busy),
        onResult: (result) => setState(() => _status = result),
        analyzing: const Duration(milliseconds: 1400),
      );

  @override
  void dispose() {
    _timer?.cancel();
    if (!kDemoMode) {
      _objectDetector.close();
      _imageLabeler.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = context.watch<CameraService>();
    return FeatureScaffold(
      route: NavigationScreen.routeName,
      camera: camera.controller,
      demoImage: DemoAssets.stairs,
      result: _status,
      busy: _busy,
      alert: _status.startsWith('تحذير'),
      actionLabel: 'فحص فوري',
      actionIcon: Icons.radar_rounded,
      onAction: kDemoMode ? _startDemo : _analyzeFrame,
    );
  }
}

class _RiskDetection {
  const _RiskDetection(this.message);
  final String message;
}
