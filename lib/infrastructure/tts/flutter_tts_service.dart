// lib/infrastructure/tts/flutter_tts_service.dart
//
// Our native TTS engine using flutter_tts.
// We keep all the flutter_tts stuff in here so it's easy to swap out if needed.

import 'package:flutter_tts/flutter_tts.dart';
import 'package:peblo_ai_buddy/domain/services/i_tts_service.dart';

class FlutterTtsService implements ITtsService {
  // We wait to initialize this until we actually need it.
  FlutterTts? _tts;

  @override
  Future<void> init() async {
    if (_tts != null) return; // Already started, don't do it again.
    _tts = FlutterTts();

    // Tune for child-friendly delivery: slightly slower rate, higher pitch,
    // moderate volume — all optimised for 6–10 year old comprehension.
    await _tts!.setLanguage('en-US');
    await _tts!.setSpeechRate(0.45);
    await _tts!.setPitch(1.15);
    await _tts!.setVolume(1.0);
  }

  @override
  Future<void> speak(String text) async {
    assert(_tts != null, 'ITtsService.init() must be called before speak()');
    await _tts!.speak(text);
  }

  @override
  Future<void> stop() async {
    // Stop the engine safely.
    await _tts?.stop();
  }

  @override
  void onComplete(void Function() callback) {
    // Let the rest of the app know when the audio finishes playing.
    _tts?.setCompletionHandler(callback);
  }

  @override
  Future<void> dispose() async {
    // Clean up when we're done.
    await _tts?.stop();
    _tts = null;
  }
}
