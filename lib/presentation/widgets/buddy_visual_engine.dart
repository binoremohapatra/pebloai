import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peblo_ai_buddy/application/providers.dart';
import 'package:peblo_ai_buddy/domain/state/story_buddy_state.dart';
import 'package:peblo_ai_buddy/presentation/theme/app_theme.dart';

/// This widget controls the mascot's face and animations.
/// It pre-loads the images so they don't flicker when the face changes.
class BuddyVisualEngine extends ConsumerStatefulWidget {
  const BuddyVisualEngine({super.key});

  @override
  ConsumerState<BuddyVisualEngine> createState() => _BuddyVisualEngineState();
}

class _BuddyVisualEngineState extends ConsumerState<BuddyVisualEngine>
    with TickerProviderStateMixin {
  // Asset paths
  static const String _neutralAsset = 'assets/images/neutral.jpg';
  static const String _happyAsset = 'assets/images/happy.jpg';
  static const String _sadAsset = 'assets/images/sad.jpg';

  // Animation Controllers
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeOffset;
  late final Animation<double> _grayscaleAnimation;

  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Success Bounce Animation (1.0 -> 1.2 -> 1.0)
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_scaleController);

    // 2. Wrong Answer Shake & Grayscale Animation
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Decaying sinusoidal horizontal shake
    _shakeOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: -15), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -15, end: 15), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 15, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -10, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 10, end: -5), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -5, end: 5), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 5, end: 0), weight: 1),
    ]).animate(_shakeController);

    // Grayscale tint fades in quickly, holds, then fades out
    _grayscaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(_shakeController);

    // 3. Audio-Reactive Ambient Glow
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _glowAnimation = Tween<double>(begin: 10.0, end: 30.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache assets to prevent frame drops during state transitions
    precacheImage(const AssetImage(_neutralAsset), context);
    precacheImage(const AssetImage(_happyAsset), context);
    precacheImage(const AssetImage(_sadAsset), context);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _shakeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // Monitor FSM changes to trigger explicit animations
  void _listenToStateChanges(StoryBuddyState? previous, StoryBuddyState next) {
    if (next is AnswerCorrect && previous is! AnswerCorrect) {
      _scaleController.forward(from: 0.0);
    } else if (next is AnswerWrong && previous is! AnswerWrong) {
      _shakeController.forward(from: 0.0);
    }

    if (next is Playing && previous is! Playing) {
      _glowController.repeat(reverse: true);
    } else if (next is! Playing && previous is Playing) {
      _glowController.animateTo(0.0,
          duration: const Duration(milliseconds: 600), curve: Curves.easeOut);
    }
  }

  String _getAssetForState(StoryBuddyState state) {
    return switch (state) {
      Initial() || LoadingAudio() || QuizRevealed() => _neutralAsset,
      Playing() || AnswerCorrect() => _happyAsset,
      AudioError() || AnswerWrong() => _sadAsset,
    };
  }

  Color _getAuraColor(StoryBuddyState state) {
    return switch (state) {
      Initial() || LoadingAudio() || QuizRevealed() || Playing() => AppColours.skyBlue,
      AnswerCorrect() => AppColours.success,
      AudioError() || AnswerWrong() => AppColours.errorRed,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Listen to state changes to fire off one-shot animations
    ref.listen(storyBuddyProvider, _listenToStateChanges);

    // Rebuild UI on state change
    final fsmState = ref.watch(storyBuddyProvider);
    final currentAsset = _getAssetForState(fsmState);

    // Wrap in RepaintBoundary to isolate mascot animations
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = constraints.maxWidth * 0.55;
          final boxHeight = boxWidth;

          return SizedBox(
            width: boxWidth,
            height: boxHeight,
            child: AnimatedBuilder(
              animation: Listenable.merge([_scaleController, _shakeController, _glowController]),
              builder: (context, child) {
                // Determine glow values
                final glowBlur = fsmState is Playing ? _glowAnimation.value : 24.0;
                final glowSpread = fsmState is Playing ? _glowAnimation.value : 8.0;

                // Apply shake offset
                Widget mascot = Transform.translate(
                  offset: Offset(_shakeOffset.value, 0),
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(50),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: _getAuraColor(fsmState).withAlpha(150),
                            blurRadius: glowBlur,
                            spreadRadius: glowSpread,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  ),
                );

                // Apply grayscale if shaking
                if (_grayscaleAnimation.value > 0.0) {
                  // We blend the normal image with a fully desaturated version
                  // ColorFilter doesn't have an opacity/intensity natively, 
                  // but we can lerp the BlendMode.saturation effect using a color tween
                  // For grayscale, using ColorFilter.matrix is very effective.
                  final colorMatrix = _calculateGrayscaleMatrix(_grayscaleAnimation.value);
                  mascot = ColorFiltered(
                    colorFilter: ColorFilter.matrix(colorMatrix),
                    child: mascot,
                  );
                }

                return mascot;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getAuraColor(fsmState),
                    width: 6,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  // Ensures smooth cross-fade without popping
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: SizedBox.expand(
                    key: ValueKey(currentAsset),
                    child: Transform.scale(
                      scale: 1.2,
                      child: Image.asset(
                        currentAsset,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Calculates a color matrix that blends between full color (intensity=0.0)
  /// and full grayscale (intensity=1.0)
  List<double> _calculateGrayscaleMatrix(double intensity) {
    // Standard luminance weights
    const double rw = 0.2126;
    const double gw = 0.7152;
    const double bw = 0.0722;

    // The inverted intensity (how much color to keep)
    final double invInt = 1.0 - intensity;

    return <double>[
      invInt + intensity * rw, intensity * gw,          intensity * bw,          0, 0,
      intensity * rw,          invInt + intensity * gw, intensity * bw,          0, 0,
      intensity * rw,          intensity * gw,          invInt + intensity * bw, 0, 0,
      0,                       0,                       0,                       1, 0,
    ];
  }
}
