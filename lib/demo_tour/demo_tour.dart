import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/feature_catalog.dart';
import '../core/services/settings_service.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/feature_scaffold.dart';
import '../features/home/home_screen.dart';
import '../main.dart';

/// Timeline in seconds from the start of the intro. `tool/demo_video/make_video.py`
/// mirrors these values to place narration, so keep both in sync.
class TourTiming {
  static const marker = 1.5;
  static const preRoll = 0.5;
  static const intro = 8.0;
  static const title = 3.5;
  static const home = 10.0;
  static const usage = 16.5;
  static const outro = 9.0;
  static const highlightAt = 0.1;
  static const pushAt = 1.4;
  static const fade = 0.45;

  static double get homeTitleStart => intro;
  static double get homeStart => homeTitleStart + title;
  static double featureStart(int i) => homeStart + home + i * (title + usage);
  static double get outroStart => featureStart(FeatureCatalog.all.length);
  static double get end => outroStart + outro;
}

class _TourCopy {
  const _TourCopy(this.arDetail, this.enDetail, this.tags);
  final String arDetail;
  final String enDetail;
  final List<String> tags;
}

const _copy = <String, _TourCopy>{
  '/scene': _TourCopy(
    'يصف الذكاء الاصطناعي ما حولك بجمل واضحة، ويذكر العوائق والمسارات الآمنة.',
    'Generative AI describes the surroundings, obstacles and safe paths.',
    ['Gemini Vision', 'Auto every 4s', 'Arabic speech'],
  ),
  '/currency': _TourCopy(
    'نموذج مدرَّب على العملة المصرية يعمل على الهاتف مباشرة، بدون إنترنت.',
    'A custom YOLOv8 model recognizes Egyptian banknotes fully on-device.',
    ['YOLOv8 · TFLite', 'Offline', '6 denominations'],
  ),
  '/ocr': _TourCopy(
    'يقرأ الأدوية واللافتات والمستندات بصوت واضح باللغتين العربية والإنجليزية.',
    'Reads medicine boxes, signs and documents aloud in Arabic and English.',
    ['ML Kit OCR', 'Gemini fallback', 'Bilingual'],
  ),
  '/objects': _TourCopy(
    'يتعرف على الأشياء أمامك ويسميها بالعربية فوراً.',
    'Detects everyday objects and names them instantly in Arabic.',
    ['ML Kit Objects', 'Image labeling', 'Live'],
  ),
  '/faces': _TourCopy(
    'يعرف عدد الأشخاص أمامك ليساعدك في المواقف الاجتماعية.',
    'Counts the people in front of you to support social situations.',
    ['Face detection', 'On-device', 'Voice alerts'],
  ),
  '/colors': _TourCopy(
    'يحدد اللون الغالب للملابس والأشياء لاختيار أسهل كل يوم.',
    'Identifies the dominant color of clothes and objects.',
    ['Color analysis', 'Instant', 'Arabic names'],
  ),
  '/barcode': _TourCopy(
    'يمسح باركود المنتجات ويخبرك باسم المنتج من قاعدة بيانات عالمية.',
    'Scans product barcodes and speaks the product name.',
    ['ML Kit Barcode', 'Open Food Facts', 'Auto scan'],
  ),
  '/navigation': _TourCopy(
    'ينبهك بالصوت والاهتزاز عند وجود سلالم أو حواجز أو حائط أمامك.',
    'Warns of stairs, barriers and walls with voice and vibration.',
    ['Obstacle alerts', 'Haptics', 'Every 2s'],
  ),
  '/time-location': _TourCopy(
    'يعلن اليوم والتاريخ والساعة واسم المكان الحالي بلمسة واحدة.',
    'Announces the day, date, time and current place in one tap.',
    ['GPS', 'Geocoding', 'Arabic calendar'],
  ),
  '/settings': _TourCopy(
    'اختيار اللغة وسرعة الصوت وإضافة مفتاح الذكاء الاصطناعي بأمان.',
    'Choose the language, speech speed and securely add the AI key.',
    ['Arabic / English', 'Speech rate', 'Secure key'],
  ),
};

class DemoTourApp extends StatelessWidget {
  const DemoTourApp({required this.settings, super.key});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BASIRA AI',
      theme: AppTheme.darkTheme,
      home: _DemoStage(settings: settings),
    );
  }
}

enum _Phase { marker, black, intro, title, stage, outro }

