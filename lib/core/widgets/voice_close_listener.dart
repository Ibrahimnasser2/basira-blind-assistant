import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/haptic_service.dart';
import '../services/tts_service.dart';
import '../services/voice_command_service.dart';

/// Closes the enclosing screen when the user says a close word, e.g. "رجوع".
class VoiceCloseListener extends StatefulWidget {
  const VoiceCloseListener({required this.child, super.key});

  final Widget child;

  static const closeWords = [
    'رجوع',
    'ارجع',
    'رجع',
    'اغلاق',
    'اغلق',
    'اقفل',
    'قفل',
    'خروج',
    'اخرج',
    'الرئيسيه',
    'الصفحه الرئيسيه',
    'كفايه',
    'back',
    'close',
    'exit',
    'home',
  ];

  @override
  State<VoiceCloseListener> createState() => _VoiceCloseListenerState();
}

class _VoiceCloseListenerState extends State<VoiceCloseListener> {
  late final VoiceCommandService _voice = context.read<VoiceCommandService>();
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _voice.register(_onVoice);
  }

  @override
  void dispose() {
    _voice.unregister(_onVoice);
    super.dispose();
  }

  bool _onVoice(String words) {
    if (_closing || !VoiceCloseListener.closeWords.any(words.contains)) return false;
    if (ModalRoute.of(context)?.isCurrent != true) return false;
    _closing = true;
    _close();
    return true;
  }

  Future<void> _close() async {
    await HapticService().tap();
    if (!mounted) return;
    await context.read<TtsService>().speak('إغلاق الخدمة');
    if (!mounted) return;
    await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
