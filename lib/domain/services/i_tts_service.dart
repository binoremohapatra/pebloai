// lib/domain/services/i_tts_service.dart
//
// Abstract interface for Text-to-Speech operations.
//
// WHY AN INTERFACE:
// Decouples the Notifier (business logic) from flutter_tts (platform channel).
// Any concrete implementation — FlutterTtsService, a web speechSynthesis
// adapter, or a MockTtsService for unit tests — can be injected via Riverpod
// ProviderScope without modifying a single line of Notifier or widget code.
// This is SOLID's Dependency Inversion Principle applied to Flutter.
abstract interface class ITtsService {
  /// Initialise the underlying TTS engine and configure voice settings.
  /// Must be called before [speak]. Idempotent — safe to call multiple times.
  Future<void> init();

  /// Begin speaking [text]. Resolves when speech has started (not completed).
  Future<void> speak(String text);

  /// Stop any ongoing speech immediately. Must be called before setting
  /// AudioError state so the engine is silenced before the error card appears.
  Future<void> stop();

  /// Register a callback invoked when TTS finishes speaking the full text.
  /// The Notifier uses this to transition Playing → QuizRevealed.
  void onComplete(void Function() callback);

  /// Release all native engine resources. Called from ref.onDispose in the
  /// Notifier to prevent memory leaks when the Riverpod provider is destroyed.
  Future<void> dispose();
}
