import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
/// The [AppTheme] defines light and dark themes for the app.
///
/// Theme setup for FlexColorScheme package v8.
/// Use same major flex_color_scheme package version. If you use a
/// lower minor version, some properties may not be supported.
/// In that case, remove them after copying this theme to your
/// app or upgrade package to version 8.1.0.
///
/// Use in [MaterialApp] like this:
///
/// MaterialApp(
///   theme: AppTheme.light,
///   darkTheme: AppTheme.dark,
///     :
/// );
abstract final class AppTheme {
  // The defined light theme.
  static ThemeData light = FlexThemeData.light(fontFamily: GoogleFonts.montserrat().fontFamily,
  colors: const FlexSchemeColor( // Custom colors
    primary: Color(0xFFFFC107),
    primaryContainer: Color(0xFF657990),
    primaryLightRef: Color(0xFFFFC107),
    secondary: Color(0xFF616161),
    secondaryContainer: Color(0xFFBDBDBD),
    secondaryLightRef: Color(0xFF616161),
    tertiary: Color(0xFF7D80AA),
    tertiaryContainer: Color(0xFF3A3D78),
    tertiaryLightRef: Color(0xFF7D80AA),
    appBarColor: Color(0xFFBDBDBD),
    error: Color(0xFFBA1A1A),
    errorContainer: Color(0xFFFFDAD6),
  ),
  subThemesData: const FlexSubThemesData(
    interactionEffects: true,
    tintedDisabledControls: true,
    useM2StyleDividerInM3: true,
    inputDecoratorIsFilled: true,
    inputDecoratorBorderType: FlexInputBorderType.outline,
    alignedDropdown: true,
    navigationRailUseIndicator: true,
    navigationRailLabelType: NavigationRailLabelType.all,
  ),
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
  cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );
  // The defined dark theme.
  static ThemeData dark = FlexThemeData.dark( fontFamily: GoogleFonts.montserrat().fontFamily,
  colors: const FlexSchemeColor( // Custom colors
    primary: Color(0xFFFFC107),
    primaryContainer: Color(0xFF343434),
    primaryLightRef: Color(0xFFFFC107),
    secondary: Color(0xFF959595),
    secondaryContainer: Color(0xFF7A6426),
    secondaryLightRef: Color(0xFF616161),
    tertiary: Color(0xFFB0C37A),
    tertiaryContainer: Color(0xFF1D0059),
    tertiaryLightRef: Color(0xFF7D80AA),
    appBarColor: Color(0xFFBDBDBD),
    error: Color(0xFFC37A7A),
    errorContainer: Color(0xFF93000A),
  ),
  subThemesData: const FlexSubThemesData(
    interactionEffects: true,
    tintedDisabledControls: true,
    blendOnColors: true,
    useM2StyleDividerInM3: true,
    inputDecoratorIsFilled: true,
    inputDecoratorBorderType: FlexInputBorderType.outline,
    alignedDropdown: true,
    navigationRailUseIndicator: true,
    navigationRailLabelType: NavigationRailLabelType.all,
  ),
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
  cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );
}
