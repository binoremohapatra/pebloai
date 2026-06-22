// lib/main.dart
//
// Application entry point. ProviderScope is the root of the Riverpod
// dependency graph — all providers live and die within this scope.
// No business logic or widget code lives here; this file's sole
// responsibility is wiring Flutter's runApp with the provider tree.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peblo_ai_buddy/presentation/screens/story_buddy_screen.dart';
import 'package:peblo_ai_buddy/presentation/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait-up only — the layout is optimised for portrait and
  // landscape is out of scope for this feature evaluation.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Configure the system UI overlay to use a transparent status bar with
  // light icons — consistent with the deep purple scaffold background.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColours.scaffoldBackground,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    // ProviderScope is placed at the very root so that every provider
    // in the graph shares the same lifetime as the app itself.
    // In tests, replace this with ProviderScope(overrides: [...]) to inject
    // mock services without touching a single line of production code.
    const ProviderScope(
      child: PebloApp(),
    ),
  );
}

class PebloApp extends StatelessWidget {
  const PebloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peblo — AI Story Buddy',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),

      // SEO / accessibility metadata for the single screen
      // (title is also read by screen readers as the window label).
      home: const StoryBuddyScreen(),

      // Builder wraps the entire app in a MediaQuery override — useful for
      // text scaling guards in production; left at system default here to
      // respect the user's accessibility font size settings.
      builder: (context, child) {
        return child!;
      },
    );
  }
}
