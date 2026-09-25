import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/camera_service.dart';
import 'core/services/gemini_service.dart';
import 'core/services/tts_service.dart';
import 'core/services/settings_service.dart';
import 'core/theme/app_theme.dart';
import 'features/currency_detection/currency_screen.dart';
import 'features/face_recognition/face_screen.dart';
import 'features/home/home_screen.dart';
import 'features/light_detector/light_screen.dart';
import 'features/navigation_assistant/navigation_screen.dart';
import 'features/object_detection/object_screen.dart';
import 'features/product_scanner/barcode_screen.dart';
import 'features/scene_description/scene_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/text_reader/ocr_screen.dart';
import 'features/color_detection/color_screen.dart';
import 'features/time_location/time_location_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsService();
  await settings.load();
  runApp(BasiraApp(settings: settings));
}

class BasiraApp extends StatelessWidget {
  const BasiraApp({required this.settings, super.key});
  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsService>.value(value: settings),
        Provider<TtsService>(create: (_) => TtsService(settings)),
        Provider<CameraService>(create: (_) => CameraService()),
        Provider<GeminiService>(create: (_) => GeminiService(settings)),
      ],
      child: Consumer<SettingsService>(
        builder: (context, appSettings, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'BASIRA AI',
            theme: AppTheme.darkTheme,
            locale: Locale(appSettings.languageCode),
            home: const HomeScreen(),
            routes: {
              SceneScreen.routeName: (_) => const SceneScreen(),
              CurrencyScreen.routeName: (_) => const CurrencyScreen(),
              OcrScreen.routeName: (_) => const OcrScreen(),
              ObjectScreen.routeName: (_) => const ObjectScreen(),
              FaceScreen.routeName: (_) => const FaceScreen(),
              ColorScreen.routeName: (_) => const ColorScreen(),
              BarcodeScreen.routeName: (_) => const BarcodeScreen(),
              NavigationScreen.routeName: (_) => const NavigationScreen(),
              LightScreen.routeName: (_) => const LightScreen(),
              TimeLocationScreen.routeName: (_) => const TimeLocationScreen(),
              SettingsScreen.routeName: (_) => const SettingsScreen(),
            },
            builder: (context, child) {
              return Directionality(
                textDirection: appSettings.languageCode == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
