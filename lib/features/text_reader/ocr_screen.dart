import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/services/camera_service.dart';
import '../../core/services/gemini_service.dart';
import '../../core/services/tts_service.dart';

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});
  static const routeName = '/ocr';

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  final _latinRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  Timer? _timer;
  String _lastText = 'اضغط تحليل النص لبدء القراءة.';

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
    _latinRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = context.watch<CameraService>();
    return Scaffold(
      appBar: AppBar(title: const Text('قراءة النصوص')),
      body: Column(
        children: [
          Expanded(
            child: camera.isInitialized
                ? CameraPreview(camera.controller!)
                : const Center(child: CircularProgressIndicator()),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_lastText),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton(
              onPressed: _scan,
              child: const Text('تحليل النص الآن'),
            ),
          ),
        ],
      ),
    );
  }
}
