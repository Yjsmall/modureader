import 'package:flutter/material.dart';

/// Shared visual language confirmed on the bookshelf: warm paper surfaces,
/// coral actions and restrained pastel accents. Typography remains unchanged.
abstract final class AppTheme {
  static const defaultSeed = Color(0xFFC94C35);
  static const cardRadius = 24.0;
  static const controlRadius = 14.0;

  static ColorScheme scheme({
    required Color seed,
    required Brightness brightness,
    bool trueBlack = false,
    bool eink = false,
  }) {
    if (eink) {
      return const ColorScheme.light(
        primary: Colors.black,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFEAEAEA),
        onPrimaryContainer: Colors.black,
        secondary: Colors.black,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFF0F0F0),
        onSecondaryContainer: Colors.black,
        tertiary: Colors.black,
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFEAEAEA),
        onTertiaryContainer: Colors.black,
        surface: Colors.white,
        onSurface: Colors.black,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: Colors.white,
        surfaceContainer: Colors.white,
        surfaceContainerHigh: Color(0xFFF0F0F0),
        surfaceContainerHighest: Color(0xFFEAEAEA),
        onSurfaceVariant: Colors.black,
        outline: Colors.black,
        outlineVariant: Colors.black,
      );
    }
    final dark = brightness == Brightness.dark;
    final defaultPalette = seed.toARGB32() == defaultSeed.toARGB32() ||
        seed.toARGB32() == 0xFF283142; // Previous built-in palette.
    return ColorScheme.fromSeed(
            seedColor: defaultPalette ? defaultSeed : seed,
            brightness: brightness)
        .copyWith(
      primary: defaultPalette
          ? (dark ? const Color(0xFFEA8F7B) : defaultSeed)
          : null,
      onPrimary: defaultPalette
          ? (dark ? const Color(0xFF281914) : Colors.white)
          : null,
      primaryFixed: dark && defaultPalette ? defaultSeed : null,
      onPrimaryFixed: dark && defaultPalette ? Colors.white : null,
      primaryContainer: defaultPalette
          ? (dark ? const Color(0xFF332827) : const Color(0xFFFBE9E2))
          : null,
      onPrimaryContainer: defaultPalette
          ? (dark ? const Color(0xFFF2BBAF) : const Color(0xFF9A3C2B))
          : null,
      secondary: defaultPalette
          ? (dark ? const Color(0xFF9DBEAE) : const Color(0xFF50765D))
          : null,
      secondaryContainer: defaultPalette
          ? (dark ? const Color(0xFF24322D) : const Color(0xFFE7EEE5))
          : null,
      onSecondaryContainer: defaultPalette
          ? (dark ? const Color(0xFFC9DED4) : const Color(0xFF334E3B))
          : null,
      tertiaryContainer:
          dark ? const Color(0xFF302F29) : const Color(0xFFF1ECDA),
      onTertiaryContainer:
          dark ? const Color(0xFFDDD9C5) : const Color(0xFF655A32),
      surface: dark
          ? (trueBlack ? Colors.black : const Color(0xFF141619))
          : const Color(0xFFFBF9F5),
      onSurface: dark ? const Color(0xFFECEEF0) : const Color(0xFF302D32),
      onSurfaceVariant:
          dark ? const Color(0xFFAAB0B8) : const Color(0xFF716960),
      surfaceContainerLowest:
          dark ? const Color(0xFF101215) : const Color(0xFFFFFFFF),
      surfaceContainerLow:
          dark ? const Color(0xFF191B1F) : const Color(0xFFF5F1EB),
      surfaceContainer:
          dark ? const Color(0xFF202327) : const Color(0xFFFFFDFA),
      surfaceContainerHigh:
          dark ? const Color(0xFF2A2E33) : const Color(0xFFF0ECE6),
      surfaceContainerHighest:
          dark ? const Color(0xFF343940) : const Color(0xFFEAE3D8),
      inverseSurface: dark ? const Color(0xFFE8EAED) : null,
      onInverseSurface: dark ? const Color(0xFF202327) : null,
      outline: dark ? const Color(0xFF7F8994) : const Color(0xFF8A8177),
      outlineVariant: dark ? const Color(0xFF383E46) : const Color(0xFFECE7E0),
    );
  }

  static Color surfaceShadow(ColorScheme c, double opacity) =>
      (c.brightness == Brightness.dark ? c.shadow : c.onSurface)
          .withValues(alpha: opacity);

  static Color darkOverlaySurface(ColorScheme c) =>
      c.brightness == Brightness.dark
          ? c.surfaceContainerHigh
          : c.surfaceContainer;

  static Color actionColor(ColorScheme c) =>
      c.brightness == Brightness.dark ? c.primaryFixed : c.primary;

  static Color onActionColor(ColorScheme c) =>
      c.brightness == Brightness.dark ? c.onPrimaryFixed : c.onPrimary;

  static ThemeData apply(ThemeData base, {required bool eink}) {
    final c = base.colorScheme;
    final type = base.textTheme;
    final border = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(controlRadius));
    final text = type;
    final button = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      shape: WidgetStatePropertyAll(border),
      padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
      textStyle: WidgetStatePropertyAll(text.labelLarge),
    );
    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: c.surface,
      iconTheme: IconThemeData(size: 22, color: c.onSurfaceVariant),
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 24,
        toolbarHeight: 72,
        titleTextStyle: base.appBarTheme.titleTextStyle,
        iconTheme: IconThemeData(color: c.onSurfaceVariant, size: 22),
      ),
      cardTheme: CardThemeData(
        color: c.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: eink ? 0 : 1,
        shadowColor: surfaceShadow(c, .06),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
            side: BorderSide(color: c.outlineVariant)),
      ),
      filledButtonTheme: FilledButtonThemeData(
          style: button.copyWith(
        backgroundColor: c.brightness == Brightness.dark
            ? WidgetStateProperty.resolveWith<Color?>((states) =>
                states.contains(WidgetState.disabled) ? null : actionColor(c))
            : null,
        foregroundColor: c.brightness == Brightness.dark
            ? WidgetStateProperty.resolveWith<Color?>((states) =>
                states.contains(WidgetState.disabled) ? null : onActionColor(c))
            : null,
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: button.copyWith(
              side: WidgetStatePropertyAll(BorderSide(color: c.outline)))),
      textButtonTheme: TextButtonThemeData(style: button),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: button.copyWith(elevation: const WidgetStatePropertyAll(0))),
      iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
              minimumSize: const Size(48, 48), shape: border)),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: border,
        iconColor: c.onSurfaceVariant,
        textColor: c.onSurface,
        selectedColor: c.onPrimaryContainer,
        selectedTileColor: c.primaryContainer,
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodySmall,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: c.brightness == Brightness.dark
            ? c.surfaceContainerLow
            : c.surfaceContainer,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(controlRadius),
            borderSide: BorderSide(color: c.outlineVariant)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(controlRadius),
            borderSide: BorderSide(color: c.outlineVariant)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(controlRadius),
            borderSide: BorderSide(color: c.primary, width: 2)),
        hintStyle: text.bodyMedium?.copyWith(color: c.onSurfaceVariant),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: c.surfaceContainer,
        selectedColor: c.primaryContainer,
        side: BorderSide(color: c.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: text.labelMedium?.copyWith(color: c.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      dividerTheme:
          DividerThemeData(color: c.outlineVariant, thickness: 1, space: 24),
      dialogTheme: DialogThemeData(
        backgroundColor: darkOverlaySurface(c),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyLarge,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: eink ? BorderSide(color: c.outline) : BorderSide.none),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: darkOverlaySurface(c),
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: darkOverlaySurface(c),
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: darkOverlaySurface(c),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
            side: BorderSide(color: c.outlineVariant)),
        textStyle: text.bodyMedium,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
            color: c.inverseSurface, borderRadius: BorderRadius.circular(8)),
        textStyle: text.bodySmall?.copyWith(color: c.onInverseSurface),
      ),
    );
  }
}
