import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/demo/demo_mode.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/feature_scaffold.dart';

class ColorScreen extends StatefulWidget {
  const ColorScreen({super.key});
  static const routeName = '/colors';

  @override
  State<ColorScreen> createState() => _ColorScreenState();
}

class _ColorScreenState extends State<ColorScreen> {
  Timer? _timer;
  bool _isRunning = false;
  bool _busy = false;
  String _status = 'جاري تهيئة التعرف على الألوان...';
  String _lastSpoken = '';
  Color _previewColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (kDemoMode) {
      _status = 'تم تشغيل التعرف على الألوان. سيتم التحليل كل 3 ثوانٍ.';
      return _startDemo();
    }
    final cameraService = context.read<CameraService>();
    await Permission.camera.request();
    await cameraService.initialize();
    if (!mounted) return;

    _status = 'تم تشغيل التعرف على الألوان. سيتم التحليل كل 3 ثوانٍ.';
    setState(() {});

    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _detectColorNow());
    await _detectColorNow();
  }

  Future<void> _detectColorNow() async {
    if (_isRunning) return;
    _isRunning = true;

    try {
      final shot = await context.read<CameraService>().takePicture();
      if (shot == null) return;

      final bytes = await File(shot.path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return;

      final resized = img.copyResize(decoded, width: 64, height: 64);

      int totalR = 0;
      int totalG = 0;
      int totalB = 0;
      int count = 0;

      for (final p in resized) {
        totalR += p.r.toInt();
        totalG += p.g.toInt();
        totalB += p.b.toInt();
        count++;
      }

      if (count == 0) return;

      final r = (totalR / count).round();
      final g = (totalG / count).round();
      final b = (totalB / count).round();
      final colorName = _toArabicColorName(r, g, b);

      _previewColor = Color.fromARGB(255, r, g, b);
      _status = 'اللون الغالب: $colorName';

      if (!mounted) return;
      setState(() {});

      if (_status != _lastSpoken) {
        _lastSpoken = _status;
        await context.read<TtsService>().speak(_status);
      }

      try {
        await File(shot.path).delete();
      } catch (_) {}
    } finally {
      _isRunning = false;
    }
  }

  String _toArabicColorName(int r, int g, int b) {
    final maxV = [r, g, b].reduce((a, c) => a > c ? a : c);
    final minV = [r, g, b].reduce((a, c) => a < c ? a : c);
    final diff = maxV - minV;

    if (maxV < 40) return 'أسود';
    if (minV > 220) return 'أبيض';
    if (diff < 18) return 'رمادي';

    if (r > 200 && g > 160 && b < 120) return 'أصفر';
    if (r > 180 && g < 100 && b < 100) return 'أحمر';
    if (g > 170 && r < 140 && b < 140) return 'أخضر';
    if (b > 170 && r < 140 && g < 160) return 'أزرق';
    if (r > 150 && b > 150 && g < 120) return 'بنفسجي';
    if (r > 170 && g > 100 && g < 170 && b < 120) return 'برتقالي';

    if (r >= g && r >= b) return 'أحمر';
    if (g >= r && g >= b) return 'أخضر';
    return 'أزرق';
  }

  Future<void> _startDemo() => runDemoScript(
        const ['اللون الغالب: أزرق'],
        isMounted: () => mounted,
        onBusy: (busy) => setState(() => _busy = busy),
        onResult: (result) => setState(() {
          _status = result;
          _previewColor = const Color(0xFF2F62C9);
        }),
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
      route: ColorScreen.routeName,
      camera: camera.controller,
      demoImage: DemoAssets.colors,
      result: _status,
      busy: _busy,
      actionLabel: 'تحليل فوري',
      actionIcon: Icons.colorize_rounded,
      onAction: kDemoMode ? _startDemo : _detectColorNow,
      extra: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 56,
            height: 44,
            decoration: BoxDecoration(
              color: _previewColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 2),
            ),
          ),
          const SizedBox(width: 12),
          const Text('عينة اللون', style: TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(
            '#${_previewColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
            style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700, letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}
