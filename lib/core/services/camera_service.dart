import 'dart:async';

import 'package:camera/camera.dart';

class CameraService {
  CameraController? _controller;
  bool _isProcessing = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  bool get isProcessing => _isProcessing;

  Future<void> initialize() async {
    if (_controller != null && _controller!.value.isInitialized) return;
    final cameras = await availableCameras();
    final back = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      back,
      ResolutionPreset.medium,
      imageFormatGroup: ImageFormatGroup.yuv420,
      enableAudio: false,
    );
    await _controller!.initialize();
  }

  Future<XFile?> takePicture() async {
    if (!isInitialized) return null;
    _isProcessing = true;
    try {
      return await _controller!.takePicture();
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}
