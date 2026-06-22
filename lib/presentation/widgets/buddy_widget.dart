// lib/presentation/widgets/buddy_widget.dart
//
// Displays the AI Buddy character (Pip the Robot) and reacts independently
// to FSM state changes via its own Consumer scope. Wrapped in RepaintBoundary
// so its animation does not trigger a repaint pass on sibling widgets.
//
// ANIMATIONS:
//   • Rive State Machine Integration: Animations are isolated within the Rive
//     engine. We toggle `isHappy` and `isShaking` SMIBool inputs based on FSM state.
//   • Glow shadow — morphs from blue → warm yellow on AnswerCorrect.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart';
import 'package:peblo_ai_buddy/application/providers.dart';
import 'package:peblo_ai_buddy/domain/state/story_buddy_state.dart';
import 'package:peblo_ai_buddy/presentation/theme/app_theme.dart';

class BuddyWidget extends StatelessWidget {
  const BuddyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Semantics(
        label: 'Pip the Robot, your story buddy',
        child: Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(storyBuddyProvider);
            final isHappy = state is AnswerCorrect || state is Playing;
            final isShaking = state is AnswerWrong;
            return _BuddyAnimated(isHappy: isHappy, isShaking: isShaking);
          },
        ),
      ),
    );
  }
}

class _BuddyAnimated extends StatefulWidget {
  const _BuddyAnimated({required this.isHappy, required this.isShaking});
  final bool isHappy;
  final bool isShaking;

  @override
  State<_BuddyAnimated> createState() => _BuddyAnimatedState();
}

class _BuddyAnimatedState extends State<_BuddyAnimated> {
  SMIBool? _isHappyInput;
  SMIBool? _isShakingInput;

  @override
  void didUpdateWidget(_BuddyAnimated oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isHappy != widget.isHappy) {
      _isHappyInput?.value = widget.isHappy;
    }
    if (oldWidget.isShaking != widget.isShaking) {
      _isShakingInput?.value = widget.isShaking;
    }
  }

  void _onRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1', // Common default name in Rive, adapt if needed
    );
    if (controller != null) {
      artboard.addController(controller);
      _isHappyInput = controller.findInput<bool>('isHappy') as SMIBool?;
      _isShakingInput = controller.findInput<bool>('isShaking') as SMIBool?;

      _isHappyInput?.value = widget.isHappy;
      _isShakingInput?.value = widget.isShaking;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageWidth = constraints.maxWidth * 0.72;
        final imageHeight = imageWidth * 0.65;

        return Center(
          child: AnimatedContainer(
            // Glow shadow morphs blue → warm yellow on happy.
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            width: imageWidth,
            height: imageHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: widget.isHappy
                      ? AppColours.electricYellow.withAlpha(110)
                      : AppColours.skyBlue.withAlpha(55),
                  blurRadius: 32,
                  spreadRadius: 6,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: RiveAnimation.asset(
                'assets/animations/pip.riv',
                fit: BoxFit.cover,
                onInit: _onRiveInit,
              ),
            ),
          ),
        );
      },
    );
  }
}
