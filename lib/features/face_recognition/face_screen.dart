import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/demo/demo_mode.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/feature_scaffold.dart';

class FaceScreen extends StatefulWidget {
  const FaceScreen({super.key});
  static const routeName = '/faces';

  @override
  State<FaceScreen> createState() => _FaceScreenState();
}

class _FaceScreenState extends State<FaceScreen> {
  late final FaceDetector _detector;
  Timer? _timer;
  bool _busy = false;
  int? _faceCount;
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
    if (kDemoMode) return _startDemo();
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
    _faceCount = faces.length;
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

  Future<void> _startDemo() => runDemoScript(
        const ['عدد الوجوه: 2 — شخصان أمامك مباشرة.'],
        isMounted: () => mounted,
        onBusy: (busy) => setState(() => _busy = busy),
        onResult: (result) => setState(() {
          _status = result;
          _faceCount = 2;
        }),
        analyzing: const Duration(milliseconds: 2200),
      );

  @override
  void dispose() {
    _timer?.cancel();
    if (!kDemoMode) _detector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = context.watch<CameraService>();
    return FeatureScaffold(
      route: FaceScreen.routeName,
      camera: camera.controller,
      demoImage: DemoAssets.faces,
      result: _status,
      busy: _busy,
      actionLabel: 'عدّ الوجوه الآن',
      actionIcon: Icons.groups_rounded,
      onAction: kDemoMode ? _startDemo : _detect,
      extra: _FaceCounter(count: _busy ? null : _faceCount),
    );
  }
}

class _FaceCounter extends StatelessWidget {
  const _FaceCounter({required this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFC792EA);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups_rounded, color: accent),
          const SizedBox(width: 10),
          const Text('الأشخاص في الإطار', style: TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(
            count?.toString() ?? '—',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: accent),
          ),
        ],
      ),
    );
  }
}
