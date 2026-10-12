import 'package:flutter/material.dart';

/// Shared visual language: neutral surfaces, precise alignment and clear type.
abstract final class AppTheme {
  static const defaultSeed = Color(0xFF283142);
  static const cardRadius = 12.0;
  static const controlRadius = 10.0;

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
    final defaultPalette = seed.toARGB32() == defaultSeed.toARGB32();
    return ColorScheme.fromSeed(seedColor: seed, brightness: brightness)
        .copyWith(
      primary: defaultPalette
          ? (dark ? const Color(0xFFD9DFEC) : defaultSeed)
          : null,
      onPrimary: defaultPalette
          ? (dark ? const Color(0xFF242C3B) : Colors.white)
          : null,
      primaryContainer: defaultPalette
          ? (dark ? const Color(0xFF303845) : const Color(0xFFE9EDF4))
          : null,
      onPrimaryContainer: defaultPalette
          ? (dark ? const Color(0xFFDFE5F0) : const Color(0xFF283142))
          : null,
      secondary: defaultPalette
          ? (dark ? const Color(0xFFBEC7D5) : const Color(0xFF596579))
          : null,
      secondaryContainer: defaultPalette
          ? (dark ? const Color(0xFF303744) : const Color(0xFFEBEEF3))
          : null,
      onSecondaryContainer: defaultPalette
          ? (dark ? const Color(0xFFE0E5EE) : const Color(0xFF394353))
          : null,
      surface: dark
          ? (trueBlack ? Colors.black : const Color(0xFF111318))
          : const Color(0xFFF7F8FA),
      onSurface: dark ? const Color(0xFFE9ECF2) : const Color(0xFF1C2028),
      onSurfaceVariant:
          dark ? const Color(0xFFB5BDCA) : const Color(0xFF5E6878),
      surfaceContainerLowest:
          dark ? const Color(0xFF0B0D12) : const Color(0xFFFFFFFF),
      surfaceContainerLow:
          dark ? const Color(0xFF171A21) : const Color(0xFFF0F2F6),
      surfaceContainer:
          dark ? const Color(0xFF1D2129) : const Color(0xFFFFFFFF),
      surfaceContainerHigh:
          dark ? const Color(0xFF272C35) : const Color(0xFFEBEEF3),
      surfaceContainerHighest:
          dark ? const Color(0xFF323844) : const Color(0xFFE1E5EC),
      outline: dark ? const Color(0xFF8993A4) : const Color(0xFF7D8797),
      outlineVariant: dark ? const Color(0xFF363D49) : const Color(0xFFDDE2EA),
    );
  }

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
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
            side: BorderSide(color: c.outlineVariant)),
      ),
      filledButtonTheme: FilledButtonThemeData(style: button),
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
        fillColor: c.surfaceContainer,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: text.labelMedium?.copyWith(color: c.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      dividerTheme:
          DividerThemeData(color: c.outlineVariant, thickness: 1, space: 24),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyLarge,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: eink ? BorderSide(color: c.outline) : BorderSide.none),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: c.surfaceContainer,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surfaceContainer,
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