class _DemoStage extends StatefulWidget {
  const _DemoStage({required this.settings});

  final SettingsService settings;

  @override
  State<_DemoStage> createState() => _DemoStageState();
}

class _DemoStageState extends State<_DemoStage> {
  final _phoneNav = GlobalKey<NavigatorState>();
  final _clock = Stopwatch();
  _Phase _phase = _Phase.marker;

  /// -1 = home screen step, otherwise index into [FeatureCatalog.all].
  int _step = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _at(double seconds) async {
    final wait = Duration(milliseconds: (seconds * 1000).round()) - _clock.elapsed;
    if (wait > Duration.zero) await Future<void>.delayed(wait);
  }

  void _set(_Phase phase, {int? step}) {
    if (!mounted) return;
    setState(() {
      _phase = phase;
      if (step != null) _step = step;
    });
  }

  Future<void> _run() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    _clock.start();
    await _at(TourTiming.marker);
    _set(_Phase.black);
    await _at(TourTiming.marker + TourTiming.preRoll);
    _clock
      ..reset()
      ..start();

    _set(_Phase.intro);
    await _at(TourTiming.homeTitleStart);
    _set(_Phase.title, step: -1);
    await _at(TourTiming.homeStart);
    _set(_Phase.stage);

    for (var i = 0; i < FeatureCatalog.all.length; i++) {
      final start = TourTiming.featureStart(i);
      final route = FeatureCatalog.all[i].route;
      await _at(start);
      _set(_Phase.title, step: i);
      await _at(start + TourTiming.fade);
      _phoneNav.currentState?.popUntil((r) => r.isFirst);
      await _at(start + TourTiming.title);
      _set(_Phase.stage);
      await _at(start + TourTiming.title + TourTiming.highlightAt);
      HomeScreen.demoHighlight.value = route;
      await _at(start + TourTiming.title + TourTiming.pushAt);
      HomeScreen.demoHighlight.value = null;
      unawaited(_phoneNav.currentState?.pushNamed(route));
    }

    await _at(TourTiming.outroStart);
    _set(_Phase.outro);
    await _at(TourTiming.outroStart + TourTiming.fade);
    _phoneNav.currentState?.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FittedBox(
          child: SizedBox(
            width: 1920,
            height: 1080,
            child: Stack(
              children: [
                const Positioned.fill(child: _StageBackground()),
                Positioned.fill(child: _buildStage()),
                // Keeps the stage hidden while one full-screen page crossfades into another.
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _phase == _Phase.stage ? 0 : 1,
                      duration: Duration(milliseconds: (TourTiming.fade * 1000).round()),
                      child: const _PageBackground(child: SizedBox.shrink()),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: (TourTiming.fade * 1000).round()),
                    child: _buildOverlay(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    switch (_phase) {
      case _Phase.marker:
        return const ColoredBox(key: ValueKey('marker'), color: Color(0xFFFF00FF), child: SizedBox.expand());
      case _Phase.black:
        return const ColoredBox(key: ValueKey('black'), color: Colors.black, child: SizedBox.expand());
      case _Phase.intro:
        return const _IntroPage(key: ValueKey('intro'));
      case _Phase.title:
        return _TitlePage(key: ValueKey('title$_step'), step: _step);
      case _Phase.outro:
        return const _OutroPage(key: ValueKey('outro'));
      case _Phase.stage:
        return const SizedBox.shrink(key: ValueKey('none'));
    }
  }

  Widget _buildStage() {
    return Row(
      children: [
        const SizedBox(width: 200),
        _PhoneFrame(child: BasiraApp(settings: widget.settings, navigatorKey: _phoneNav)),
        const SizedBox(width: 110),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 140),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0.04, 0), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              child: _CaptionPanel(key: ValueKey(_step), step: _step),
            ),
          ),
        ),
      ],
    );
  }
}

