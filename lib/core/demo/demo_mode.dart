/// Build with `--dart-define=DEMO_MODE=true` to replace the live camera and
/// AI services with sample images and scripted results (for presentations).
/// `--dart-define=DEMO_TOUR=true` additionally runs the automated video tour.
const bool kDemoTour = bool.fromEnvironment('DEMO_TOUR');
const bool kDemoMode = kDemoTour || bool.fromEnvironment('DEMO_MODE');

class DemoAssets {
  static const scene = 'assets/demo/demo_scene.jpg';
  static const currency = 'assets/demo/demo_currency.jpg';
  static const text = 'assets/demo/demo_text.jpg';
  static const objects = 'assets/demo/demo_objects.jpg';
  static const faces = 'assets/demo/demo_faces.jpg';
  static const colors = 'assets/demo/demo_colors.jpg';
  static const barcode = 'assets/demo/demo_barcode.jpg';
  static const stairs = 'assets/demo/demo_stairs.jpg';
}

/// Plays scripted results: each one is preceded by [analyzing] of busy state
/// and stays on screen for [hold] before the next one starts.
Future<void> runDemoScript(
  List<String> results, {
  required bool Function() isMounted,
  required void Function(bool busy) onBusy,
  required void Function(String result) onResult,
  Duration initialDelay = const Duration(milliseconds: 1200),
  Duration analyzing = const Duration(milliseconds: 1800),
  Duration hold = const Duration(milliseconds: 4200),
}) async {
  await Future<void>.delayed(initialDelay);
  for (var i = 0; i < results.length; i++) {
    if (!isMounted()) return;
    onBusy(true);
    await Future<void>.delayed(analyzing);
    if (!isMounted()) return;
    onBusy(false);
    onResult(results[i]);
    if (i < results.length - 1) await Future<void>.delayed(hold);
  }
}
