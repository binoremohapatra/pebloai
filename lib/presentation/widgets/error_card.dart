// lib/presentation/widgets/error_card.dart
//
// First-class error UI — shown when FSM enters AudioError.
// liveRegion: true on the Semantics node instructs screen readers (TalkBack,
// VoiceOver) to announce the error automatically when it appears, without
// requiring the user to focus it manually. Critical for accessibility.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peblo_ai_buddy/application/providers.dart';
import 'package:peblo_ai_buddy/domain/state/story_buddy_state.dart';
import 'package:peblo_ai_buddy/presentation/theme/app_theme.dart';

class ErrorCard extends StatelessWidget {
  const ErrorCard({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // liveRegion ensures TalkBack announces this card the moment it mounts —
      // users with visual impairments are informed of the error without needing
      // to navigate to the card.
      liveRegion: true,
      label: 'Error: $message',
      child: Container(
        decoration: BoxDecoration(
          color: AppColours.coralLight,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: AppColours.errorRed.withAlpha(120),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColours.errorRed.withAlpha(30),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: AppColours.errorRed,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Oops! Something went wrong',
                  style: AppTextStyles.errorTitle,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.errorBody,
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, _) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        ref.read(storyBuddyProvider.notifier).reset(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColours.errorRed,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps ErrorCard with an AnimatedSwitcher so it fades in/out smoothly
/// as the FSM enters and exits the AudioError state.
class ErrorCardSlot extends ConsumerWidget {
  const ErrorCardSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // select() ensures this widget only rebuilds when the AudioError
    // state changes — not on every FSM transition.
    final errorMessage = ref.watch(
      storyBuddyProvider.select((s) => s is AudioError ? s.message : null),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: errorMessage != null
          ? ErrorCard(key: const ValueKey('error_card'), message: errorMessage)
          : const SizedBox.shrink(key: ValueKey('error_empty')),
    );
  }
}
