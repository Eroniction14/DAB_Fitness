import 'package:flutter/material.dart';

/// DAB Fitness design system ("clean & light", see DESIGN.md).
///
/// This is the only file allowed to define colours, font sizes, radii and
/// shadows. Screens read them from `Theme.of(context)`, [AppColors]
/// (`context.appColors`), [AppSpacing] and [AppRadius].
/// `test/design_tokens_test.dart` enforces this.
abstract final class AppTheme {
  static const seed = Color(0xFF0F9D8A);
  static const fontFamily = 'PlusJakartaSans';

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colors =
        brightness == Brightness.light ? AppColors.light : AppColors.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    ).copyWith(
      surface: colors.card,
      onSurface: colors.textPrimary,
      onSurfaceVariant: colors.textSecondary,
      outlineVariant: colors.divider,
      surfaceContainerLowest: colors.card,
      surfaceContainerLow: colors.card,
      surfaceContainer: colors.inputFill,
      surfaceContainerHighest: colors.inputFill,
    );
    final text = _textTheme(scheme);

    final buttonShape =
        WidgetStatePropertyAll<OutlinedBorder>(const StadiumBorder());
    const buttonSize = WidgetStatePropertyAll(Size(64, 52));
    final buttonText = WidgetStatePropertyAll(text.labelLarge);
    const buttonPadding =
        WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: AppSpacing.xl));

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: BorderSide.none,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      dividerColor: colors.divider,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          shape: buttonShape,
          minimumSize: buttonSize,
          textStyle: buttonText,
          padding: buttonPadding,
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: buttonShape,
          minimumSize: buttonSize,
          textStyle: buttonText,
          padding: buttonPadding,
          side: WidgetStatePropertyAll(BorderSide(color: colors.divider)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: buttonShape,
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          textStyle: buttonText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          shape: buttonShape,
          minimumSize: buttonSize,
          textStyle: buttonText,
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: const StadiumBorder(),
        extendedTextStyle: text.labelLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
            borderSide: BorderSide(color: scheme.primary, width: 2)),
        errorBorder: inputBorder.copyWith(
            borderSide: BorderSide(color: scheme.error, width: 1.5)),
        focusedErrorBorder: inputBorder.copyWith(
            borderSide: BorderSide(color: scheme.error, width: 2)),
        labelStyle: text.bodyLarge?.copyWith(color: colors.inputLabel),
        floatingLabelStyle: text.bodyLarge?.copyWith(color: scheme.primary),
        hintStyle: text.bodyLarge?.copyWith(color: colors.inputLabel),
        errorStyle: text.bodySmall?.copyWith(color: scheme.error),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: colors.inputFill,
        labelStyle: text.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          side: WidgetStatePropertyAll(BorderSide(color: colors.divider)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.textSecondary,
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle:
            text.bodyMedium?.copyWith(color: colors.textSecondary),
        minVerticalPadding: AppSpacing.md,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      ),
      dividerTheme: DividerThemeData(color: colors.divider, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle:
            text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        actionTextColor: scheme.inversePrimary,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.input)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: colors.divider,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sheet)),
        titleTextStyle: text.titleLarge,
        contentTextStyle:
            text.bodyMedium?.copyWith(color: colors.textSecondary),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    );
  }

  /// The type scale from DESIGN.md on Material 3 slots:
  /// display 32/bold, title 22/semibold, heading 18/semibold,
  /// body 16/regular, label 14/medium, caption 12/regular.
  static TextTheme _textTheme(ColorScheme scheme) {
    TextStyle style(double size, FontWeight weight,
            {Color? color, double? height}) =>
        TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          fontWeight: weight,
          height: height,
          color: color ?? scheme.onSurface,
          letterSpacing: 0,
        );
    final display = style(32, FontWeight.w700, height: 1.2);
    final title = style(22, FontWeight.w600, height: 1.25);
    final heading = style(18, FontWeight.w600, height: 1.3);
    final body = style(16, FontWeight.w400, height: 1.45);
    final label = style(14, FontWeight.w500, height: 1.3);
    final caption = style(12, FontWeight.w400,
        color: scheme.onSurfaceVariant, height: 1.35);
    return TextTheme(
      displayLarge: display,
      displayMedium: display,
      displaySmall: display,
      headlineLarge: title,
      headlineMedium: title,
      headlineSmall: title,
      titleLarge: title,
      titleMedium: heading,
      titleSmall: label.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: body,
      bodyMedium: body,
      bodySmall: caption,
      labelLarge: label,
      labelMedium: style(12, FontWeight.w500),
      labelSmall: style(12, FontWeight.w500),
    );
  }
}

/// Spacing scale (DESIGN.md): 4, 8, 12, 16, 24, 32; screen side padding 20.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Left/right padding of every screen.
  static const screen = 20.0;

  /// Padding inside cards.
  static const card = 16.0;

  /// Minimum tap target.
  static const tapTarget = 48.0;
}

/// Corner radii (DESIGN.md). Buttons are stadium-shaped.
abstract final class AppRadius {
  static const card = 20.0;
  static const input = 14.0;
  static const sheet = 28.0;
  static const chip = 999.0;

  static BorderRadius get cardAll => BorderRadius.circular(card);
  static BorderRadius get inputAll => BorderRadius.circular(input);
}

