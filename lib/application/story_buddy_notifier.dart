// lib/application/story_buddy_notifier.dart
//
// FSM Notifier — the sole authority over StoryBuddyState transitions.
// Every public method is a guarded transition; illegal transitions are
// rejected with an assertion and a descriptive message for developer tooling.
//
// ┌─────────────────── VALID TRANSITION SUMMARY ──────────────────────────┐
// │  Initial       → LoadingAudio   (requestStory)                         │
// │  LoadingAudio  → Playing        (_onTtsReady — internal)               │
// │  LoadingAudio  → AudioError     (_onTtsError — internal)               │
// │  Playing       → QuizRevealed   (_onTtsComplete — internal)            │
// │  Playing       → AudioError     (_onTtsError — internal)               │
// │  AudioError    → Initial        (reset)                                 │
// │  QuizRevealed  → AnswerCorrect  (submitAnswer, correct branch)         │
// │  QuizRevealed  → QuizRevealed   (submitAnswer, wrong branch — no-op)   │
// └────────────────────────────────────────────────────────────────────────┘

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peblo_ai_buddy/application/providers.dart';
import 'package:peblo_ai_buddy/domain/models/quiz_model.dart';
import 'package:peblo_ai_buddy/domain/services/i_tts_service.dart';
import 'package:peblo_ai_buddy/domain/state/story_buddy_state.dart';

// The story text is defined here, co-located with the logic that speaks it,
// so that the UI Story Card and the TTS utterance are always in sync.
const String kStoryText =
    'Once upon a time, a clever little robot named Pip lost his shiny blue gear '
    'in the Whispering Woods. He searched and searched, but the trees just '
    'whispered secrets…';

class StoryBuddyNotifier extends Notifier<StoryBuddyState> {
  // Resolved lazily from the provider graph — no constructor injection needed
  // because Riverpod 2 Notifiers have access to ref directly.
  late final ITtsService _tts;
  late final QuizModel _quiz;

  @override
  StoryBuddyState build() {
    // Resolve dependencies from the provider graph at build time.
    _tts = ref.read(ttsServiceProvider);
    _quiz = ref.read(quizProvider);

    // TTS engine disposal is registered in ttsServiceProvider itself via
    // ref.onDispose — no additional disposal needed here.
    return const Initial();
  }

  // ---------------------------------------------------------------------------
  // Public FSM Transitions
  // ---------------------------------------------------------------------------

  /// Triggered by the "Read Me a Story!" button tap.
  /// Valid from: Initial, AudioError (via reset then re-tap — but reset goes
  /// to Initial first, so this always receives Initial).
  Future<void> requestStory() async {
    // Guard: only valid from Initial state.
    // debugPrint is erased by the release compiler — zero production overhead.
    // Using debugPrint instead of assert(false) so the guard is a graceful
    // no-op in test mode rather than an AssertionError that crashes callers.
    if (state is! Initial) {
      debugPrint(
        '[StoryBuddyNotifier] requestStory() called from '
        '${state.runtimeType} — only valid from Initial. Ignoring.',
      );
      return;
    }

    state = const LoadingAudio();

    try {
      // Lazy init: the TTS engine is first touched here, not at app startup,
      // keeping the initial screen render cost minimal on low-end devices.
      await _tts.init();

      // Register the completion callback before speaking so no race condition
      // exists between speech starting and the handler being attached.
      _tts.onComplete(_onTtsComplete);

      state = const Playing();
      await _tts.speak(kStoryText);
    } catch (e) {
      await _onTtsError(e.toString());
    }
  }

  /// Triggered when the user taps a quiz option button.
  /// Valid from: QuizRevealed only.
  /// Returns true if the answer is correct so the UI can trigger confetti
  /// and shake animations without coupling animation logic to the Notifier.
  bool submitAnswer(String selected) {
    // Guard: quiz answers can only be submitted from QuizRevealed or AnswerWrong state.
    if (state is! QuizRevealed && state is! AnswerWrong) {
      debugPrint(
        '[StoryBuddyNotifier] submitAnswer() called from '
        '${state.runtimeType} — only valid from QuizRevealed or AnswerWrong. Ignoring.',
      );
      return false;
    }

    final isCorrect = selected == _quiz.answer;

    if (isCorrect) {
      // Transition to terminal success state — no further answers accepted.
      state = AnswerCorrect(quiz: _quiz);
      _tts.speak("Yay! That's correct! My gear was blue.");
    } else {
      // Transition to AnswerWrong state to trigger sad mascot animation.
      // We recreate the state object so that Riverpod notifies listeners even if
      // they were already in AnswerWrong.
      state = AnswerWrong(quiz: _quiz);
      _tts.speak("Oops! That's incorrect. Try again!");
    }
    
    // The widget layer may use this return value for local animations (like shake/tint)
    return isCorrect;
  }

  /// Resets the FSM to Initial after an AudioError. The user can tap
  /// "Try Again" to restart the full TTS → Quiz flow.
  void reset() {
    if (state is! AudioError) {
      debugPrint(
        '[StoryBuddyNotifier] reset() called from '
        '${state.runtimeType} — only valid from AudioError. Ignoring.',
      );
      return;
    }
    state = const Initial();
  }

  // ---------------------------------------------------------------------------
  // Private Internal Transitions (called by TTS callbacks)
  // ---------------------------------------------------------------------------

  /// Called by the TTS completion handler when the utterance finishes.
  void _onTtsComplete() {
    // Guard: completion is only meaningful while Playing.
    if (state is! Playing) return;
    state = QuizRevealed(quiz: _quiz);
    _tts.speak(_quiz.question);
  }

  /// Called when the TTS platform throws or the init fails.
  Future<void> _onTtsError(String message) async {
    // Stop the engine before setting error state so audio is silenced
    // before the error card animates in — prevents a jarring overlap.
    await _tts.stop();
    state = AudioError(
      message: 'Could not read the story: $message',
    );
  }
}
