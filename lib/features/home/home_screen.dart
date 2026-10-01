import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/feature_catalog.dart';
import '../../core/demo/demo_mode.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/services/voice_command_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/feature_scaffold.dart';
import '../color_detection/color_screen.dart';
import '../currency_detection/currency_screen.dart';
import '../face_recognition/face_screen.dart';
import '../object_detection/object_screen.dart';
import '../product_scanner/barcode_screen.dart';
import '../navigation_assistant/navigation_screen.dart';
import '../scene_description/scene_screen.dart';
import '../settings/settings_screen.dart';
import '../text_reader/ocr_screen.dart';
import '../time_location/time_location_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// Route of the card to show as pressed; driven by the demo tour.
  static final demoHighlight = ValueNotifier<String?>(null);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final VoiceCommandService _voice = context.read<VoiceCommandService>();
  final HapticService _haptic = HapticService();
  bool _navigating = false;

  static const _commands = <({String keyword, String route, String label})>[
    (keyword: 'مشهد', route: SceneScreen.routeName, label: 'وصف المشهد'),
    (keyword: 'عمله', route: CurrencyScreen.routeName, label: 'تعرف على العملة'),
    (keyword: 'فلوس', route: CurrencyScreen.routeName, label: 'تعرف على العملة'),
    (keyword: 'نص', route: OcrScreen.routeName, label: 'قراءة النصوص'),
    (keyword: 'قراءه', route: OcrScreen.routeName, label: 'قراءة النصوص'),
    (keyword: 'اشياء', route: ObjectScreen.routeName, label: 'اكتشاف الأشياء'),
    (keyword: 'وجوه', route: FaceScreen.routeName, label: 'اكتشاف الوجوه'),
    (keyword: 'الوان', route: ColorScreen.routeName, label: 'تعرف على الألوان'),
    (keyword: 'لون', route: ColorScreen.routeName, label: 'تعرف على الألوان'),
    (keyword: 'باركود', route: BarcodeScreen.routeName, label: 'مسح الباركود'),
    (keyword: 'منتج', route: BarcodeScreen.routeName, label: 'مسح الباركود'),
    (keyword: 'سير', route: NavigationScreen.routeName, label: 'مساعد السير'),
    (keyword: 'تنقل', route: NavigationScreen.routeName, label: 'مساعد السير'),
    (keyword: 'مشي', route: NavigationScreen.routeName, label: 'مساعد السير'),
    (keyword: 'وقت', route: TimeLocationScreen.routeName, label: 'الوقت والمكان'),
    (keyword: 'ساعه', route: TimeLocationScreen.routeName, label: 'الوقت والمكان'),
    (keyword: 'تاريخ', route: TimeLocationScreen.routeName, label: 'الوقت والمكان'),
    (keyword: 'مكان', route: TimeLocationScreen.routeName, label: 'الوقت والمكان'),
    (keyword: 'اعدادات', route: SettingsScreen.routeName, label: 'الإعدادات'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _welcomeAndListen());
  }

  @override
  void dispose() {
    _voice.unregister(_onVoice);
    super.dispose();
  }

  Future<void> _welcomeAndListen() async {
    final tts = context.read<TtsService>();
    // Speech completion is not awaited, so hold the microphone until the greeting ends.
    unawaited(_voice.pauseFor(const Duration(seconds: 6)));
    _voice.register(_onVoice);
    await tts.speak('مرحباً بك في بصيرة. قل اسم الخدمة التي تريدها في أي وقت، وقل رجوع لإغلاقها.');
    if (kDemoMode) return;
    await Future<void>.delayed(const Duration(seconds: 6));
    if (mounted && !await _voice.ensureReady()) {
      await tts.speak('تعذر تفعيل الأوامر الصوتية الآن.');
    }
  }

  bool _onVoice(String words) {
    if (_navigating) return false;
    for (final entry in _commands) {
      if (words.contains(entry.keyword)) {
        _open(entry.route, 'فتح ${entry.label}');
        return true;
      }
    }
    return false;
  }

  Future<void> _open(String route, String announcement) async {
    if (_navigating) return;
    _navigating = true;
    final tts = context.read<TtsService>();
    // Keep the microphone from hearing the announcement.
    unawaited(_voice.pauseFor(const Duration(seconds: 3)));
    try {
      await _haptic.tap();
      await tts.speak(announcement);
      if (!mounted) return;
      await Navigator.pushNamed(context, route);
    } finally {
      _navigating = false;
    }
    if (!mounted || kDemoMode) return;
    unawaited(_voice.pauseFor(const Duration(seconds: 3)));
    await tts.speak('الصفحة الرئيسية. قل اسم الخدمة.');
  }

  Future<void> _speakDesc(String desc) async {
    final tts = context.read<TtsService>();
    await _haptic.tap();
    await tts.speak(desc);
  }

  void _listenForCommand() {
    if (kDemoMode || ModalRoute.of(context)?.isCurrent != true) return;
    _voice.register(_onVoice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(child: _Header()),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _voice.listening,
                    builder: (context, listening, _) =>
                        _VoiceCommandCard(listening: listening, onTap: _listenForCommand),
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 26, 20, 12),
                sliver: SliverToBoxAdapter(child: _SectionTitle()),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                sliver: SliverGrid.builder(
                  itemCount: FeatureCatalog.all.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.02,
                  ),
                  itemBuilder: (context, i) {
                    final f = FeatureCatalog.all[i];
                    return _FeatureCard(
                      feature: f,
                      onTap: () => _open(f.route, f.arLabel),
                      onLongPress: () => _speakDesc(f.description),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: AppColors.gold.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 6)),
            ],
          ),
          child: const Icon(Icons.visibility_rounded, size: 34, color: Color(0xFF1A1204)),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('بصيرة', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.1)),
              Text(
                'BASIRA AI',
                style: TextStyle(fontSize: 13, letterSpacing: 4, fontWeight: FontWeight.w800, color: AppColors.gold),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_rounded, size: 16, color: AppColors.success),
              SizedBox(width: 6),
              Text(
                'جاهز',
                style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VoiceCommandCard extends StatelessWidget {
  const _VoiceCommandCard({required this.listening, required this.onTap});

  final bool listening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'أمر صوتي',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: AppColors.gold.withValues(alpha: 0.25), blurRadius: 26, offset: const Offset(0, 10)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(color: Color(0xFF1A1204), shape: BoxShape.circle),
                  child: Icon(
                    listening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                    color: AppColors.goldSoft,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listening ? 'أستمع إليك الآن...' : 'أمر صوتي',
                        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Color(0xFF1A1204)),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'قل اسم الخدمة في أي وقت: "عملة"، "نص"، "مشهد"',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xCC1A1204)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 10),
        const Text('الخدمات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(width: 10),
        const Text(
          'SERVICES',
          style: TextStyle(fontSize: 12, letterSpacing: 2.5, color: AppColors.textMuted, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        Text(
          '${FeatureCatalog.all.length}',
          style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({required this.feature, required this.onTap, required this.onLongPress});

  final FeatureInfo feature;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _highlighted = false;

  @override
  void initState() {
    super.initState();
    HomeScreen.demoHighlight.addListener(_onHighlight);
  }

  @override
  void dispose() {
    HomeScreen.demoHighlight.removeListener(_onHighlight);
    super.dispose();
  }

  void _onHighlight() {
    final on = HomeScreen.demoHighlight.value == widget.feature.route;
    if (on == _highlighted) return;
    setState(() => _highlighted = on);
    if (on) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.feature;
    return Semantics(
      button: true,
      label: f.arLabel,
      hint: f.description,
      child: AnimatedScale(
        scale: _highlighted ? 0.95 : 1,
        duration: const Duration(milliseconds: 220),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _highlighted ? f.accent.withValues(alpha: 0.16) : AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _highlighted ? f.accent : AppColors.border, width: _highlighted ? 2 : 1),
                boxShadow: _highlighted
                    ? [BoxShadow(color: f.accent.withValues(alpha: 0.35), blurRadius: 24)]
                    : const [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconBadge(icon: f.icon, color: f.accent, size: 50),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      f.arLabel,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.25),
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      f.enLabel,
                      maxLines: 1,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
