// GENERATED CODE - DO NOT MODIFY BY HAND
// dart run build_runner build --delete-conflicting-outputs

// ignore_for_file: type=lint

part of 'quiz_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QuizModelImpl _$$QuizModelImplFromJson(Map<String, dynamic> json) =>
    _$QuizModelImpl(
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>).map((e) => e as String).toList(),
      answer: json['answer'] as String,
    );

Map<String, dynamic> _$$QuizModelImplToJson(_$QuizModelImpl instance) =>
    <String, dynamic>{
      'question': instance.question,
      'options': instance.options,
      'answer': instance.answer,
    };
