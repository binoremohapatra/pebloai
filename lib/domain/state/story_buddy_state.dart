// lib/domain/state/story_buddy_state.dart
//
// Finite State Machine definition for the Story Buddy screen lifecycle.
// All states are modelled as a Dart 3 sealed class — the Dart analyser
// enforces exhaustive switches, making illegal state combinations unrepresentable
// in the type system.
//
// ┌─────────────────────── VALID TRANSITION GRAPH ────────────────────────┐
// │                                                                         │
// │  Initial ──[tap Read]──► LoadingAudio ──[tts ready]──► Playing         │
// │      ▲                        │                           │             │
// │      │               [platform error]               [tts complete]      │
// │      │                        │                           │             │
// │      │                        ▼                           ▼             │
// │      │                   AudioError               QuizRevealed          │
// │      │                        │                     │         │         │
// │      └──────[tap Try Again]───┘            [wrong tap]   [right tap]   │
// │                                                 │               │       │
// │                                            QuizRevealed    AnswerCorrect│
// │                                          (unchanged —        (terminal) │
// │                                          user retries)                  │
// └─────────────────────────────────────────────────────────────────────────┘
//
// ILLEGAL (enforced by Notifier guard clauses):
//   Initial → AnswerCorrect        (must pass through Loading/Playing/Quiz)
//   Playing → Initial              (must stop TTS before resetting)
//   AnswerCorrect → anything       (terminal state; requires full screen reset)

sealed class StoryBuddyState {
  const StoryBuddyState();
}

/// The screen has just mounted. No audio has been requested yet.
final class Initial extends StoryBuddyState {
  const Initial();
}

/// The TTS engine is initialising or buffering. Button is disabled.
final class LoadingAudio extends StoryBuddyState {
  const LoadingAudio();
}

/// TTS is actively speaking. The action button shows a pulsing indicator.
final class Playing extends StoryBuddyState {
  const Playing();
}

/// TTS platform call failed or was interrupted. Carries the reason for display
/// in the first-class error card UI.
final class AudioError extends StoryBuddyState {
  const AudioError({required this.message});
  final String message;
}

/// TTS playback finished. The quiz animates in. User has not answered yet.
final class QuizRevealed extends StoryBuddyState {
  const QuizRevealed({required this.quiz});
  final dynamic quiz; // typed as QuizModel at usage site to avoid circular imports
}

/// User selected the correct answer. Terminal state for this session.
/// Confetti and success message are displayed.
final class AnswerCorrect extends StoryBuddyState {
  const AnswerCorrect({required this.quiz});
  final dynamic quiz;
}

/// User selected a wrong answer.
final class AnswerWrong extends StoryBuddyState {
  const AnswerWrong({required this.quiz});
  final dynamic quiz;
}

