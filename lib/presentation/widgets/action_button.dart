// lib/presentation/widgets/action_button.dart
//
// The primary CTA button. Its appearance is driven entirely by FSM state,
// read via a scoped Consumer so only this widget rebuilds on state changes.
// Uses Semantics with a descriptive hint for screen-reader users.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peblo_ai_buddy/application/providers.dart';
import 'package:peblo_ai_buddy/domain/state/story_buddy_state.dart';
import 'package:peblo_ai_buddy/presentation/theme/app_theme.dart';

class ActionButton extends ConsumerStatefulWidget {
  const ActionButton({super.key});

  @override
  ConsumerState<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends ConsumerState<ActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 400),
    );

    // Scales to 0.95 on press, elastic bounce on release
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _pressController.forward();

  void _onTapUp(TapUpDetails _, bool isError, bool isDisabled) {
    _pressController.reverse();
    if (isDisabled) return;
    
    if (isError) {
      ref.read(storyBuddyProvider.notifier).reset();
    } else {
      ref.read(storyBuddyProvider.notifier).requestStory();
    }
  }

  void _onTapCancel() => _pressController.reverse();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storyBuddyProvider);

    final isHidden = state is QuizRevealed || state is AnswerCorrect || state is AnswerWrong;
    if (isHidden) return const SizedBox.shrink();

    final isLoading = state is LoadingAudio;
    final isPlaying = state is Playing;
    final isError = state is AudioError;

    final (String label, String a11yLabel, String a11yHint) = switch (state) {
      Initial() => (
          'Read Me a Story!',
          'Read me a story',
          "Tap to hear Pip's adventure"
        ),
      LoadingAudio() => ('Loading...', 'Loading story', 'Please wait'),
      Playing() => ('Listening...', 'Story playing', 'Story is being read aloud'),
      AudioError() => ('Try Again', 'Try again', 'Tap to retry the story'),
      QuizRevealed() || AnswerCorrect() || AnswerWrong() => ('', '', ''),
    };

    final bool isDisabled = isLoading || isPlaying;

    final bgColor = isError
        ? AppColours.warningLight
        : isDisabled
            ? AppColours.electricYellow.withAlpha(140)
            : AppColours.electricYellow;
            
    final fgColor = isError ? AppColours.warning : const Color(0xFF1E293B);

    return Semantics(
      button: true,
      label: a11yLabel,
      hint: a11yHint,
      enabled: !isDisabled,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTapDown: isDisabled ? null : _onTapDown,
          onTapUp: (details) => _onTapUp(details, isError, isDisabled),
          onTapCancel: isDisabled ? null : _onTapCancel,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: isError
                  ? Border.all(color: AppColours.warning, width: 2)
                  : null,
              boxShadow: isDisabled
                  ? []
                  : [
                      BoxShadow(
                        color: isError
                            ? AppColours.errorRed.withAlpha(70)
                            : AppColours.electricYellowDark.withAlpha(150),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Color(0xFF1E293B),
                      ),
                    )
                  : isPlaying
                      ? _PulsingPlayingLabel()
                      : Text(
                          label,
                          style: AppTextStyles.buttonLabel.copyWith(
                            color: fgColor,
                          ),
                        ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pulsing "Listening…" label shown while TTS is active.
/// Uses its own AnimationController so the pulse is independent of
/// the parent rebuild cycle — no jank even if the Notifier emits rapidly.
class _PulsingPlayingLabel extends StatefulWidget {
  @override
  State<_PulsingPlayingLabel> createState() => _PulsingPlayingLabelState();
}

class _PulsingPlayingLabelState extends State<_PulsingPlayingLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    // Pulse controller must be disposed so the repeat() vsync callback
    // does not continue after this widget leaves the tree.
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.graphic_eq_rounded, size: 22, color: Color(0xFF1E293B)),
          const SizedBox(width: 8),
          Text(
            'Listening…',
            style: AppTextStyles.buttonLabel,
          ),
        ],
      ),
    );
  }
}
