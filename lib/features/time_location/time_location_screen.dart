import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import '../../core/constants/feature_catalog.dart';
import '../../core/demo/demo_mode.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/feature_scaffold.dart';
import '../../core/widgets/voice_close_listener.dart';

class TimeLocationScreen extends StatefulWidget {
  const TimeLocationScreen({super.key});
  static const routeName = '/time-location';

  @override
  State<TimeLocationScreen> createState() => _TimeLocationScreenState();
}

class _TimeLocationScreenState extends State<TimeLocationScreen> {
  String _dayName = '-';
  String _date = '-';
  String _time = '-';
  String _location = 'جاري جلب الموقع...';

  @override
  void initState() {
    super.initState();
    _refreshInfo();
  }

  Future<void> _refreshInfo() async {
    final tts = context.read<TtsService>();

    final now = kDemoMode ? DateTime(2026, 10, 1, 10, 30) : DateTime.now();
    String dayName;
    String date;
    String time;

    try {
      await initializeDateFormatting('ar');
      dayName = DateFormat('EEEE', 'ar').format(now);
      date = DateFormat('yyyy/MM/dd', 'ar').format(now);
      time = DateFormat('hh:mm a', 'ar').format(now);
    } catch (_) {
      // Fallback keeps the service working even if locale data fails.
      dayName = DateFormat('EEEE').format(now);
      date = DateFormat('yyyy/MM/dd').format(now);
      time = DateFormat('hh:mm a').format(now);
    }

    final locationText = await _getLocationText();

    _dayName = dayName;
    _date = date;
    _time = time;
    _location = locationText;
    if (!mounted) return;
    setState(() {});
    await tts.speak('اليوم $_dayName، التاريخ $_date، الساعة $_time. $_location');
  }

  Future<String> _getLocationText() async {
    if (kDemoMode) return 'موقعك الحالي: مدينة نصر، القاهرة، مصر';
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return 'خدمة الموقع غير مفعلة.';

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return 'صلاحية الموقع غير متاحة.';
    }

    try {
      await setLocaleIdentifier('ar_EG');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final places = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (places.isEmpty) {
        return 'تعذر تحديد اسم المكان، لكن تم تحديد الإحداثيات.';
      }

      final p = places.first;
      // Prefer human-readable area names and avoid street-level/plus-code fragments.
      final parts = [p.subLocality, p.locality, p.administrativeArea, p.country]
          .where((e) => e != null && e.trim().isNotEmpty)
          .map((e) => _sanitizePlacePart(e!.trim()))
          .where((e) => e.isNotEmpty)
          .toList();

      if (parts.isEmpty) return 'تم تحديد الموقع بدون تفاصيل نصية.';
      return 'موقعك الحالي: ${parts.take(3).join('، ')}';
    } catch (_) {
      return 'تعذر الحصول على الموقع الحالي حالياً.';
    }
  }

  String _sanitizePlacePart(String input) {
    // Remove plus-codes and coordinate-like fragments such as 582X+JPV.
    final plusCodePattern = RegExp(r'\b[A-Z0-9]{3,}\+[A-Z0-9]{2,}\b', caseSensitive: false);
    var cleaned = input.replaceAll(plusCodePattern, ' ').trim();
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    // Skip any part that still contains digits (coordinates, codes, house numbers).
    if (RegExp(r'[0-9٠-٩]').hasMatch(cleaned)) return '';

    // Skip very short/noisy tokens.
    if (cleaned.length < 2) return '';
    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    final feature = FeatureCatalog.byRoute(TimeLocationScreen.routeName);
    return VoiceCloseListener(
      child: Scaffold(
        appBar: FeatureAppBar(feature: feature),
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Semantics(
                liveRegion: true,
                label: 'الساعة $_time',
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.surfaceHigh, AppColors.surface],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.12), blurRadius: 30)],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'الساعة الآن  •  CURRENT TIME',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 12,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(_time, style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w800, height: 1.1)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _InfoTile(icon: Icons.today_rounded, title: 'اليوم', value: _dayName),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoTile(icon: Icons.event_rounded, title: 'التاريخ', value: _date),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoTile(icon: Icons.location_on_rounded, title: 'الموقع الحالي', value: _location, large: true),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _refreshInfo,
                icon: const Icon(Icons.refresh_rounded, size: 26),
                label: const Text('تحديث وإعلان بالصوت'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.title, required this.value, this.large = false});

  final IconData icon;
  final String title;
  final String value;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: large ? 19 : 21, fontWeight: FontWeight.w800, height: 1.4),
          ),
        ],
      ),
    );
  }
}
