// lib/domain/models/quiz_model.dart
//
// Immutable data model for the quiz payload.
// Generated equality/hashCode/copyWith from freezed guarantees correct Riverpod
// change-detection without hand-maintained boilerplate.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz_model.freezed.dart';
part 'quiz_model.g.dart';

@freezed
class QuizModel with _$QuizModel {
  // Private named constructor required by freezed — all construction goes
  // through the factory constructors below, which enforce class invariants.
  const QuizModel._();

  const factory QuizModel({
    required String question,
    required List<String> options,
    required String answer,
  }) = _QuizModel;

  // Safe JSON factory — delegates to generated _$QuizModelFromJson, then
  // runs post-parse invariant validation so malformed payloads never reach
  // the UI layer.
  factory QuizModel.fromJson(Map<String, dynamic> json) {
    final model = _$QuizModelFromJson(json);
    // Validate that the declared answer actually exists in the options list.
    // A mismatch here means the JSON contract was broken server-side; throwing
    // a FormatException surfaces this immediately in logs rather than silently
    // allowing an un-selectable correct answer.
    if (!model.options.contains(model.answer)) {
      throw FormatException(
        'QuizModel invariant violated: answer "${model.answer}" '
        'is not present in options ${model.options}. '
        'Check the JSON payload from the server.',
      );
    }
    return model;
  }

  // Fallback factory — used when JSON is completely malformed or missing.
  // Prevents null-safety violations by providing a safe, non-null default
  // that the UI can gracefully render instead of crashing.
  factory QuizModel.empty() => const QuizModel(
        question: 'What did Pip lose in the Whispering Woods?',
        options: ['A golden key', 'A shiny blue gear', 'A silver map', 'A red ribbon'],
        answer: 'A shiny blue gear',
      );
}
