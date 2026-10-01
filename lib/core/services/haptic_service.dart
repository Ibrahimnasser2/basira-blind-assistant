import 'package:vibration/vibration.dart';

import '../demo/demo_mode.dart';

class HapticService {
  Future<void> tap() => _vibrate(() => Vibration.vibrate(duration: 40));

  Future<void> success() => _vibrate(() => Vibration.vibrate(pattern: [0, 60, 40, 80]));

  Future<void> _vibrate(Future<void> Function() action) async {
    if (kDemoMode) return;
    try {
      if (await Vibration.hasVibrator()) await action();
    } catch (_) {}
  }
}
