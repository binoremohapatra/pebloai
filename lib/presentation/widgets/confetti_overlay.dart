// lib/presentation/widgets/confetti_overlay.dart
//
// Confetti celebration overlay, shown when FSM enters AnswerCorrect.
// Owns a ConfettiController that is properly disposed in State.dispose().
// Wrapped in RepaintBoundary so the particle system paints on its own layer —
// critical for preventing confetti from triggering full-screen repaints
// on each vsync tick (which would be fatal to 60fps on mid-range devices).

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peblo_ai_buddy/application/providers.dart';
import 'package:peblo_ai_buddy/domain/state/story_buddy_state.dart';
import 'package:peblo_ai_buddy/presentation/theme/app_theme.dart';

class ConfettiOverlay extends ConsumerStatefulWidget {
  const ConfettiOverlay({super.key});

  @override
  ConsumerState<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends ConsumerState<ConfettiOverlay> {
  late final ConfettiController _confettiController;
  bool _hasPlayed = false;

  @override
  void initState() {
    super.initState();
    // ConfettiController lifetime: 3 seconds of particle emission.
    // Longer durations waste GPU compositing time on mid-range devices.
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    // ConfettiController must be disposed to stop particle emission and
    // release the underlying animation ticker — same requirement as any
    // AnimationController derived resource.
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // select() constrains rebuilds to only fire when the AnswerCorrect
    // predicate changes — no rebuild on unrelated FSM transitions.
    final isCorrect = ref.watch(
      storyBuddyProvider.select((s) => s is AnswerCorrect),
    );

    if (isCorrect && !_hasPlayed) {
      // Fire confetti once per correct answer session — guard flag prevents
      // re-triggering on subsequent rebuilds while AnswerCorrect persists.
      _hasPlayed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _confettiController.play();
      });
    }

    // RepaintBoundary ensures the particle system composites independently.
    // Without this, every particle position update (60 per second) would
    // invalidate the paint of the entire Scaffold subtree.
    return RepaintBoundary(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _confettiController,
          // Explosive blast from the Mascot covers the entire screen!
          blastDirectionality: BlastDirectionality.explosive,
          emissionFrequency: 0.1,
          numberOfParticles: 50,
          maxBlastForce: 80,
          minBlastForce: 20,
          gravity: 0.15, // Falls slightly slower to fill the screen longer

          colors: AppColours.confettiColors,
          strokeWidth: 1.5,
          strokeColor: Colors.white.withAlpha(80),
        ),
      ),
    );
  }
}
