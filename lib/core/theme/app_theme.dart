import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Fixed brand constants, in their light-mode values.
///
/// These stay constant on purpose so artefacts that must not follow the app
/// theme — the logo mark and the exported share card — keep one appearance in
/// both themes. Screen colours come from [AppPalette] instead.
abstract final class AppColors {
  static const canvas = Color(0xFFF6F3EC);
  static const surface = Color(0xFFFFFDF8);
  static const surfaceElevated = Color(0xFFFFFFFF);
  static const ink = Color(0xFF132238);
  static const inkMuted = Color(0xFF687384);
  static const lime = Color(0xFFB9F44A);
  static const limeLight = Color(0xFFE8FABC);
  static const limeDark = Color(0xFF668F14);
  static const aqua = Color(0xFF58D6C7);
  static const coral = Color(0xFFEF6A5B);
  static const line = Color(0xFFDDE0DA);
  static const navySoft = Color(0xFFE9EDF1);
  static const shadowColor = Color(0x14132238);

  // "Instrument" surfaces: deep ink panels that carry the lime signal colour.
  static const inkDeep = Color(0xFF0C1626);
  static const inkRaised = Color(0xFF1D2F4A);
  static const onInkMuted = Color(0xFFA9B4C4);
}

/// Every colour a screen is allowed to read, resolved for the active theme.
///
/// Read it through `context.palette` so a widget picks up the light or dark
/// value without knowing which theme is active.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.surfaceElevated,
    required this.ink,
    required this.inkMuted,
    required this.lime,
    required this.limeLight,
    required this.limeDark,
    required this.aqua,
    required this.coral,
    required this.line,
    required this.navySoft,
    required this.shadowColor,
    required this.inkDeep,
    required this.inkRaised,
    required this.onInkMuted,
    required this.onInk,
    required this.onLime,
    required this.success,
    required this.carbs,
    required this.amber,
  });

  final Brightness brightness;

  /// App background.
  final Color canvas;

  /// Default panel fill sitting on [canvas].
  final Color surface;

  /// Card fill, one step above [surface].
  final Color surfaceElevated;

  /// Primary text and icons.
  final Color ink;

  /// Secondary text.
  final Color inkMuted;

  /// Brand signal colour. Bright in both themes.
  final Color lime;

  /// Soft lime fill behind lime accents.
  final Color limeLight;

  /// Lime used as text or an icon: darker than [lime] on light, lighter on dark.
  final Color limeDark;

  final Color aqua;
  final Color coral;

  /// Hairlines and borders.
  final Color line;

  /// Neutral raised fill for pills and placeholders.
  final Color navySoft;

  final Color shadowColor;

  /// Deep instrument panels. These stay dark in both themes.
  final Color inkDeep;
  final Color inkRaised;

  /// Secondary text on an instrument panel.
  final Color onInkMuted;

  /// Text and icons on an [ink] fill.
  final Color onInk;

  /// Text and icons on a [lime] fill. Dark in both themes.
  final Color onLime;

  final Color success;
  final Color carbs;
  final Color amber;

  bool get isDark => brightness == Brightness.dark;

  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    canvas: Color(0xFFF6F3EC),
    surface: Color(0xFFFFFDF8),
    surfaceElevated: Color(0xFFFFFFFF),
    ink: Color(0xFF132238),
    inkMuted: Color(0xFF687384),
    lime: Color(0xFFB9F44A),
    limeLight: Color(0xFFE8FABC),
    limeDark: Color(0xFF668F14),
    aqua: Color(0xFF58D6C7),
    coral: Color(0xFFEF6A5B),
    line: Color(0xFFDDE0DA),
    navySoft: Color(0xFFE9EDF1),
    shadowColor: Color(0x14132238),
    inkDeep: Color(0xFF0C1626),
    inkRaised: Color(0xFF1D2F4A),
    onInkMuted: Color(0xFFA9B4C4),
    onInk: Color(0xFFFFFFFF),
    onLime: Color(0xFF132238),
    success: Color(0xFF168B78),
    carbs: Color(0xFFE39B2A),
    amber: Color(0xFFC98412),
  );

  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    canvas: Color(0xFF0B121C),
    surface: Color(0xFF141C28),
    surfaceElevated: Color(0xFF1A2432),
    ink: Color(0xFFEDF2F8),
    inkMuted: Color(0xFF9BA8B9),
    lime: Color(0xFFB9F44A),
    limeLight: Color(0xFF2B3A17),
    limeDark: Color(0xFFCDF77A),
    aqua: Color(0xFF63DDCE),
    coral: Color(0xFFFF8B7B),
    line: Color(0xFF283340),
    navySoft: Color(0xFF1F2A38),
    shadowColor: Color(0x66000000),
    inkDeep: Color(0xFF060B13),
    inkRaised: Color(0xFF18273C),
    onInkMuted: Color(0xFFA9B4C4),
    onInk: Color(0xFF0B121C),
    onLime: Color(0xFF0C1626),
    success: Color(0xFF4FD1B5),
    carbs: Color(0xFFF0B457),
    amber: Color(0xFFE8A93C),
  );

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? canvas,
    Color? surface,
    Color? surfaceElevated,
    Color? ink,
    Color? inkMuted,
    Color? lime,
    Color? limeLight,
    Color? limeDark,
    Color? aqua,
    Color? coral,
    Color? line,
    Color? navySoft,
    Color? shadowColor,
    Color? inkDeep,
    Color? inkRaised,
    Color? onInkMuted,
    Color? onInk,
    Color? onLime,
    Color? success,
    Color? carbs,
    Color? amber,
  }) {
    return AppPalette(
      brightness: brightness ?? this.brightness,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      lime: lime ?? this.lime,
      limeLight: limeLight ?? this.limeLight,
      limeDark: limeDark ?? this.limeDark,
      aqua: aqua ?? this.aqua,
      coral: coral ?? this.coral,
      line: line ?? this.line,
      navySoft: navySoft ?? this.navySoft,
      shadowColor: shadowColor ?? this.shadowColor,
      inkDeep: inkDeep ?? this.inkDeep,
      inkRaised: inkRaised ?? this.inkRaised,
      onInkMuted: onInkMuted ?? this.onInkMuted,
      onInk: onInk ?? this.onInk,
      onLime: onLime ?? this.onLime,
      success: success ?? this.success,
      carbs: carbs ?? this.carbs,
      amber: amber ?? this.amber,
    );
  }

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      lime: Color.lerp(lime, other.lime, t)!,
      limeLight: Color.lerp(limeLight, other.limeLight, t)!,
      limeDark: Color.lerp(limeDark, other.limeDark, t)!,
      aqua: Color.lerp(aqua, other.aqua, t)!,
      coral: Color.lerp(coral, other.coral, t)!,
      line: Color.lerp(line, other.line, t)!,
      navySoft: Color.lerp(navySoft, other.navySoft, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      inkDeep: Color.lerp(inkDeep, other.inkDeep, t)!,
      inkRaised: Color.lerp(inkRaised, other.inkRaised, t)!,
      onInkMuted: Color.lerp(onInkMuted, other.onInkMuted, t)!,
      onInk: Color.lerp(onInk, other.onInk, t)!,
      onLime: Color.lerp(onLime, other.onLime, t)!,
      success: Color.lerp(success, other.success, t)!,
      carbs: Color.lerp(carbs, other.carbs, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
    );
  }
}