class _StageBackground extends StatelessWidget {
  const _StageBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.45, 0),
          radius: 1.1,
          colors: [Color(0xFF14264A), Color(0xFF081226), Color(0xFF040913)],
          stops: [0, 0.55, 1],
        ),
      ),
      child: CustomPaint(painter: _GridPainter()),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = const Color(0x14FFFFFF);
    for (double x = 24; x < size.width; x += 48) {
      for (double y = 24; y < size.height; y += 48) {
        canvas.drawCircle(Offset(x, y), 1.4, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});

  final Widget child;

  static const screen = Size(412, 892);

  @override
  Widget build(BuildContext context) {
    final base = MediaQuery.of(context);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF05070C),
        borderRadius: BorderRadius.circular(62),
        border: Border.all(color: const Color(0xFF3A4660), width: 2.5),
        boxShadow: [
          BoxShadow(color: AppColors.gold.withValues(alpha: 0.16), blurRadius: 90, spreadRadius: 6),
          const BoxShadow(color: Colors.black54, blurRadius: 40, offset: Offset(0, 24)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(49),
        child: SizedBox.fromSize(
          size: screen,
          child: MediaQuery(
            data: base.copyWith(
              size: screen,
              padding: const EdgeInsets.only(top: 40, bottom: 14),
              viewPadding: const EdgeInsets.only(top: 40, bottom: 14),
              viewInsets: EdgeInsets.zero,
              textScaler: TextScaler.noScaling,
            ),
            child: Stack(
              children: [
                Positioned.fill(child: child),
                const Positioned(top: 0, left: 0, right: 0, height: 40, child: _StatusBar()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28),
        child: Row(
          children: [
            Text('10:30', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
            Spacer(),
            Icon(Icons.signal_cellular_alt_rounded, size: 17, color: Colors.white),
            SizedBox(width: 5),
            Icon(Icons.wifi_rounded, size: 17, color: Colors.white),
            SizedBox(width: 5),
            Icon(Icons.battery_full_rounded, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _CaptionPanel extends StatelessWidget {
  const _CaptionPanel({required this.step, super.key});

  final int step;

  @override
  Widget build(BuildContext context) {
    final total = FeatureCatalog.all.length;
    final isHome = step < 0;
    final feature = isHome ? null : FeatureCatalog.all[step];
    final copy = isHome ? null : _copy[feature!.route]!;
    final accent = feature?.accent ?? AppColors.gold;

    final arTitle = feature?.arLabel ?? 'الواجهة الرئيسية';
    final enTitle = feature?.enLabel ?? 'Home Screen';
    final arDetail = copy?.arDetail ?? 'عشر خدمات بأزرار كبيرة عالية التباين، وأوامر صوتية واهتزاز.';
    final enDetail = copy?.enDetail ?? 'Ten services, large high-contrast controls, voice commands and haptic feedback.';
    final tags = copy?.tags ?? const ['Voice commands', 'High contrast', 'Haptic feedback'];

    return Column(
      children: [
        const SizedBox(height: 70),
        const _Brand(),
        const Spacer(),
        Text(
          isHome ? 'OVERVIEW' : 'FEATURE ${(step + 1).toString().padLeft(2, '0')} / $total',
          style: const TextStyle(color: AppColors.gold, fontSize: 24, letterSpacing: 6, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 26),
        IconBadge(icon: feature?.icon ?? Icons.dashboard_rounded, color: accent, size: 110),
        const SizedBox(height: 26),
        Text(
          arTitle,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 84, fontWeight: FontWeight.w800, height: 1.15),
        ),
        Text(
          enTitle,
          style: const TextStyle(fontSize: 40, color: AppColors.textMuted, fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
        const SizedBox(height: 28),
        Container(width: 130, height: 5, decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(3))),
        const SizedBox(height: 28),
        Text(
          arDetail,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, height: 1.5),
        ),
        const SizedBox(height: 12),
        Text(
          enDetail,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, color: AppColors.textMuted, height: 1.45),
        ),
        const SizedBox(height: 34),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final tag in tags)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.5),
                ),
                child: Text(tag, style: TextStyle(color: accent, fontSize: 22, fontWeight: FontWeight.w800)),
              ),
          ],
        ),
        const Spacer(),
        _Progress(step: step, total: total),
        const SizedBox(height: 70),
      ],
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.visibility_rounded, color: Color(0xFF1A1204), size: 28),
        ),
        const SizedBox(width: 14),
        const Text('BASIRA AI', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 6)),
        const SizedBox(width: 14),
        Container(width: 2, height: 28, color: AppColors.border),
        const SizedBox(width: 14),
        const Text('بصيرة', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.gold)),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          Container(
            width: i == step ? 64 : 34,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: i == step ? AppColors.gold : (i < step ? AppColors.goldDeep.withValues(alpha: 0.6) : AppColors.border),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

/// Fades and lifts its child in once when first built.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.child, this.delay = 0});

  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 900 + delay),
      curve: Interval(delay / (900 + delay), 1, curve: Curves.easeOutCubic),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 30 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}

class _PageBackground extends StatelessWidget {
  const _PageBackground({required this.child, this.glow = AppColors.gold});

  final Widget child;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 0.9,
          colors: [Color.lerp(const Color(0xFF14264A), glow, 0.12)!, const Color(0xFF071022), const Color(0xFF03070F)],
          stops: const [0, 0.6, 1],
        ),
      ),
      child: CustomPaint(painter: const _GridPainter(), child: Center(child: child)),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageBackground(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Reveal(
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(56),
                boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.45), blurRadius: 80)],
              ),
              child: const Icon(Icons.visibility_rounded, size: 120, color: Color(0xFF1A1204)),
            ),
          ),
          const SizedBox(height: 40),
          const _Reveal(
            delay: 250,
            child: Text('بصيرة', style: TextStyle(fontSize: 150, fontWeight: FontWeight.w800, height: 1.1)),
          ),
          const _Reveal(
            delay: 450,
            child: Text(
              'BASIRA AI',
              style: TextStyle(fontSize: 56, fontWeight: FontWeight.w800, letterSpacing: 22, color: AppColors.gold),
            ),
          ),
          const SizedBox(height: 40),
          const _Reveal(
            delay: 800,
            child: Text(
              'مساعدك الذكي للرؤية — للمكفوفين وضعاف البصر',
              textDirection: TextDirection.rtl,
              style: TextStyle(fontSize: 44, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          const _Reveal(
            delay: 1000,
            child: Text(
              'An AI-powered vision assistant for blind and visually impaired people',
              style: TextStyle(fontSize: 30, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 60),
          const _Reveal(
            delay: 1400,
            child: Text(
              'PRODUCT DEMO  •  2026',
              style: TextStyle(fontSize: 22, letterSpacing: 8, color: AppColors.textMuted, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _TitlePage extends StatelessWidget {
  const _TitlePage({required this.step, super.key});

  final int step;

  @override
  Widget build(BuildContext context) {
    final isHome = step < 0;
    final feature = isHome ? null : FeatureCatalog.all[step];
    final accent = feature?.accent ?? AppColors.gold;
    return _PageBackground(
      glow: accent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Reveal(
            child: Text(
              isHome
                  ? 'نظرة عامة  •  OVERVIEW'
                  : 'الميزة ${step + 1}  •  FEATURE ${(step + 1).toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 30, letterSpacing: 5, color: AppColors.gold, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 44),
          _Reveal(delay: 150, child: IconBadge(icon: feature?.icon ?? Icons.dashboard_rounded, color: accent, size: 170)),
          const SizedBox(height: 44),
          _Reveal(
            delay: 300,
            child: Text(
              feature?.arLabel ?? 'الواجهة الرئيسية',
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 128, fontWeight: FontWeight.w800, height: 1.15),
            ),
          ),
          _Reveal(
            delay: 450,
            child: Text(
              feature?.enLabel ?? 'Home Screen',
              style: const TextStyle(fontSize: 56, color: AppColors.textMuted, fontWeight: FontWeight.w700, letterSpacing: 2),
            ),
          ),
          const SizedBox(height: 44),
          _Reveal(
            delay: 600,
            child: Container(width: 180, height: 6, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(3))),
          ),
        ],
      ),
    );
  }
}

class _OutroPage extends StatelessWidget {
  const _OutroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageBackground(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Reveal(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final f in FeatureCatalog.all)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    child: IconBadge(icon: f.icon, color: f.accent, size: 76),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 60),
          const _Reveal(
            delay: 250,
            child: Text('شكراً لكم', style: TextStyle(fontSize: 130, fontWeight: FontWeight.w800, height: 1.1)),
          ),
          const _Reveal(
            delay: 400,
            child: Text('Thank you', style: TextStyle(fontSize: 56, color: AppColors.textMuted, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 44),
          const _Reveal(
            delay: 700,
            child: Text(
              'BASIRA AI  —  بصيرة',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: 6, color: AppColors.gold),
            ),
          ),
          const SizedBox(height: 14),
          const _Reveal(
            delay: 850,
            child: Text(
              'نرى العالم بالذكاء الاصطناعي  •  Seeing the world through AI',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
