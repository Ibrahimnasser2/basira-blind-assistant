import 'package:flutter/material.dart';

import '../../features/color_detection/color_screen.dart';
import '../../features/currency_detection/currency_screen.dart';
import '../../features/face_recognition/face_screen.dart';
import '../../features/navigation_assistant/navigation_screen.dart';
import '../../features/object_detection/object_screen.dart';
import '../../features/product_scanner/barcode_screen.dart';
import '../../features/scene_description/scene_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/text_reader/ocr_screen.dart';
import '../../features/time_location/time_location_screen.dart';

class FeatureInfo {
  const FeatureInfo({
    required this.icon,
    required this.arLabel,
    required this.enLabel,
    required this.route,
    required this.description,
    required this.enDescription,
    required this.accent,
  });

  final IconData icon;
  final String arLabel;
  final String enLabel;
  final String route;
  final String description;
  final String enDescription;
  final Color accent;
}

class FeatureCatalog {
  static const all = <FeatureInfo>[
    FeatureInfo(
      icon: Icons.camera_alt_rounded,
      arLabel: 'وصف المشهد',
      enLabel: 'Scene Description',
      route: SceneScreen.routeName,
      description: 'وصف سريع للمشهد الحالي بالصوت.',
      enDescription: 'AI describes the surroundings aloud.',
      accent: Color(0xFF5AB8FF),
    ),
    FeatureInfo(
      icon: Icons.payments_rounded,
      arLabel: 'تعرف على العملة',
      enLabel: 'Currency Recognition',
      route: CurrencyScreen.routeName,
      description: 'التعرف على فئة العملة المصرية.',
      enDescription: 'Identifies Egyptian banknotes on-device.',
      accent: Color(0xFF3DDC97),
    ),
    FeatureInfo(
      icon: Icons.menu_book_rounded,
      arLabel: 'قراءة النصوص',
      enLabel: 'Text Reader',
      route: OcrScreen.routeName,
      description: 'قراءة النصوص العربية والإنجليزية.',
      enDescription: 'Reads Arabic and English text aloud.',
      accent: Color(0xFFE0B04B),
    ),
    FeatureInfo(
      icon: Icons.center_focus_strong_rounded,
      arLabel: 'اكتشاف الأشياء',
      enLabel: 'Object Detection',
      route: ObjectScreen.routeName,
      description: 'كشف العوائق والأشياء أمامك.',
      enDescription: 'Names the objects in front of you.',
      accent: Color(0xFFFF9F5A),
    ),
    FeatureInfo(
      icon: Icons.face_retouching_natural_rounded,
      arLabel: 'اكتشاف الوجوه',
      enLabel: 'Face Detection',
      route: FaceScreen.routeName,
      description: 'عدّ الوجوه وإعطاء تنبيه صوتي.',
      enDescription: 'Counts the people facing you.',
      accent: Color(0xFFC792EA),
    ),
    FeatureInfo(
      icon: Icons.palette_rounded,
      arLabel: 'تعرف على الألوان',
      enLabel: 'Color Recognition',
      route: ColorScreen.routeName,
      description: 'تحديد اللون الغالب في المشهد.',
      enDescription: 'Tells the dominant color in view.',
      accent: Color(0xFFFF6B9A),
    ),
    FeatureInfo(
      icon: Icons.qr_code_scanner_rounded,
      arLabel: 'مسح الباركود',
      enLabel: 'Barcode Scanner',
      route: BarcodeScreen.routeName,
      description: 'قراءة الباركود والتعريف بالمنتج.',
      enDescription: 'Scans products and reads their names.',
      accent: Color(0xFF4FD1C5),
    ),
    FeatureInfo(
      icon: Icons.directions_walk_rounded,
      arLabel: 'مساعد السير',
      enLabel: 'Walking Assistant',
      route: NavigationScreen.routeName,
      description: 'اكتشاف السلالم والحواجز والحائط والمطبات والتنبيه الفوري.',
      enDescription: 'Warns of stairs, walls and obstacles.',
      accent: Color(0xFFFF6B6B),
    ),
    FeatureInfo(
      icon: Icons.schedule_rounded,
      arLabel: 'الوقت والمكان',
      enLabel: 'Time & Location',
      route: TimeLocationScreen.routeName,
      description: 'معرفة اليوم والساعة والتاريخ والموقع الحالي.',
      enDescription: 'Speaks the day, date, time and place.',
      accent: Color(0xFF8FA8FF),
    ),
    FeatureInfo(
      icon: Icons.tune_rounded,
      arLabel: 'الإعدادات',
      enLabel: 'Settings',
      route: SettingsScreen.routeName,
      description: 'تغيير اللغة والسرعة وإعدادات الصوت.',
      enDescription: 'Language, speech speed and AI key.',
      accent: Color(0xFF9AA7BD),
    ),
  ];

  static FeatureInfo byRoute(String route) => all.firstWhere((f) => f.route == route);
}
