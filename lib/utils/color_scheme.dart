import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:anx_reader/theme/app_theme.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:anx_reader/utils/app_motion.dart';

ThemeData colorSchema(
  Prefs prefsNotifier,
  BuildContext context,
  Brightness brightness,
) {
  if (prefsNotifier.eInkMode) brightness = Brightness.light;
  final isEinkMode = prefsNotifier.eInkMode;
  final disableMotion = prefsNotifier.eInkMotionDisabled ||
      MediaQuery.disableAnimationsOf(context);
  final colorScheme = AppTheme.scheme(
    seed: prefsNotifier.themeColor,
    brightness: brightness,
    trueBlack: prefsNotifier.trueDarkMode,
    eink: isEinkMode,
  );
  final gropedBackgroundColor = colorScheme.surface;

  ThemeData themeData = isEinkMode
      ? FlexThemeData.light(
          useMaterial3: true,
          swapLegacyOnMaterial3: true,
          colorScheme: colorScheme)
      : switch (brightness) {
          Brightness.light => FlexThemeData.light(
              useMaterial3: true,
              swapLegacyOnMaterial3: true,
              colorScheme: colorScheme,
            ),
          Brightness.dark => FlexThemeData.dark(
              useMaterial3: true,
              swapLegacyOnMaterial3: true,
              darkIsTrueBlack: prefsNotifier.trueDarkMode,
              colorScheme: colorScheme,
            )
        };

  return AppTheme.apply(themeData, eink: isEinkMode)
      .copyWith(
          pageTransitionsTheme: disableMotion
              ? PageTransitionsTheme(builders: {
                  for (final platform in TargetPlatform.values)
                    platform: const NoMotionPageTransitionsBuilder(),
                })
              : themeData.pageTransitionsTheme,
          splashFactory:
              disableMotion ? NoSplash.splashFactory : themeData.splashFactory,
          highlightColor:
              disableMotion ? Colors.transparent : themeData.highlightColor,
          hoverColor: disableMotion ? Colors.transparent : themeData.hoverColor,
          expansionTileTheme: themeData.expansionTileTheme
              .copyWith(expansionAnimationStyle: AppMotion.style),
          // Flutter still requires this deprecated opt-in for the 2024 shapes.
          // ignore: deprecated_member_use
          sliderTheme: const SliderThemeData(year2023: false),
          progressIndicatorTheme:
              // ignore: deprecated_member_use
              const ProgressIndicatorThemeData(year2023: false),
          scaffoldBackgroundColor: gropedBackgroundColor,
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isEinkMode
                    ? const BorderSide(color: Colors.black)
                    : BorderSide.none),
            backgroundColor:
                isEinkMode ? Colors.white : colorScheme.surfaceContainer,
            contentTextStyle: themeData.textTheme.bodyMedium
                ?.copyWith(color: colorScheme.onSurface),
            actionTextColor: colorScheme.primary,
            closeIconColor: colorScheme.onSurface,
            insetPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          ),
          drawerTheme: DrawerThemeData()
              .copyWith(backgroundColor: gropedBackgroundColor))
      .useSystemChineseFont(brightness);
}
