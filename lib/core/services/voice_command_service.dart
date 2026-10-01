import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../demo/demo_mode.dart';

/// Returns true when the recognized (normalized) words were handled.
typedef VoiceHandler = bool Function(String words);

/// Owns the single speech recognizer and keeps it listening while any screen
/// has registered a handler. Only the most recently registered handler (the
/// screen on top) receives results.
class VoiceCommandService with WidgetsBindingObserver {
  VoiceCommandService() {
    WidgetsBinding.instance.addObserver(this);
  }

  final stt.SpeechToText _speech = stt.SpeechToText();
  final List<VoiceHandler> _handlers = [];
  final ValueNotifier<bool> listening = ValueNotifier(false);

  bool _ready = false;
  Future<bool>? _initializing;
  bool _loopRunning = false;
  bool _foreground = true;
  int _holds = 0;
  Completer<void>? _session;

  bool get _active => !kDemoMode && _foreground && _holds == 0 && _handlers.isNotEmpty;

  static String normalize(String text) => text
      .toLowerCase()
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll(RegExp('[\u064B-\u0652]'), '');

  Future<bool> ensureReady() async {
    if (_ready || kDemoMode) return _ready;
    final ok = await (_initializing ??= _initialize());
    _initializing = null;
    return ok;
  }

  Future<bool> _initialize() async {
    try {
      _ready = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') _endSession();
        },
        onError: (_) => _endSession(),
      );
    } catch (_) {
      _ready = false;
    }
    return _ready;
  }

  void register(VoiceHandler handler) {
    _handlers
      ..remove(handler)
      ..add(handler);
    _kick();
  }

  void unregister(VoiceHandler handler) {
    _handlers.remove(handler);
    if (_handlers.isEmpty) _cancel();
  }

  /// Stops listening for [duration], e.g. while the app is speaking.
  Future<void> pauseFor(Duration duration) async {
    _holds++;
    _cancel();
    await Future<void>.delayed(duration);
    _holds--;
    _kick();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _foreground ? _kick() : _cancel();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _handlers.clear();
    _cancel();
  }

  void _kick() {
    if (_active && !_loopRunning) unawaited(_loop());
  }

  void _cancel() {
    if (_ready) _speech.cancel();
    _endSession();
  }

  void _endSession() {
    final session = _session;
    if (session != null && !session.isCompleted) session.complete();
  }

  Future<void> _loop() async {
    _loopRunning = true;
    try {
      if (!await ensureReady()) return;
      while (_active) {
        _session = Completer<void>();
        listening.value = true;
        try {
          await _speech.listen(
            localeId: 'ar_EG',
            listenFor: const Duration(seconds: 30),
            pauseFor: const Duration(seconds: 5),
            listenOptions: stt.SpeechListenOptions(partialResults: false, cancelOnError: true),
            onResult: (result) {
              if (result.finalResult) _dispatch(result.recognizedWords);
            },
          );
        } catch (_) {
          _endSession();
        }
        await _session!.future.timeout(const Duration(seconds: 40), onTimeout: () {});
        listening.value = false;
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    } finally {
      _loopRunning = false;
      listening.value = false;
    }
  }

  void _dispatch(String recognized) {
    final words = normalize(recognized);
    if (words.isEmpty || _handlers.isEmpty) return;
    _handlers.last(words);
  }
}