/// Colours that aren't part of Material's [ColorScheme], per brightness.
/// Read with `context.appColors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  /// Screen background behind cards.
  final Color background;

  /// Cards, sheets, navigation bar.
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color inputFill;

  /// Labels and hints inside filled inputs: a step darker than
  /// [textSecondary] in light mode so they meet WCAG AA on [inputFill].
  final Color inputLabel;
  final Color warning;

  /// The single soft card shadow.
  final List<BoxShadow> cardShadow;

  /// Text and icons drawn on top of photos (with [photoScrim] behind).
  final Color onPhoto;

  /// Bottom-up gradient that keeps text on photos readable.
  final Gradient photoScrim;

  /// Translucent pill behind chips drawn on photos.
  final Color photoChip;

  /// Panel behind the onboarding illustrations (they have white
  /// backgrounds, so this stays white in dark mode too).
  final Color illustration;

  /// The video call screen stays dark in both themes.
  final Color callBackground;
  final Color onCall;

  /// Star ratings.
  final Color rating;

  /// The "LIVE" badge on classes happening now.
  final Color live;
  final Color onLive;

  const AppColors({
    required this.background,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.inputFill,
    required this.inputLabel,
    required this.warning,
    required this.cardShadow,
    required this.onPhoto,
    required this.photoScrim,
    required this.photoChip,
    required this.illustration,
    required this.rating,
    required this.callBackground,
    required this.onCall,
    required this.live,
    required this.onLive,
  });

  static const _scrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0xB3000000)],
    stops: [0.35, 1],
  );

  static const light = AppColors(
    background: Color(0xFFF7F8FA),
    card: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1A1D21),
    textSecondary: Color(0xFF6B7280),
    divider: Color(0xFFE5E7EB),
    inputFill: Color(0xFFEEF0F3),
    inputLabel: Color(0xFF4B5563),
    warning: Color(0xFFB45309),
    cardShadow: [
      BoxShadow(color: Color(0x0F000000), blurRadius: 24, offset: Offset(0, 8)),
    ],
    onPhoto: Color(0xFFFFFFFF),
    photoScrim: _scrim,
    photoChip: Color(0x8C000000),
    illustration: Color(0xFFFFFFFF),
    rating: Color(0xFFF59E0B),
    callBackground: Color(0xFF000000),
    onCall: Color(0xFFFFFFFF),
    live: Color(0xFFD32F2F),
    onLive: Color(0xFFFFFFFF),
  );

  static const dark = AppColors(
    background: Color(0xFF0E1113),
    card: Color(0xFF181C20),
    textPrimary: Color(0xFFE7E9EC),
    textSecondary: Color(0xFFA1A8B3),
    divider: Color(0xFF2B3137),
    inputFill: Color(0xFF22272C),
    inputLabel: Color(0xFFA1A8B3),
    warning: Color(0xFFFBBF24),
    cardShadow: [
      BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8)),
    ],
    onPhoto: Color(0xFFFFFFFF),
    photoScrim: _scrim,
    photoChip: Color(0x8C000000),
    illustration: Color(0xFFFFFFFF),
    rating: Color(0xFFFBBF24),
    callBackground: Color(0xFF000000),
    onCall: Color(0xFFFFFFFF),
    live: Color(0xFFEF5350),
    onLive: Color(0xFF1A0000),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? card,
    Color? textPrimary,
    Color? textSecondary,
    Color? divider,
    Color? inputFill,
    Color? inputLabel,
    Color? warning,
    List<BoxShadow>? cardShadow,
    Color? onPhoto,
    Gradient? photoScrim,
    Color? photoChip,
    Color? illustration,
    Color? rating,
    Color? callBackground,
    Color? onCall,
    Color? live,
    Color? onLive,
  }) =>
      AppColors(
        background: background ?? this.background,
        card: card ?? this.card,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        divider: divider ?? this.divider,
        inputFill: inputFill ?? this.inputFill,
        inputLabel: inputLabel ?? this.inputLabel,
        warning: warning ?? this.warning,
        cardShadow: cardShadow ?? this.cardShadow,
        onPhoto: onPhoto ?? this.onPhoto,
        photoScrim: photoScrim ?? this.photoScrim,
        photoChip: photoChip ?? this.photoChip,
        illustration: illustration ?? this.illustration,
        rating: rating ?? this.rating,
        callBackground: callBackground ?? this.callBackground,
        onCall: onCall ?? this.onCall,
        live: live ?? this.live,
        onLive: onLive ?? this.onLive,
      );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: c(background, other.background),
      card: c(card, other.card),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      divider: c(divider, other.divider),
      inputFill: c(inputFill, other.inputFill),
      inputLabel: c(inputLabel, other.inputLabel),
      warning: c(warning, other.warning),
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t)!,
      onPhoto: c(onPhoto, other.onPhoto),
      photoScrim: Gradient.lerp(photoScrim, other.photoScrim, t)!,
      photoChip: c(photoChip, other.photoChip),
      illustration: c(illustration, other.illustration),
      rating: c(rating, other.rating),
      callBackground: c(callBackground, other.callBackground),
      onCall: c(onCall, other.onCall),
      live: c(live, other.live),
      onLive: c(onLive, other.onLive),
    );
  }
}

extension AppThemeContext on BuildContext {
  /// The [AppColors] of the current theme.
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;

  TextTheme get textStyles => Theme.of(this).textTheme;

  ColorScheme get colors => Theme.of(this).colorScheme;
}
