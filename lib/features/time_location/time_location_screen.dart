import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import '../../core/services/tts_service.dart';

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

    final now = DateTime.now();
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final places = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (places.isEmpty) {
        return 'تعذر تحديد اسم المكان، لكن تم تحديد الإحداثيات.';
      }

      final p = places.first;
      // Prefer human-readable area names and avoid street-level/plus-code fragments.
      final parts = [
        p.subLocality,
        p.locality,
        p.administrativeArea,
        p.country,
      ]
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
    return Scaffold(
      appBar: AppBar(title: const Text('الوقت والمكان')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('اليوم'),
                subtitle: Text(_dayName),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.event),
                title: const Text('التاريخ'),
                subtitle: Text(_date),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('الساعة'),
                subtitle: Text(_time),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('الموقع الحالي'),
                subtitle: Text(_location),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshInfo,
              child: const Text('تحديث الآن'),
            ),
          ],
        ),
      ),
    );
  }
}
