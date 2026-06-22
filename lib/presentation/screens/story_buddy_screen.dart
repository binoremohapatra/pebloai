// lib/presentation/screens/story_buddy_screen.dart
//
// This is the main screen of the app where the magic happens!
// The background has some cool floating blobs, and the mascot, story card,
// and action button all slide in one after another.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:peblo_ai_buddy/application/providers.dart';
import 'package:peblo_ai_buddy/domain/state/story_buddy_state.dart';
import 'package:peblo_ai_buddy/presentation/theme/app_theme.dart';
import 'package:peblo_ai_buddy/presentation/widgets/action_button.dart';
import 'package:peblo_ai_buddy/presentation/widgets/buddy_visual_engine.dart';
import 'package:peblo_ai_buddy/presentation/widgets/confetti_overlay.dart';
import 'package:peblo_ai_buddy/presentation/widgets/error_card.dart';
import 'package:peblo_ai_buddy/presentation/widgets/quiz_zone.dart';
import 'package:peblo_ai_buddy/presentation/widgets/story_card.dart';

class StoryBuddyScreen extends ConsumerWidget {
  const StoryBuddyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusLabel = ref.watch(
      storyBuddyProvider.select(_statusLabel),
    );

    return Scaffold(
      backgroundColor: AppColours.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Story Buddy',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              statusLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFFE2E8F0),
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            // A tiny pulsing star to make the app bar feel alive!
            child: _PulsingStarBadge(),
          ),
        ],
      ),
      body: const _GyroParallaxWrapper(
        background: _BackgroundDecoration(),
        foreground: const SafeArea(
          child: Column(
            children: [
              // The mascot floats at the top right away.
              // Pinned at the top so it's never covered.
              Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: BuddyVisualEngine(),
              ),
              SizedBox(height: 20),

              // Scrollable area for everything else
              Expanded(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Column(
                    children: [
                      // The story card slides in slightly after.
                      StoryCard(),
                      SizedBox(height: 20),

                      // Shows up only if audio breaks.
                      ErrorCardSlot(),

                      // The big play button.
                      _AnimatedActionButtonSlot(),
                      SizedBox(height: 20),

                      // The quiz that pops up at the end.
                      QuizZoneWidget(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        overlay: ConfettiOverlay(),
      ),
    );
  }

  static String _statusLabel(StoryBuddyState state) => switch (state) {
        Initial() => 'Tap below to start the adventure!',
        LoadingAudio() => 'Getting Pip\'s voice ready…',
        Playing() => 'Pip is talking…',
        AudioError() => 'Something went wrong',
        QuizRevealed() => 'Quiz time! Can you answer?',
        AnswerCorrect() => 'Amazing job!',
        AnswerWrong() => 'Oops! Try again!',
      };
}

// ---------------------------------------------------------------------------
// Gyroscope Parallax Wrapper
// ---------------------------------------------------------------------------
// Reads accelerometer events and translates the background/foreground to
// simulate faux-3D depth.
class _GyroParallaxWrapper extends StatefulWidget {
  const _GyroParallaxWrapper({
    required this.background,
    required this.foreground,
    required this.overlay,
  });

  final Widget background;
  final Widget foreground;
  final Widget overlay;

  @override
  State<_GyroParallaxWrapper> createState() => _GyroParallaxWrapperState();
}

class _GyroParallaxWrapperState extends State<_GyroParallaxWrapper> {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double _pitch = 0.0;
  double _roll = 0.0;

  @override
  void initState() {
    super.initState();
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      if (mounted) {
        setState(() {
          // Accelerometer values typically range around -10 to 10
          _pitch = event.y.clamp(-10.0, 10.0);
          _roll = event.x.clamp(-10.0, 10.0);
        });
      }
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background moves opposite to device tilt
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(-_roll * 4, -_pitch * 4, 0),
          child: widget.background,
        ),
        // Foreground moves slightly with device tilt for parallax
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(_roll * 2, _pitch * 2, 0),
          child: widget.foreground,
        ),
        // Overlay (like confetti) stays fixed
        widget.overlay,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Animated Action Button Slot
// ---------------------------------------------------------------------------
// Wraps ActionButton in a staggered fade+slide entrance that starts 350ms
// after the screen mounts — after BuddyWidget (0ms) and StoryCard (200ms).
class _AnimatedActionButtonSlot extends StatefulWidget {
  const _AnimatedActionButtonSlot();

  @override
  State<_AnimatedActionButtonSlot> createState() =>
      _AnimatedActionButtonSlotState();
}

class _AnimatedActionButtonSlotState extends State<_AnimatedActionButtonSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: const ActionButton(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pulsing Star Badge in AppBar
// ---------------------------------------------------------------------------
// A subtle scale pulse (1.0 ↔ 1.15) on the star avatar keeps the top-right
// corner feeling lively without distracting from the main content.
class _PulsingStarBadge extends StatefulWidget {
  const _PulsingStarBadge();

  @override
  State<_PulsingStarBadge> createState() => _PulsingStarBadgeState();
}

class _PulsingStarBadgeState extends State<_PulsingStarBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: const CircleAvatar(
        radius: 20,
        backgroundColor: AppColours.skyBlueLight,
        child: Icon(
          Icons.auto_awesome_rounded,
          size: 20,
          color: AppColours.skyBlueDark,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated Background Decoration
// ---------------------------------------------------------------------------
// Three blobs each breathe on independent looping controllers so they drift
// out of phase, giving organic depth. RepaintBoundary at the widget level
// ensures blob repaints never invalidate the scroll content above.
class _BackgroundDecoration extends StatefulWidget {
  const _BackgroundDecoration();

  @override
  State<_BackgroundDecoration> createState() => _BackgroundDecorationState();
}

class _BackgroundDecorationState extends State<_BackgroundDecoration>
    with TickerProviderStateMixin {
  late final AnimationController _blob1Ctrl;
  late final AnimationController _blob2Ctrl;
  late final AnimationController _blob3Ctrl;

  late final Animation<double> _blob1Scale;
  late final Animation<double> _blob2Scale;
  late final Animation<double> _blob3Scale;

  @override
  void initState() {
    super.initState();

    // Three different periods → they drift out of phase, feeling organic.
    _blob1Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _blob2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3100),
    )..repeat(reverse: true);

    _blob3Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _blob1Scale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _blob1Ctrl, curve: Curves.easeInOut),
    );
    _blob2Scale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _blob2Ctrl, curve: Curves.easeInOut),
    );
    _blob3Scale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _blob3Ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _blob1Ctrl.dispose();
    _blob2Ctrl.dispose();
    _blob3Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          // Top-right yellow blob
          Positioned(
            top: -60,
            right: -60,
            child: ScaleTransition(
              scale: _blob1Scale,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColours.electricYellow.withAlpha(35),
                ),
              ),
            ),
          ),
          // Bottom-left blue blob
          Positioned(
            bottom: -80,
            left: -80,
            child: ScaleTransition(
              scale: _blob2Scale,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColours.skyBlue.withAlpha(25),
                ),
              ),
            ),
          ),
          // Mid-right coral accent
          Positioned(
            top: 300,
            right: -40,
            child: ScaleTransition(
              scale: _blob3Scale,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColours.coral.withAlpha(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
