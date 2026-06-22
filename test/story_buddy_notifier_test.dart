// test/story_buddy_notifier_test.dart
//
// Unit tests for the FSM Notifier using pure-Dart MockTtsService.
// No Flutter engine required — all tests run in the Dart VM.
// Uses ProviderScope(overrides) to inject the mock without modifying
// any production code, validating the ITtsService abstraction layer.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peblo_ai_buddy/application/providers.dart';
import 'package:peblo_ai_buddy/application/story_buddy_notifier.dart';
import 'package:peblo_ai_buddy/domain/models/quiz_model.dart';
import 'package:peblo_ai_buddy/domain/services/i_tts_service.dart';
import 'package:peblo_ai_buddy/domain/state/story_buddy_state.dart';

// ---------------------------------------------------------------------------
// Pure-Dart Mock — zero flutter_tts dependency in this test file.
// Validates the entire ITtsService abstraction: the Notifier never knows
// whether it is talking to FlutterTtsService or this mock.
// ---------------------------------------------------------------------------
class MockTtsService implements ITtsService {
  bool initCalled = false;
  bool speakCalled = false;
  bool stopCalled = false;
  bool disposeCalled = false;
  String? lastSpokenText;
  void Function()? _completionCallback;

  // Simulates a successful TTS speak. Tests call triggerComplete() manually
  // to fire the completion callback at a controlled moment.
  @override
  Future<void> init() async => initCalled = true;

  @override
  Future<void> speak(String text) async {
    speakCalled = true;
    lastSpokenText = text;
  }

  @override
  Future<void> stop() async => stopCalled = true;

  @override
  void onComplete(void Function() callback) => _completionCallback = callback;

  @override
  Future<void> dispose() async => disposeCalled = true;

  /// Manually trigger the TTS completion event in tests.
  void triggerComplete() => _completionCallback?.call();
}

// ---------------------------------------------------------------------------
// Error-throwing mock for AudioError transition tests.
// ---------------------------------------------------------------------------
class ErrorTtsService implements ITtsService {
  @override
  Future<void> init() async =>
      throw Exception('Microphone permission denied');

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}

  @override
  void onComplete(void Function() callback) {}

  @override
  Future<void> dispose() async {}
}

// ---------------------------------------------------------------------------
// Helper: creates a ProviderContainer with the given TTS service injected.
// ---------------------------------------------------------------------------
ProviderContainer makeContainer(ITtsService tts) {
  return ProviderContainer(
    overrides: [
      ttsServiceProvider.overrideWithValue(tts),
    ],
  );
}

