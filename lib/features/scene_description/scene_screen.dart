import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/demo/demo_mode.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/gemini_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/widgets/feature_scaffold.dart';

class SceneScreen extends StatefulWidget {
  const SceneScreen({super.key});
  static const routeName = '/scene';

  @override
  State<SceneScreen> createState() => _SceneScreenState();
}

class _SceneScreenState extends State<SceneScreen> {
  Timer? _timer;
  bool _isRunning = false;
  bool _busy = false;
  String _status = 'جاري تهيئة الكاميرا...';
  String _lastSpoken = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (kDemoMode) return _startDemo();
    final cameraService = context.read<CameraService>();
    await Permission.camera.request();
    await cameraService.initialize();
    if (!mounted) return;

    _status = 'تم تشغيل وصف المشهد. سيتم التحليل كل 4 ثوانٍ.';
    setState(() {});

    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _describeNow());
    await _describeNow();
  }

  Future<void> _describeNow() async {
    if (_isRunning) return;
    _isRunning = true;

    try {
      final cameraService = context.read<CameraService>();
      final gemini = context.read<GeminiService>();
      final tts = context.read<TtsService>();

      final shot = await cameraService.takePicture();
      if (shot == null) return;

      final file = File(shot.path);
      final response = await gemini.describeImage(file, AppConstants.scenePromptAr);

      if (!mounted) return;
      _status = response;
      setState(() {});

      if (response != _lastSpoken) {
        _lastSpoken = response;
        await tts.speak(response);
      }

      try {
        await file.delete();
      } catch (_) {}
    } finally {
      _isRunning = false;
    }
  }

  Future<void> _startDemo() => runDemoScript(
        const [
          'أمامك رصيف مشاة واسع. على يمينك مقعد خشبي، وعلى يسارك مقهى. المسار آمن.',
          'يسير شخصان أمامك، وتوجد سيارة متوقفة على اليمين.',
        ],
        isMounted: () => mounted,
        onBusy: (busy) => setState(() => _busy = busy),
        onResult: (result) => setState(() => _status = result),
      );

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = context.watch<CameraService>();
    return FeatureScaffold(
      route: SceneScreen.routeName,
      camera: camera.controller,
      demoImage: DemoAssets.scene,
      result: _status,
      busy: _busy,
      actionLabel: 'وصف فوري',
      actionIcon: Icons.auto_awesome_rounded,
      onAction: kDemoMode ? _startDemo : _describeNow,
    );
  }
}
