import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../constants/feature_catalog.dart';
import '../demo/demo_mode.dart';
import '../theme/app_theme.dart';
import 'voice_close_listener.dart';

/// Shared layout for camera-based features: framed live view, result card and
/// a primary action button.
class FeatureScaffold extends StatelessWidget {
  const FeatureScaffold({
    required this.route,
    required this.result,
    this.camera,
    this.demoImage,
    this.busy = false,
    this.actionLabel,
    this.actionIcon = Icons.bolt_rounded,
    this.onAction,
    this.extra,
    this.alert = false,
    super.key,
  });

  final String route;
  final String result;
  final CameraController? camera;
  final String? demoImage;
  final bool busy;
  final String? actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;
  final Widget? extra;

  /// Highlights the result card as a warning.
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final feature = FeatureCatalog.byRoute(route);
    return VoiceCloseListener(
      child: Scaffold(
        appBar: FeatureAppBar(feature: feature),
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: CameraViewport(accent: feature.accent, camera: camera, demoImage: demoImage, scanning: busy),
                  ),
                  const SizedBox(height: 14),
                  ResultPanel(
                    icon: feature.icon,
                    accent: alert ? AppColors.danger : feature.accent,
                    text: result,
                    busy: busy,
                  ),
                  if (extra != null) ...[const SizedBox(height: 12), extra!],
                  if (actionLabel != null) ...[
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: busy ? null : onAction,
                      icon: Icon(actionIcon, size: 26),
                      label: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FeatureAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FeatureAppBar({required this.feature, super.key});

  final FeatureInfo feature;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 72,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(feature.arLabel),
          const SizedBox(height: 2),
          Text(
            feature.enLabel.toUpperCase(),
            style: const TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700, color: AppColors.gold),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 12),
          child: IconBadge(icon: feature.icon, color: feature.accent, size: 40),
        ),
      ],
    );
  }
}

class IconBadge extends StatelessWidget {
  const IconBadge({required this.icon, required this.color, this.size = 48, super.key});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }
}

class CameraViewport extends StatelessWidget {
  const CameraViewport({required this.accent, this.camera, this.demoImage, this.scanning = false, super.key});

  final Color accent;
  final CameraController? camera;
  final String? demoImage;
  final bool scanning;

  @override
  Widget build(BuildContext context) {
    final cam = camera;
    final Widget content;
    if (kDemoMode && demoImage != null) {
      content = Image.asset(demoImage!, fit: BoxFit.cover);
    } else if (cam != null && cam.value.isInitialized) {
      final size = cam.value.previewSize;
      content = size == null
          ? CameraPreview(cam)
          : FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(width: size.height, height: size.width, child: CameraPreview(cam)),
            );
    } else {
      content = const ColoredBox(
        color: AppColors.surface,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 14),
              Text('جاري تشغيل الكاميرا...', style: TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.12), blurRadius: 30, spreadRadius: 2)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Stack(
          fit: StackFit.expand,
          children: [
            content,
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66000000), Colors.transparent, Colors.transparent, Color(0x8C000000)],
                  stops: [0, 0.2, 0.7, 1],
                ),
              ),
            ),
            ScanOverlay(accent: accent, active: scanning),
            PositionedDirectional(top: 14, start: 14, child: _LiveChip(scanning: scanning)),
          ],
        ),
      ),
    );
  }
}

class _LiveChip extends StatelessWidget {
  const _LiveChip({required this.scanning});

  final bool scanning;

  @override
  Widget build(BuildContext context) {
    final color = scanning ? AppColors.gold : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xB3070F1D),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            scanning ? 'جاري التحليل' : 'مباشر',
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// Corner brackets and a sweeping scan line drawn over the camera view.
class ScanOverlay extends StatefulWidget {
  const ScanOverlay({required this.accent, this.active = false, super.key});

  final Color accent;
  final bool active;

  @override
  State<ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<ScanOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _ScanPainter(
            progress: _controller.value,
            color: widget.active ? AppColors.gold : widget.accent,
            active: widget.active,
          ),
        ),
      ),
    );
  }
}

class _ScanPainter extends CustomPainter {
  _ScanPainter({required this.progress, required this.color, required this.active});

  final double progress;
  final Color color;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 28.0;
    const arm = 36.0;
    final rect = Rect.fromLTRB(inset, inset + 34, size.width - inset, size.height - inset);
    final bracket = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final (corner, dx, dy) in [
      (rect.topLeft, 1.0, 1.0),
      (rect.topRight, -1.0, 1.0),
      (rect.bottomLeft, 1.0, -1.0),
      (rect.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawLine(corner, corner.translate(arm * dx, 0), bracket);
      canvas.drawLine(corner, corner.translate(0, arm * dy), bracket);
    }

    final t = Curves.easeInOut.transform(progress < 0.5 ? progress * 2 : (1 - progress) * 2);
    final y = rect.top + rect.height * t;
    final glow = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: active ? 0.95 : 0.45),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(rect.left, y - 1, rect.width, 2));
    canvas.drawRect(Rect.fromLTWH(rect.left + 6, y - 1.5, rect.width - 12, 3), glow);

    if (active) {
      final haze = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(rect.left, y - 60, rect.width, 60));
      canvas.drawRect(Rect.fromLTWH(rect.left + 6, y - 60, rect.width - 12, 60), haze);
    }
  }

  @override
  bool shouldRepaint(_ScanPainter old) => old.progress != progress || old.color != color || old.active != active;
}

class ResultPanel extends StatelessWidget {
  const ResultPanel({required this.icon, required this.accent, required this.text, this.busy = false, super.key});

  final IconData icon;
  final Color accent;
  final String text;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: text,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withValues(alpha: busy ? 0.35 : 0.7), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.graphic_eq_rounded, color: accent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'النتيجة  •  RESULT',
                  style: TextStyle(color: accent, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                if (busy)
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
                else
                  Icon(Icons.volume_up_rounded, color: accent.withValues(alpha: 0.8), size: 20),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              child: SizedBox(
                key: ValueKey(text),
                width: double.infinity,
                child: Text(
                  text,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, height: 1.45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
