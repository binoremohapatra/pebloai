// lib/presentation/widgets/success_message.dart
//
// Animated success banner shown when FSM enters AnswerCorrect.
// Uses an explicit ScaleTransition with ElasticOut curve for a playful
// overshoot that rewards the child emotionally for the correct answer.
// liveRegion: true ensures screen readers announce it on appearance.

import 'package:flutter/material.dart';
import 'package:peblo_ai_buddy/presentation/theme/app_theme.dart';

class SuccessMessage extends StatefulWidget {
  const SuccessMessage({super.key});

  @override
  State<SuccessMessage> createState() => _SuccessMessageState();
}

class _SuccessMessageState extends State<SuccessMessage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // ElasticOut produces an overshoot-and-settle motion — the text "pops"
    // in and bounces slightly before resting at full size. This tactile
    // quality is proven to increase positive emotional response in children.
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Begin the animation immediately when this widget first enters the tree —
    // it is only mounted after the AnswerCorrect FSM transition.
    _scaleController.forward();
  }

  @override
  void dispose() {
    // Release vsync ticker resource — critical to prevent a leaked animation
    // callback continuing to run against a detached render object.
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // liveRegion: true — screen reader announces success automatically.
      liveRegion: true,
      label: 'Correct! Brilliant! You got it!',
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColours.successLight,
                Color(0xFFBBF7D0),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: AppColours.success,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColours.success.withAlpha(60),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFF166534),
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Brilliant! You got it!',
                    style: AppTextStyles.successLabel,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFF166534),
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Pip is so proud of you!',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF166534),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
