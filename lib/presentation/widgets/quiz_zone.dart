// lib/presentation/widgets/quiz_zone.dart
//
// This is the quiz section. It fades and slides in when the story is over.
// We keep it on its own paint layer so the animations are silky smooth.
// Each button has its own bouncy tap animation!

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peblo_ai_buddy/application/providers.dart';
import 'package:peblo_ai_buddy/domain/models/quiz_model.dart';
import 'package:peblo_ai_buddy/domain/state/story_buddy_state.dart';
import 'package:peblo_ai_buddy/presentation/theme/app_theme.dart';
import 'package:peblo_ai_buddy/presentation/widgets/success_message.dart';

// ---------------------------------------------------------------------------
// Main Quiz Area - Handles showing/hiding the quiz
// ---------------------------------------------------------------------------
class QuizZoneWidget extends StatelessWidget {
  const QuizZoneWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Keep all the quiz animations separate from the rest of the app.
    return RepaintBoundary(
      child: Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(storyBuddyProvider);

          final isVisible =
              state is QuizRevealed || state is AnswerCorrect || state is AnswerWrong;

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              // Slide up and fade in at the same time.
              final slideAnimation = Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: slideAnimation,
                  child: child,
                ),
              );
            },
            child: isVisible
                ? _QuizContent(key: const ValueKey('quiz_content'), state: state)
                : const SizedBox.shrink(key: ValueKey('quiz_empty')),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quiz Content - Swaps between the question and the success message
