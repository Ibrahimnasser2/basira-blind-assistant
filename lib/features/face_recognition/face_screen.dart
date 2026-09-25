import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/services/camera_service.dart';
import '../../core/services/tts_service.dart';

class FaceScreen extends StatefulWidget {
  const FaceScreen({super.key});
  static const routeName = '/faces';

  @override
  State<FaceScreen> createState() => _FaceScreenState();
}

class _FaceScreenState extends State<FaceScreen> {
  late final FaceDetector _detector;
  Timer? _timer;
  String _status = 'سيتم عدّ الوجوه تلقائياً.';
  bool _announcedNoFaces = false;

  @override
  void initState() {
    super.initState();
    _detector = FaceDetector(
      options: FaceDetectorOptions(enableContours: false, enableClassification: false),
    );
    _init();
  }

  Future<void> _init() async {
    final cameraService = context.read<CameraService>();
    await Permission.camera.request();
    await cameraService.initialize();
    if (!mounted) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _detect());
    setState(() {});
  }

  Future<void> _detect() async {
    final shot = await context.read<CameraService>().takePicture();
    if (shot == null) return;
    final input = InputImage.fromFilePath(shot.path);
    final faces = await _detector.processImage(input);
    final hasFaces = faces.isNotEmpty;
    _status = hasFaces ? 'عدد الوجوه: ${faces.length}' : 'لا توجد وجوه حالياً.';
    if (!mounted) return;
    setState(() {});
    if (!hasFaces) {
      if (_announcedNoFaces) return;
      _announcedNoFaces = true;
      await context.read<TtsService>().speak(_status);
      return;
    }

    _announcedNoFaces = false;
    await context.read<TtsService>().speak(_status);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _detector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = context.watch<CameraService>();
    return Scaffold(
      appBar: AppBar(title: const Text('اكتشاف الوجوه')),
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
        ],
      ),
    );
  }
}