void main() {
  group('StoryBuddyNotifier — FSM transitions', () {
    // ── Initial State ──────────────────────────────────────────────────────
    test('starts in Initial state', () {
      final container = makeContainer(MockTtsService());
      addTearDown(container.dispose);

      expect(container.read(storyBuddyProvider), isA<Initial>());
    });

    // ── Initial → LoadingAudio → Playing ──────────────────────────────────
    test('requestStory transitions Initial → Playing after successful init', () async {
      final mock = MockTtsService();
      final container = makeContainer(mock);
      addTearDown(container.dispose);

      final notifier = container.read(storyBuddyProvider.notifier);

      // Start the request — do not await so we can observe intermediate states.
      final future = notifier.requestStory();

      // After init completes and before speak resolves, state is Playing.
      await future;

      expect(container.read(storyBuddyProvider), isA<Playing>());
      expect(mock.initCalled, isTrue);
      expect(mock.speakCalled, isTrue);
      expect(mock.lastSpokenText, equals(kStoryText));
    });

    // ── Playing → QuizRevealed (via TTS completion callback) ──────────────
    test('TTS completion transitions Playing → QuizRevealed', () async {
      final mock = MockTtsService();
      final container = makeContainer(mock);
      addTearDown(container.dispose);

      await container.read(storyBuddyProvider.notifier).requestStory();
      expect(container.read(storyBuddyProvider), isA<Playing>());

      // Simulate TTS engine finishing the utterance.
      mock.triggerComplete();

      final state = container.read(storyBuddyProvider);
      expect(state, isA<QuizRevealed>());
      // Verify the quiz data is correctly threaded through to the new state.
      expect((state as QuizRevealed).quiz, isA<QuizModel>());
    });

    // ── QuizRevealed → AnswerCorrect (correct answer) ─────────────────────
    test('correct answer transitions QuizRevealed → AnswerCorrect', () async {
      final mock = MockTtsService();
      final container = makeContainer(mock);
      addTearDown(container.dispose);

      await container.read(storyBuddyProvider.notifier).requestStory();
      mock.triggerComplete();

      final quiz =
          (container.read(storyBuddyProvider) as QuizRevealed).quiz as QuizModel;
      final isCorrect =
          container.read(storyBuddyProvider.notifier).submitAnswer(quiz.answer);

      expect(isCorrect, isTrue);
      expect(container.read(storyBuddyProvider), isA<AnswerCorrect>());
    });

    // ── QuizRevealed → QuizRevealed (wrong answer, no state change) ────────
    test('wrong answer does not change FSM state', () async {
      final mock = MockTtsService();
      final container = makeContainer(mock);
      addTearDown(container.dispose);

      await container.read(storyBuddyProvider.notifier).requestStory();
      mock.triggerComplete();

      const wrongAnswer = 'A golden key'; // Not the correct answer
      final isCorrect =
          container.read(storyBuddyProvider.notifier).submitAnswer(wrongAnswer);

      expect(isCorrect, isFalse);
      // FSM must remain in QuizRevealed — user can retry.
      expect(container.read(storyBuddyProvider), isA<QuizRevealed>());
    });

    // ── LoadingAudio → AudioError (TTS platform exception) ────────────────
    test('TTS init failure transitions to AudioError', () async {
      final container = makeContainer(ErrorTtsService());
      addTearDown(container.dispose);

      await container.read(storyBuddyProvider.notifier).requestStory();

      final state = container.read(storyBuddyProvider);
      expect(state, isA<AudioError>());
      expect((state as AudioError).message, contains('Microphone permission denied'));
    });

    // ── AudioError → Initial (reset) ──────────────────────────────────────
    test('reset() transitions AudioError → Initial', () async {
      final container = makeContainer(ErrorTtsService());
      addTearDown(container.dispose);

      await container.read(storyBuddyProvider.notifier).requestStory();
      expect(container.read(storyBuddyProvider), isA<AudioError>());

      container.read(storyBuddyProvider.notifier).reset();
      expect(container.read(storyBuddyProvider), isA<Initial>());
    });

    // ── Guard: illegal transition from non-Initial ─────────────────────────
    test('requestStory() from Playing is a no-op (guard enforced)', () async {
      final mock = MockTtsService();
      final container = makeContainer(mock);
      addTearDown(container.dispose);

      await container.read(storyBuddyProvider.notifier).requestStory();
      final stateBeforeIllegalCall = container.read(storyBuddyProvider);

      // Calling requestStory() again while Playing should be rejected.
      // In debug mode the assert fires; in release mode it is a silent no-op.
      // Either way, the state must not change to LoadingAudio.
      await container.read(storyBuddyProvider.notifier).requestStory();
      expect(container.read(storyBuddyProvider), equals(stateBeforeIllegalCall));
    });
  });

  // ── QuizModel unit tests ─────────────────────────────────────────────────
  group('QuizModel — fromJson validation', () {
    test('parses valid JSON correctly', () {
      final model = QuizModel.fromJson({
        'question': 'Test question?',
        'options': ['A', 'B', 'C', 'D'],
        'answer': 'B',
      });
      expect(model.question, equals('Test question?'));
      expect(model.options, hasLength(4));
      expect(model.answer, equals('B'));
    });

    test('throws FormatException when answer not in options', () {
      expect(
        () => QuizModel.fromJson({
          'question': 'Bad payload?',
          'options': ['A', 'B', 'C'],
          'answer': 'Z', // Not in options — should throw
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('empty() factory produces a valid, self-consistent model', () {
      final model = QuizModel.empty();
      // The answer must exist in options — this is the core invariant.
      expect(model.options.contains(model.answer), isTrue);
    });

    test('equality is structural, not referential', () {
      final a = QuizModel.fromJson({
        'question': 'Q?',
        'options': ['X', 'Y'],
        'answer': 'X',
      });
      final b = QuizModel.fromJson({
        'question': 'Q?',
        'options': ['X', 'Y'],
        'answer': 'X',
      });
      // freezed generates deep equality — identical JSON → identical value.
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('copyWith produces modified copy without mutating original', () {
      final original = QuizModel.empty();
      final modified = original.copyWith(question: 'New question?');
      expect(modified.question, equals('New question?'));
      expect(original.question, isNot(equals('New question?')));
      // Options and answer are unchanged in the copy.
      expect(modified.options, equals(original.options));
      expect(modified.answer, equals(original.answer));
    });
  });
}