// ---------------------------------------------------------------------------
class _QuizContent extends StatelessWidget {
  const _QuizContent({required this.state, super.key});
  final StoryBuddyState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      QuizRevealed(:final quiz) || AnswerWrong(:final quiz) => _ShakeableQuizCard(
          quiz: quiz as QuizModel,
        ),
      AnswerCorrect(:final quiz) => Column(
          children: [
            const SuccessMessage(),
            const SizedBox(height: 16),
            // Show the answered quiz card so the user can see what they got right.
            _AnsweredQuizCard(quiz: quiz as QuizModel),
          ],
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

// ---------------------------------------------------------------------------
// Shakeable Quiz Card - Wiggles if the user gets the answer wrong
// ---------------------------------------------------------------------------
class _ShakeableQuizCard extends StatefulWidget {
  const _ShakeableQuizCard({required this.quiz});
  final QuizModel quiz;

  @override
  State<_ShakeableQuizCard> createState() => _ShakeableQuizCardState();
}

class _ShakeableQuizCardState extends State<_ShakeableQuizCard>
    with TickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeOffset;

  late final AnimationController _typewriterController;
  late final Animation<int> _charCountAnim;

  // Tracks whether to show the red tint on the card background.
  bool _showRedTint = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // A quick left-to-right wiggle animation.
    _shakeOffset = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: -12),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -12, end: 12),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 12, end: -8),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -8, end: 8),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 8, end: -4),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -4, end: 4),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 4, end: 0),
        weight: 1,
      ),
    ]).animate(_shakeController);

    // Typewriter Animation
    _typewriterController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 45 * widget.quiz.question.length),
    );
    _charCountAnim = IntTween(begin: 0, end: widget.quiz.question.length).animate(
      CurvedAnimation(parent: _typewriterController, curve: Curves.linear),
    );

    // Start typing right away.
    _typewriterController.forward();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _typewriterController.dispose();
    super.dispose();
  }

  Future<void> _onOptionTapped(String selected, WidgetRef ref) async {
    unawaited(HapticFeedback.mediumImpact());

    final isCorrect =
        ref.read(storyBuddyProvider.notifier).submitAnswer(selected);

    if (!isCorrect) {
      unawaited(AudioPlayer().play(AssetSource('sounds/buzz.mp3')));
      setState(() => _showRedTint = true);
      await _shakeController.forward(from: 0.0);
      if (mounted) {
        setState(() => _showRedTint = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeOffset,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeOffset.value, 0),
          child: child,
        );
      },
      child: Consumer(
        builder: (context, ref, _) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: _showRedTint
                  ? Colors.red.shade100
                  : AppColours.quizCardSurface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: _showRedTint
                    ? AppColours.errorRed.withAlpha(150)
                    : AppColours.skyBlue.withAlpha(80),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _showRedTint
                      ? AppColours.errorRed.withAlpha(40)
                      : AppColours.skyBlue.withAlpha(40),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cute little "Quick Quiz!" badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColours.coral,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lightbulb_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Quick Quiz!',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Stack(
                    children: [
                      Text(
                        widget.quiz.question,
                        style: AppTextStyles.quizQuestion.copyWith(color: Colors.transparent),
                      ),
                      AnimatedBuilder(
                        animation: _charCountAnim,
                        builder: (context, child) {
                          return Text(
                            widget.quiz.question.substring(0, _charCountAnim.value),
                            style: AppTextStyles.quizQuestion,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Loop through all options and make a button for each.
                  // We stagger them so they pop in one by one.
                  ...widget.quiz.options.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PressableOptionButton(
                        index: entry.key,
                        label: entry.value,
                        entranceDelayMs: 100 + entry.key * 70,
                        onTap: () => _onOptionTapped(entry.value, ref),
                        onTapDown: (details) {
                          ref.read(tapPositionProvider.notifier).state = details.globalPosition;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bouncy Option Button
// ---------------------------------------------------------------------------
// Shrinks when you press it, and bounces back when you let go.
class _PressableOptionButton extends StatefulWidget {
  const _PressableOptionButton({
    required this.index,
    required this.label,
    required this.onTap,
    required this.entranceDelayMs,
    this.onTapDown,
  });

  final int index;
  final String label;
  final VoidCallback onTap;
  final ValueChanged<TapDownDetails>? onTapDown;
  final int entranceDelayMs;

  static const List<Color> _optionColors = [
    AppColours.skyBlue,
    AppColours.coral,
    AppColours.electricYellow,
    AppColours.success,
  ];

  @override
  State<_PressableOptionButton> createState() => _PressableOptionButtonState();
}

class _PressableOptionButtonState extends State<_PressableOptionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scale;

  // Entrance animation state
  double _entranceOpacity = 0.0;
  Offset _entranceOffset = const Offset(0, 0.3);

  @override
  void initState() {
    super.initState();

    // The squish effect when tapped.
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 400),
    );

    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeIn),
    );

    // Slide the button in after a short delay.
    Future.delayed(Duration(milliseconds: widget.entranceDelayMs), () {
      if (mounted) {
        setState(() {
          _entranceOpacity = 1.0;
          _entranceOffset = Offset.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    widget.onTapDown?.call(details);
    _pressController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _pressController.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _pressController.reverse();

  @override
  Widget build(BuildContext context) {
    final accentColor = _PressableOptionButton
        ._optionColors[widget.index % _PressableOptionButton._optionColors.length];

    return AnimatedOpacity(
      opacity: _entranceOpacity,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _entranceOffset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        child: Semantics(
          button: true,
          label: widget.label,
          hint: 'Tap to select this answer',
          child: ScaleTransition(
            scale: _scale,
            child: GestureDetector(
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(color: accentColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withAlpha(40),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // The letter badge (A, B, C, etc.)
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + widget.index),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: AppTextStyles.optionLabel,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: accentColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Answered Quiz Card - Shown after they get it right
// ---------------------------------------------------------------------------
class _AnsweredQuizCard extends StatelessWidget {
  const _AnsweredQuizCard({required this.quiz});
  final QuizModel quiz;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColours.successLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColours.success, width: 1.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quiz.question,
            style: AppTextStyles.quizQuestion.copyWith(
              color: const Color(0xFF166534),
            ),
          ),
          const SizedBox(height: 12),
          ...quiz.options.asMap().entries.map((entry) {
            final isCorrect = entry.value == quiz.answer;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  color: isCorrect ? AppColours.success : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(
                    color: isCorrect
                        ? AppColours.success
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isCorrect ? Colors.white : const Color(0xFFCBD5E1),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isCorrect
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isCorrect
                              ? Colors.white
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
