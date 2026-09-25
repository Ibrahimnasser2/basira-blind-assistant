import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/services/camera_service.dart';
import '../../core/services/tts_service.dart';

class BarcodeScreen extends StatefulWidget {
  const BarcodeScreen({super.key});
  static const routeName = '/barcode';

  @override
  State<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen> {
  final _scanner = BarcodeScanner();
  String _status = 'جاري المسح التلقائي...';
  Timer? _scanTimer;
  bool _isScanning = false;
  String? _lastCode;

  Future<void> _init() async {
    final cameraService = context.read<CameraService>();
    await Permission.camera.request();
    await cameraService.initialize();
    if (!mounted) return;

    _scanTimer = Timer.periodic(const Duration(seconds: 2), (_) => _scan());
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _scan() async {
    if (_isScanning) return;
    _isScanning = true;

    try {
      final shot = await context.read<CameraService>().takePicture();
      if (shot == null) return;

      final input = InputImage.fromFilePath(shot.path);
      final result = await _scanner.processImage(input);

      if (result.isEmpty) {
        if (_lastCode == null) {
          _status = 'لم يتم العثور على باركود بعد.';
          if (mounted) setState(() {});
        }
        return;
      }

      final value = result.first.rawValue ?? '';
      if (value.isEmpty || value == _lastCode) return;

      final info = await _lookupProduct(value);
      _status = 'الباركود: $value. $info';
      _lastCode = value;

      if (!mounted) return;
      setState(() {});
      await context.read<TtsService>().speak(_status);
    } finally {
      _isScanning = false;
    }
  }

  Future<String> _lookupProduct(String code) async {
    final uri = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$code.json');
    final response = await http.get(uri);
    if (response.statusCode != 200) return 'تعذر جلب معلومات المنتج.';

    final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
    final product = jsonMap['product'] as Map<String, dynamic>?;
    final name = product?['product_name'] as String?;
    return (name == null || name.isEmpty) ? 'لا يوجد اسم منتج متاح.' : 'المنتج: $name';
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _scanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = context.watch<CameraService>();
    return Scaffold(
      appBar: AppBar(title: const Text('مسح الباركود')),
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
              onPressed: _scan,
              child: const Text('مسح فوري'),
            ),
          ),
        ],
      ),
    );
  }
}
