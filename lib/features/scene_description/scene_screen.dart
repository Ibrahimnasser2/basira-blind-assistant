import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/gemini_service.dart';
import '../../core/services/tts_service.dart';

class SceneScreen extends StatefulWidget {
  const SceneScreen({super.key});
  static const routeName = '/scene';

  @override
  State<SceneScreen> createState() => _SceneScreenState();
}

class _SceneScreenState extends State<SceneScreen> {
  Timer? _timer;
  bool _isRunning = false;
  String _status = 'جاري تهيئة الكاميرا...';
  String _lastSpoken = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = context.watch<CameraService>();
    return Scaffold(
      appBar: AppBar(title: const Text('وصف المشهد')),
      body: Column(
        children: [
          Expanded(
            child: camera.isInitialized
                ? CameraPreview(camera.controller!)
                : const Center(child: CircularProgressIndicator()),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_status),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton(
              onPressed: _describeNow,
              child: const Text('وصف فوري'),
            ),
          ),
        ],
      ),
    );
  }
}
