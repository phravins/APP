import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF6C63FF),
      secondary = Color(0xFF40C4FF),
      success = Color(0xFF22C55E),
      warning = Color(0xFFF59E0B),
      danger = Color(0xFFEF4444);
}

/// Shared size tokens so icons, corners and touch targets stay consistent.
abstract final class AppSizes {
  static const iconXs = 16.0, iconSm = 18.0, iconMd = 20.0, iconLg = 24.0;
  static const radiusSm = 8.0, radiusMd = 12.0, radiusLg = 14.0;
  static const radiusXl = 20.0;

  /// Width at which the bottom bar gives way to a navigation rail. Phones
  /// (shortest side under this) keep the bottom bar even in landscape.
  static const railBreakpoint = 600.0;

  /// Width at which the rail shows labels beside the icons.
  static const extendedRailBreakpoint = 1200.0;
}

/// Square-ish 44px icon buttons used beside headings and search fields.
abstract final class AppIconButtonStyles {
  static ButtonStyle filled() => IconButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    minimumSize: const Size(44, 44),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
    ),
  );
  static ButtonStyle outlined(ColorScheme scheme) => IconButton.styleFrom(
    minimumSize: const Size(44, 44),
    backgroundColor: scheme.surfaceContainerLowest,
    foregroundColor: scheme.onSurface,
    side: BorderSide(color: scheme.outlineVariant),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
    ),
  );
}

/// Calm, flat, warm-neutral surfaces with a single accent colour.
abstract final class AppTheme {
  static const serif = 'NotoSerif';

  static ThemeData theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
        ).copyWith(
          primary: dark ? const Color(0xFFA9A3FF) : const Color(0xFF5C52DE),
          // Page background.
          surface: dark ? const Color(0xFF1C1B1A) : const Color(0xFFFAF9F5),
          // Cards, inputs, sheets.
          surfaceContainerLowest: dark
              ? const Color(0xFF262624)
              : const Color(0xFFFFFFFF),
          surfaceContainerLow: dark
              ? const Color(0xFF2A2927)
              : const Color(0xFFF5F4EE),
          surfaceContainer: dark
              ? const Color(0xFF302F2C)
              : const Color(0xFFF0EEE6),
          surfaceContainerHigh: dark
              ? const Color(0xFF363532)
              : const Color(0xFFEAE8DF),
          surfaceContainerHighest: dark
              ? const Color(0xFF3D3C38)
              : const Color(0xFFE3E1D7),
          onSurface: dark ? const Color(0xFFF5F4EE) : const Color(0xFF1F1E1D),
          onSurfaceVariant: dark
              ? const Color(0xFFA6A49B)
              : const Color(0xFF6B6963),
          outline: dark ? const Color(0xFF5A5852) : const Color(0xFFB9B6AB),
          // Hairline borders and dividers.
          outlineVariant: dark
              ? const Color(0xFF353431)
              : const Color(0xFFE6E3D9),
        );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
    TextStyle? serifStyle(TextStyle? style, double size) => style?.copyWith(
      fontFamily: serif,
      fontSize: size,
      fontWeight: FontWeight.w500,
      letterSpacing: -.4,
      height: 1.2,
      color: scheme.onSurface,
    );
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: color, width: width),
        );
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineLarge: serifStyle(base.textTheme.headlineLarge, 25),
        headlineMedium: serifStyle(base.textTheme.headlineMedium, 22),
        headlineSmall: serifStyle(base.textTheme.headlineSmall, 20),
        titleLarge: serifStyle(base.textTheme.titleLarge, 18),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -.1,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.45),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      iconTheme: IconThemeData(
        size: AppSizes.iconLg,
        color: scheme.onSurfaceVariant,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        isDense: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: border(scheme.outlineVariant),
        enabledBorder: border(scheme.outlineVariant),
        focusedBorder: border(scheme.primary, 1.5),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: dark ? const Color(0xFF1C1B1A) : Colors.white,
          minimumSize: const Size(44, 46),
          iconSize: AppSizes.iconMd,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 46),
          backgroundColor: scheme.surfaceContainerLowest,
          foregroundColor: scheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          side: BorderSide(color: scheme.outlineVariant),
          iconSize: AppSizes.iconMd,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          iconSize: AppSizes.iconLg,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        minLeadingWidth: 24,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: scheme.surfaceContainerHigh,
        indicatorShape: const StadiumBorder(),
        selectedIconTheme: IconThemeData(
          color: scheme.onSurface,
          size: AppSizes.iconLg,
        ),
        unselectedIconTheme: IconThemeData(
          color: scheme.onSurfaceVariant,
          size: AppSizes.iconLg,
        ),
        selectedLabelTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: scheme.onSurfaceVariant,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          color: scheme.onInverseSurface,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -.2,
          color: scheme.onSurface,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: scheme.surfaceContainerLowest,
        selectedColor: scheme.onSurface,
        secondarySelectedColor: scheme.onSurface,
        checkmarkColor: scheme.surface,
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? scheme.surface
                : scheme.onSurface,
          ),
        ),
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStatePropertyAll(scheme.outlineVariant),
      ),
    );
  }
}
