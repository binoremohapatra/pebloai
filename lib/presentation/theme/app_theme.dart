// lib/presentation/theme/app_theme.dart
//
// Centralised design system for the Peblo Story Buddy feature.
// All colours, radii, and typography are defined here so widgets never
// hardcode visual values — changes to the brand palette propagate instantly.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Brand Colour Palette
// ---------------------------------------------------------------------------
abstract final class AppColours {
  // Primary: Electric Yellow — main CTAs, active states
  static const Color electricYellow = Color(0xFFFFD54F);
  static const Color electricYellowDark = Color(0xFFF6A821);

  // Secondary: Sky Blue — options and accents
  static const Color skyBlue = Color(0xFF4FC3F7);
  static const Color skyBlueDark = Color(0xFF0288D1);
  static const Color skyBlueLight = Color(0xFFE1F5FE);

  // Tertiary: Coral — highlights
  static const Color coral = Color(0xFFFF6B6B);
  static const Color coralLight = Color(0xFFFFE4E4);

  // Semantic colours
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFFF8C42);
  static const Color warningLight = Color(0xFFFFF0E0);
  static const Color errorRed = Color(0xFFEF4444);

  // Surface colours
  static const Color scaffoldBackground = Color(0xFF4C1D95); // Deep purple
  static const Color cardSurface = Color(0xFFFFFFFF); // Crisp white
  static const Color quizCardSurface = Color(0xFFFFFFFF); // Crisp white

  // Confetti palette
  static const List<Color> confettiColors = [
    electricYellow,
    coral,
    skyBlue,
    success,
    Color(0xFFB57BEE), // Purple accent
  ];
}

// ---------------------------------------------------------------------------
// Border Radii
// ---------------------------------------------------------------------------
abstract final class AppRadius {
  static const double card = 20.0;
  static const double button = 16.0;
  static const double chip = 12.0;
  static const double buddy = 24.0;
}

// ---------------------------------------------------------------------------
// Typography
// ---------------------------------------------------------------------------
abstract final class AppTextStyles {
  static final TextStyle displayTitle = GoogleFonts.nunito(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static final TextStyle storyBody = GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF334155),
    height: 1.65,
    letterSpacing: 0.1,
  );

  static final TextStyle quizQuestion = GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: const Color(0xFF1E293B),
    height: 1.4,
  );

  static final TextStyle optionLabel = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF1E293B),
  );

  static final TextStyle buttonLabel = GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.2,
  );

  static final TextStyle successLabel = GoogleFonts.nunito(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    color: const Color(0xFF166534),
    letterSpacing: 0.3,
  );

  static final TextStyle errorTitle = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: const Color(0xFF991B1B),
  );

  static final TextStyle errorBody = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF7F1D1D),
    height: 1.5,
  );
}

// ---------------------------------------------------------------------------
// Material ThemeData
// ---------------------------------------------------------------------------
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColours.scaffoldBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColours.electricYellow,
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.nunitoTextTheme(),
    cardTheme: const CardThemeData(
      elevation: 8,
      surfaceTintColor: Colors.transparent,
      color: AppColours.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColours.electricYellow,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 8,
        shadowColor: AppColours.electricYellowDark.withAlpha(150),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.button)),
        ),
        minimumSize: const Size(double.infinity, 58),
        textStyle: AppTextStyles.buttonLabel,
      ),
    ),
  );
}
