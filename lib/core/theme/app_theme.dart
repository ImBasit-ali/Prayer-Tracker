import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

/// App theme configuration using flex_color_scheme
class AppTheme {
  /// Light theme with Islamic emerald green color
  static ThemeData get lightTheme {
    return FlexThemeData.light(
      scheme: FlexScheme.money, // Green-based scheme
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 7,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        blendOnColors: false,
        useTextTheme: true,
        useM2StyleDividerInM3: true,
        thickBorderWidth: 2.0,
        elevatedButtonRadius: 16.0,
        outlinedButtonRadius: 16.0,
        textButtonRadius: 16.0,
        inputDecoratorRadius: 12.0,
        fabRadius: 20.0,
        chipRadius: 12.0,
        cardRadius: 16.0,
        popupMenuRadius: 12.0,
        dialogRadius: 20.0,
        timePickerDialogRadius: 20.0,
        appBarScrolledUnderElevation: 4.0,
        bottomSheetRadius: 24.0,
        bottomSheetElevation: 8.0,
        navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
        navigationBarSelectedIconSchemeColor: SchemeColor.primary,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      // Custom colors
      primary: const Color(0xFF059669), // Emerald green
      secondary: const Color(0xFFD97706), // Gold/amber accent
    ).copyWith(
      // Custom card theme
      cardTheme: const CardThemeData(
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }

  /// Dark theme with Islamic color palette
  static ThemeData get darkTheme {
    return FlexThemeData.dark(
      scheme: FlexScheme.money,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 13,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        useTextTheme: true,
        useM2StyleDividerInM3: true,
        thickBorderWidth: 2.0,
        elevatedButtonRadius: 16.0,
        outlinedButtonRadius: 16.0,
        textButtonRadius: 16.0,
        inputDecoratorRadius: 12.0,
        fabRadius: 20.0,
        chipRadius: 12.0,
        cardRadius: 16.0,
        popupMenuRadius: 12.0,
        dialogRadius: 20.0,
        timePickerDialogRadius: 20.0,
        appBarScrolledUnderElevation: 4.0,
        bottomSheetRadius: 24.0,
        bottomSheetElevation: 8.0,
        navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
        navigationBarSelectedIconSchemeColor: SchemeColor.primary,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      // Custom colors for dark mode
      primary: const Color(0xFF10B981), // Lighter emerald for dark mode
      secondary: const Color(0xFFFBBF24), // Brighter gold for dark mode
    ).copyWith(
      // Custom card theme
      cardTheme: const CardThemeData(
        elevation: 4,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}
