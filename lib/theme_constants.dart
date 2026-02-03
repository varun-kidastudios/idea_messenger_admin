import 'package:flutter/cupertino.dart';

class AdminTheme {
  // Colors
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color secondaryBlue = Color(0xFF60A5FA);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceGrey = Color(0xFFF5F5F7);
  static const Color textBlack = Color(0xFF1D1B20);
  static const Color textGrey = Color(0xFF8E8E93);
  static const Color textLightGrey = Color(0xFFC7C7CC);
  static const Color accentBlue = CupertinoColors.activeBlue;

  // Gradients
  static const LinearGradient blueGradient = LinearGradient(
    colors: [primaryBlue, secondaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    color: textBlack,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: textBlack,
  );

  static const TextStyle subHeading = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: textGrey,
    letterSpacing: -0.1,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textBlack,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textGrey,
  );

  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];
}
