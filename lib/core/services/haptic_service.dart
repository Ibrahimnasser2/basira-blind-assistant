import 'package:vibration/vibration.dart';

class HapticService {
  Future<void> tap() async {
    if (await Vibration.hasVibrator()) {
      await Vibration.vibrate(duration: 40);
    }
  }

  Future<void> success() async {
    if (await Vibration.hasVibrator()) {
      await Vibration.vibrate(pattern: [0, 60, 40, 80]);
    }
  }
}
