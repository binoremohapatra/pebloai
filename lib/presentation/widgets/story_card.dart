// lib/presentation/widgets/story_card.dart
//
// Displays the story text with a staggered entrance animation (fade + slide up)
// and a typewriter effect that syncs with the TTS utterance.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peblo_ai_buddy/application/providers.dart';
import 'package:peblo_ai_buddy/application/story_buddy_notifier.dart';
import 'package:peblo_ai_buddy/domain/state/story_buddy_state.dart';
import 'package:peblo_ai_buddy/presentation/theme/app_theme.dart';

class StoryCard extends ConsumerStatefulWidget {
  const StoryCard({super.key});

  @override
  ConsumerState<StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends ConsumerState<StoryCard>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  late final AnimationController _typewriterController;
  late final Animation<int> _charCountAnim;

  @override
  void initState() {
    super.initState();

    // Entrance Animation
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    // Typewriter Animation: roughly 45ms per character to match speech rate 0.45
    _typewriterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 45 * kStoryText.length),
    );
    _charCountAnim = IntTween(begin: 0, end: kStoryText.length).animate(
      CurvedAnimation(parent: _typewriterController, curve: Curves.linear),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _typewriterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to state changes to trigger the typewriter effect
    ref.listen(storyBuddyProvider, (previous, next) {
      if (next is Playing && previous is! Playing) {
        _typewriterController.forward(from: 0.0);
      } else if (next is Initial) {
        _typewriterController.reset();
      }
    });

    // If the widget rebuilds and we're already past the playing state, ensure text is fully visible.
    final currentState = ref.read(storyBuddyProvider);
    if (currentState is QuizRevealed || currentState is AnswerCorrect || currentState is AnswerWrong) {
      if (!_typewriterController.isCompleted) {
        _typewriterController.value = 1.0;
      }
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Semantics(
          label: 'Story text. ${kStoryText.replaceAll('…', '.')}',
          excludeSemantics: true,
          child: Card(
            elevation: 6,
            shadowColor: AppColours.skyBlue.withAlpha(60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.card),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFEFF6FF),
                    Color(0xFFFFFBEB),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColours.skyBlue,
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            SizedBox(width: 5),
                            Text(
                              "Pip's Story",
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
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Stack allows the invisible full text to preserve the correct
                  // bounding box height while the animated text types out over it,
                  // preventing the card from jittering vertically as lines wrap.
                  Stack(
                    children: [
                      Text(
                        kStoryText,
                        style: AppTextStyles.storyBody.copyWith(color: Colors.transparent),
                      ),
                      AnimatedBuilder(
                        animation: _charCountAnim,
                        builder: (context, child) {
                          return Text(
                            kStoryText.substring(0, _charCountAnim.value),
                            style: AppTextStyles.storyBody,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
