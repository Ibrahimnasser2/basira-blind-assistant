import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/demo/demo_mode.dart';
import '../../core/services/camera_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/feature_scaffold.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});
  static const routeName = '/currency';

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  Interpreter? _interpreter;
  Timer? _timer;

  bool _isRunning = false;
  bool _busy = false;
  String _status = 'جاري تحميل نموذج العملة...';
  String _lastAnnounced = '';

  List<int> _inputShape = const [1, 640, 640, 3];
  List<int> _outputShape = const [1, 16, 8400];

  // Map classes from trained model to denomination label.
  static const Map<int, String> _classToDenomination = {
    10: '5 EGP',
    1: '5 EGP',
    0: '10 EGP',
    3: '10 EGP',
    9: '20 EGP',
    5: '20 EGP',
    8: '50 EGP',
    2: '50 EGP',
    4: '100 EGP',
    11: '100 EGP',
    6: '200 EGP',
    7: '200 EGP',
  };

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (kDemoMode) {
      _status = 'تم تحميل النموذج. وجّه الكاميرا نحو العملة.';
      return _startDemo();
    }
    final cameraService = context.read<CameraService>();
    await Permission.camera.request();
    await cameraService.initialize();
    await _loadModel();

    if (!mounted) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _runInferenceNow());
    setState(() {});
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(AppConstants.currencyModelAsset);
      _inputShape = _interpreter!.getInputTensor(0).shape;
      _outputShape = _interpreter!.getOutputTensor(0).shape;
      _status = 'تم تحميل النموذج. وجّه الكاميرا نحو العملة.';
    } catch (_) {
      _status = 'تعذر تحميل نموذج العملة. تأكد من وجود assets/models/egp_currency.tflite';
    }
    if (mounted) setState(() {});
  }

  Future<void> _runInferenceNow() async {
    if (_isRunning || _interpreter == null) return;
    _isRunning = true;

    try {
      final cameraService = context.read<CameraService>();
      final tts = context.read<TtsService>();

      final shot = await cameraService.takePicture();
      if (shot == null) return;

      final file = File(shot.path);
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return;

      final inputH = _inputShape.length > 2 ? _inputShape[1] : 640;
      final inputW = _inputShape.length > 2 ? _inputShape[2] : 640;
      final resized = img.copyResize(decoded, width: inputW, height: inputH);

      final input = List.generate(
        1,
        (_) => List.generate(
          inputH,
          (y) => List.generate(inputW, (x) {
            final p = resized.getPixel(x, y);
            return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
          }),
        ),
      );

      final channels = _outputShape[1];
      final candidates = _outputShape[2];
      final output = List.generate(
        1,
        (_) => List.generate(
          channels,
          (_) => List.filled(candidates, 0.0),
        ),
      );

      _interpreter!.run(input, output);

      final result = _bestPrediction(output[0]);
      final classId = result.$1;
      final confidence = result.$2;

      if (classId == null || confidence < 0.45) {
        _status = 'لم يتم التعرف على فئة العملة بوضوح. قرّب الورقة أكثر.';
        if (mounted) setState(() {});
        return;
      }

      final label = _classToDenomination[classId] ?? 'فئة غير مدعومة';
      final message = 'تم التعرف على $label بنسبة ${(confidence * 100).toStringAsFixed(0)} بالمئة';
      _status = message;
      if (mounted) setState(() {});

      if (label != _lastAnnounced) {
        _lastAnnounced = label;
        await tts.speak(message);
      }

      try {
        await file.delete();
      } catch (_) {}
    } finally {
      _isRunning = false;
    }
  }

  (int?, double) _bestPrediction(List<List<double>> tensor) {
    // YOLOv8 detect head: [4 bbox + N class scores, candidates]
    if (tensor.length <= 4) return (null, 0);

    final numClasses = tensor.length - 4;
    final candidates = tensor[0].length;

    int? bestClass;
    double bestScore = 0.0;

    for (var i = 0; i < candidates; i++) {
      for (var c = 0; c < numClasses; c++) {
        final raw = tensor[c + 4][i];
        final score = _sigmoidIfNeeded(raw);
        if (score > bestScore) {
          bestScore = score;
          bestClass = c;
        }
      }
    }

    return (bestClass, bestScore);
  }

  double _sigmoidIfNeeded(double v) {
    if (v >= 0.0 && v <= 1.0) return v;
    return 1.0 / (1.0 + math.exp(-v));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _startDemo() => runDemoScript(
        const ['تم التعرف على 100 جنيه مصري بنسبة 97 بالمئة'],
        isMounted: () => mounted,
        onBusy: (busy) => setState(() => _busy = busy),
        onResult: (result) => setState(() {
          _status = result;
          _lastAnnounced = '100 EGP';
        }),
        analyzing: const Duration(milliseconds: 2400),
      );

  @override
  Widget build(BuildContext context) {
    final camera = context.watch<CameraService>();
    return FeatureScaffold(
      route: CurrencyScreen.routeName,
      camera: camera.controller,
      demoImage: DemoAssets.currency,
      result: _status,
      busy: _busy,
      actionLabel: 'تحليل فوري',
      actionIcon: Icons.document_scanner_rounded,
      onAction: kDemoMode ? _startDemo : _runInferenceNow,
      extra: _DenominationStrip(detected: _busy ? '' : _lastAnnounced),
    );
  }
}

class _DenominationStrip extends StatelessWidget {
  const _DenominationStrip({required this.detected});

  final String detected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final label in AppConstants.egpLabels)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: label == detected ? AppColors.success.withValues(alpha: 0.18) : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: label == detected ? AppColors.success : AppColors.border,
                    width: label == detected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      label.split(' ').first,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: label == detected ? AppColors.success : AppColors.textPrimary,
                      ),
                    ),
                    const Text('جنيه', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