extension AppPaletteAccess on BuildContext {
  /// The palette for the active theme.
  ///
  /// Falls back to [AppPalette.light] so a widget pumped with a bare
  /// [ThemeData] in a test still renders.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

/// Transparent system bars without a contrast scrim so Samsung's 3-button
/// navigation overlay does not sit on top of Flutter and steal taps.
///
/// [brightness] is the brightness of the app behind the bars, so the icons are
/// asked for the opposite.
SystemUiOverlayStyle systemUiOverlayStyleFor(Brightness brightness) {
  final iconBrightness = brightness == Brightness.dark
      ? Brightness.light
      : Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: iconBrightness,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: iconBrightness,
    systemNavigationBarContrastEnforced: false,
  );
}

/// Light-mode overlay style, kept const for the pre-theme launch frame.
const SystemUiOverlayStyle appSystemUiOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarContrastEnforced: false,
);

ThemeData buildAppTheme() => buildAppThemeFor(AppPalette.light);

ThemeData buildAppDarkTheme() => buildAppThemeFor(AppPalette.dark);

ThemeData buildAppThemeFor(AppPalette palette) {
  final isDark = palette.isDark;
  final colorScheme = isDark
      ? ColorScheme.dark(
          primary: palette.ink,
          onPrimary: palette.onInk,
          secondary: palette.lime,
          onSecondary: palette.onLime,
          tertiary: palette.aqua,
          onTertiary: palette.onLime,
          error: palette.coral,
          onError: palette.onInk,
          surface: palette.surface,
          onSurface: palette.ink,
          outline: palette.line,
        )
      : ColorScheme.light(
          primary: palette.ink,
          onPrimary: palette.onInk,
          secondary: palette.lime,
          onSecondary: palette.onLime,
          tertiary: palette.aqua,
          onTertiary: palette.onLime,
          error: palette.coral,
          onError: palette.onInk,
          surface: palette.surface,
          onSurface: palette.ink,
          outline: palette.line,
        );

  final base = ThemeData(
    useMaterial3: true,
    brightness: palette.brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: palette.canvas,
    splashFactory: InkSparkle.splashFactory,
  );

  return base.copyWith(
    extensions: <ThemeExtension<dynamic>>[palette],
    textTheme: base.textTheme.copyWith(
      displayLarge: TextStyle(
        color: palette.ink,
        fontSize: 48,
        height: 0.98,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      displayMedium: TextStyle(
        color: palette.ink,
        fontSize: 38,
        height: 1.04,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      headlineLarge: TextStyle(
        color: palette.ink,
        fontSize: 30,
        height: 1.08,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      headlineMedium: TextStyle(
        color: palette.ink,
        fontSize: 24,
        height: 1.12,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(
        color: palette.ink,
        fontSize: 19,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: palette.ink,
        fontSize: 16,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(
        color: palette.ink,
        fontSize: 16,
        height: 1.6,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: palette.inkMuted,
        fontSize: 14,
        height: 1.6,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        color: palette.ink,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.canvas,
      foregroundColor: palette.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: systemUiOverlayStyleFor(palette.brightness),
      titleTextStyle: TextStyle(
        color: palette.ink,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: palette.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shadowColor: palette.shadowColor,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: palette.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.ink,
        foregroundColor: palette.onInk,
        minimumSize: const Size(64, 56),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        disabledBackgroundColor: palette.navySoft,
        disabledForegroundColor: palette.inkMuted,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.ink,
        minimumSize: const Size(64, 54),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        side: BorderSide(color: palette.ink, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: palette.surface,
      // A bright lime fill would leave light label text unreadable in dark
      // mode, so the selected chip there is a deep lime tint instead.
      selectedColor: isDark ? palette.limeLight : palette.lime,
      side: BorderSide(color: palette.line),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      labelStyle: TextStyle(color: palette.ink, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(color: palette.line, thickness: 1, space: 1),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 70,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      indicatorColor: palette.lime,
      indicatorShape: const StadiumBorder(),
      labelTextStyle: WidgetStateProperty.resolveWith(
        // The label sits on the bar itself, so it follows the theme.
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? palette.ink
              : palette.inkMuted,
          fontSize: 11.5,
          height: 1.1,
          letterSpacing: 0,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        // The selected icon sits inside the lime pill and needs onLime.
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? palette.onLime
              : palette.inkMuted,
        ),
      ),
    ),
  );
}
