import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/demo/demo_mode.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/gemini_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/widgets/feature_scaffold.dart';

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});
  static const routeName = '/ocr';

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  final _latinRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  Timer? _timer;
  bool _busy = false;
  String _lastText = 'اضغط تحليل النص لبدء القراءة.';

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
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _scan());
    setState(() {});
  }

  Future<void> _scan() async {
    final cam = context.read<CameraService>();
    final gemini = context.read<GeminiService>();
    final tts = context.read<TtsService>();
    final shot = await cam.takePicture();
    if (shot == null) return;
    final file = File(shot.path);
    try {
      final input = InputImage.fromFilePath(shot.path);
      final latinResult = await _latinRecognizer.processImage(input);
      final latinText = latinResult.text.trim();

      if (latinText.isNotEmpty) {
        _lastText = latinText.split('\n').take(3).join(' ');
      } else {
        final geminiText = await gemini.extractTextFromImage(file);
        _lastText = geminiText.split('\n').take(3).join(' ');
      }

      if (!mounted) return;
      setState(() {});
      await tts.speak(_lastText);
    } finally {
      try {
        await file.delete();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (!kDemoMode) _latinRecognizer.close();
    super.dispose();
  }

  Future<void> _startDemo() => runDemoScript(
        const [
          'PARACETAMOL 500 mg',
          'PARACETAMOL 500 mg. Take 1 tablet every 6 hours. 10 Tablets.',
        ],
        isMounted: () => mounted,
        onBusy: (busy) => setState(() => _busy = busy),
        onResult: (result) => setState(() => _lastText = result),
      );

  @override
  Widget build(BuildContext context) {
    final camera = context.watch<CameraService>();
    return FeatureScaffold(
      route: OcrScreen.routeName,
      camera: camera.controller,
      demoImage: DemoAssets.text,
      result: _lastText,
      busy: _busy,
      actionLabel: 'تحليل النص الآن',
      actionIcon: Icons.text_snippet_rounded,
      onAction: kDemoMode ? _startDemo : _scan,
    );
  }
}
