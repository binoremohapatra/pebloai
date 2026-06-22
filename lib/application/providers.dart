// lib/application/providers.dart
//
// Centralised Riverpod provider declarations.
// All providers are top-level constants — Riverpod 2 requires this for
// compile-time provider identity checks and hot-reload correctness.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peblo_ai_buddy/application/story_buddy_notifier.dart';
import 'package:peblo_ai_buddy/domain/models/quiz_model.dart';
import 'package:peblo_ai_buddy/domain/services/i_tts_service.dart';
import 'package:peblo_ai_buddy/domain/state/story_buddy_state.dart';
import 'package:peblo_ai_buddy/infrastructure/tts/flutter_tts_service.dart';

// ---------------------------------------------------------------------------
// Interaction Providers
// ---------------------------------------------------------------------------
// Stores the global tap coordinates when an option is selected.
final tapPositionProvider = StateProvider<Offset?>((ref) => null);


// TTS Service Provider

// Provides the concrete TTS implementation to the Notifier.
// Override this in tests: ProviderScope(overrides: [
//   ttsServiceProvider.overrideWithValue(MockTtsService()),
// ])
// Using Provider (not StateProvider) because ITtsService is a long-lived
// service singleton, not a reactive state value.
final ttsServiceProvider = Provider<ITtsService>(
  (ref) {
    final service = FlutterTtsService();
    // Dispose the native TTS engine when the provider scope is destroyed,
    // preventing audio session leaks across widget tree tear-downs.
    ref.onDispose(service.dispose);
    return service;
  },
);

// ---------------------------------------------------------------------------
// Quiz Data Provider

// Parses the quiz JSON at provider-creation time. Using QuizModel.empty()
// as a safe fallback ensures the UI never receives null even if JSON is
// malformed — the app degrades gracefully with a built-in question.
final quizProvider = Provider<QuizModel>((ref) {
  const rawJson = <String, dynamic>{
    'question': 'What did Pip lose in the Whispering Woods?',
    'options': [
      'A golden key',
      'A shiny blue gear',
      'A silver map',
      'A red ribbon',
    ],
    'answer': 'A shiny blue gear',
  };

  try {
    return QuizModel.fromJson(rawJson);
  } on FormatException catch (e) {
    // Log the invariant violation for diagnostics without crashing the app.
    // The empty() factory provides a known-good question so the user can
    // still interact with the feature during a data incident.
    assert(false, 'QuizModel.fromJson failed: $e');
    return QuizModel.empty();
  }
});

// ---------------------------------------------------------------------------
// Story Buddy FSM Notifier Provider
// ---------------------------------------------------------------------------
// The single source of truth for the entire screen's lifecycle state.
// NotifierProvider is used (Riverpod 2 style) over StateNotifierProvider
// because it provides ref access inside the Notifier without needing to pass
// it through the constructor, simplifying the dependency injection pattern.
final storyBuddyProvider =
    NotifierProvider<StoryBuddyNotifier, StoryBuddyState>(
  StoryBuddyNotifier.new,
);
