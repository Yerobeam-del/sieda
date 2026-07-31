import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand Colors ──────────────────────────────────────────
  static const Color _seed = Color(0xFF0D9488);

  // Light mode semantic colors
  static const Color primary = Color(0xFF0D9488);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color surface = Color(0xFFF0FDF4);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Dark mode: gunakan skema standar Material 3 (ColorScheme.fromSeed).
  // Tidak ada konstanta dark custom — semua warna diambil dari colorScheme
  // saat runtime agar serasi dengan komponen standar Android (navbar, dll).

  // Gender colors (same in both modes)
  static const Color male = Color(0xFF3B82F6);
  static const Color female = Color(0xFFEC4899);

  // ── Typography helpers ────────────────────────────────────

  /// Build the full text theme with the given primary text color.
  static TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor, Color hintColor) {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.sora(
        fontSize: 32, fontWeight: FontWeight.w700, color: primaryColor, letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.sora(
        fontSize: 26, fontWeight: FontWeight.w700, color: primaryColor, letterSpacing: -0.25,
      ),
      displaySmall: GoogleFonts.sora(
        fontSize: 22, fontWeight: FontWeight.w600, color: primaryColor,
      ),
      headlineLarge: GoogleFonts.sora(
        fontSize: 20, fontWeight: FontWeight.w600, color: primaryColor,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w600, color: primaryColor,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w600, color: primaryColor,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w600, color: primaryColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w500, color: primaryColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w500, color: secondaryColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w400, color: primaryColor, height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400, color: secondaryColor, height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400, color: hintColor, height: 1.4,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w500, color: secondaryColor, letterSpacing: 0.25,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w500, color: hintColor, letterSpacing: 0.15,
      ),
    );
  }

  // ── Light Theme ───────────────────────────────────────────
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
      surface: Colors.white,
      error: error,
    );

    final textTheme = _buildTextTheme(textPrimary, textSecondary, textHint);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: _lightAppBarTheme(textTheme),
      cardTheme: _lightCardTheme(colorScheme),
      inputDecorationTheme: _lightInputTheme(colorScheme),
      elevatedButtonTheme: _buttonTheme(colorScheme),
      textButtonTheme: _textButtonTheme(colorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(colorScheme),
      filledButtonTheme: _filledButtonTheme(colorScheme),
      navigationBarTheme: _lightNavBar(colorScheme),
      navigationRailTheme: _navRail(colorScheme),
      segmentedButtonTheme: _segmentedButtonTheme(),
      bottomSheetTheme: _lightBottomSheet(),
      dialogTheme: _lightDialog(),
      snackBarTheme: _snackBarTheme(),
      chipTheme: _chipTheme(colorScheme),
      checkboxTheme: _lightCheckbox(colorScheme),
      switchTheme: _lightSwitch(colorScheme),
      dividerTheme: _lightDivider(),
      listTileTheme: _listTile(),
      tabBarTheme: _tabBar(colorScheme),
      dropdownMenuTheme: _dropDown(colorScheme),
      menuButtonTheme: _menuButton(),
      progressIndicatorTheme: _progress(colorScheme),
      popupMenuTheme: _popupMenu(),
      tooltipTheme: _tooltip(),
      badgeTheme: _badge(),
      scrollbarTheme: _scrollbar(),
      pageTransitionsTheme: _pageTransitions(),
    );
  }

  // ── Dark Theme ────────────────────────────────────────────
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
      error: error,
    );

    final textTheme = _buildTextTheme(
        colorScheme.onSurface, colorScheme.onSurfaceVariant, colorScheme.outline);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: _darkAppBarTheme(colorScheme, textTheme),
      cardTheme: _darkCardTheme(colorScheme),
      inputDecorationTheme: _darkInputTheme(colorScheme),
      elevatedButtonTheme: _buttonTheme(colorScheme),
      textButtonTheme: _textButtonTheme(colorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(colorScheme),
      filledButtonTheme: _filledButtonTheme(colorScheme),
      navigationBarTheme: _darkNavBar(colorScheme),
      navigationRailTheme: _navRail(colorScheme),
      segmentedButtonTheme: _segmentedButtonTheme(),
      bottomSheetTheme: _darkBottomSheet(colorScheme),
      dialogTheme: _darkDialog(colorScheme),
      snackBarTheme: _snackBarTheme(),
      chipTheme: _chipTheme(colorScheme),
      checkboxTheme: _darkCheckbox(colorScheme),
      switchTheme: _darkSwitch(colorScheme),
      dividerTheme: _darkDivider(colorScheme),
      listTileTheme: _listTile(),
      tabBarTheme: _tabBar(colorScheme),
      dropdownMenuTheme: _darkDropDown(colorScheme),
      menuButtonTheme: _menuButton(),
      progressIndicatorTheme: _progress(colorScheme),
      popupMenuTheme: _darkPopupMenu(colorScheme),
      tooltipTheme: _tooltip(),
      badgeTheme: _badge(),
      scrollbarTheme: _darkScrollbar(colorScheme),
      pageTransitionsTheme: _pageTransitions(),
    );
  }

  // ── Shared component themes ───────────────────────────────

  static ElevatedButtonThemeData _buttonTheme(ColorScheme cs) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: cs.primary.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.25),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return Colors.white.withValues(alpha: 0.15);
            if (states.contains(WidgetState.hovered)) return Colors.white.withValues(alpha: 0.08);
            return null;
          }),
        ),
      );

  static TextButtonThemeData _textButtonTheme(ColorScheme cs) =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme(ColorScheme cs) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      );

  static FilledButtonThemeData _filledButtonTheme(ColorScheme cs) =>
      FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primaryContainer,
          foregroundColor: cs.onPrimaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      );

  static NavigationRailThemeData _navRail(ColorScheme cs) =>
      NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: cs.primaryContainer,
      );

  static SegmentedButtonThemeData _segmentedButtonTheme() =>
      SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  static ChipThemeData _chipTheme(ColorScheme cs) =>
      ChipThemeData(
        backgroundColor: cs.primaryContainer,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onPrimaryContainer),
        secondaryLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onPrimaryContainer),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      );

  static ListTileThemeData _listTile() =>
      ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  static TabBarThemeData _tabBar(ColorScheme cs) =>
      TabBarThemeData(
        labelColor: cs.primary,
        unselectedLabelColor: textHint,
        indicatorColor: cs.primary,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400),
      );

  static SnackBarThemeData _snackBarTheme() =>
      SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
      );

  static MenuButtonThemeData _menuButton() =>
      MenuButtonThemeData(
        style: MenuItemButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

  static ProgressIndicatorThemeData _progress(ColorScheme cs) =>
      ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.primaryContainer,
        circularTrackColor: cs.primaryContainer,
      );

  static TooltipThemeData _tooltip() =>
      TooltipThemeData(
        textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      );

  static BadgeThemeData _badge() =>
      const BadgeThemeData(
        backgroundColor: error,
        textColor: Colors.white,
        textStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      );

  static PageTransitionsTheme _pageTransitions() =>
      PageTransitionsTheme(
        builders: {
          TargetPlatform.android: const ZoomPageTransitionsBuilder(allowEnterRouteSnapshotting: false),
          TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
        },
      );

  // ── Light-specific component themes ───────────────────────

  static AppBarTheme _lightAppBarTheme(TextTheme tt) =>
      AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleSpacing: 16,
        titleTextStyle: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        shape: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      );

  static CardThemeData _lightCardTheme(ColorScheme cs) =>
      CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border.withValues(alpha: 0.5), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      );

  static InputDecorationTheme _lightInputTheme(ColorScheme cs) =>
      InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border.withValues(alpha: 0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border.withValues(alpha: 0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: textSecondary),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: textHint),
        prefixIconColor: textHint,
        floatingLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary),
      );

  static NavigationBarThemeData _lightNavBar(ColorScheme cs) =>
      NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: cs.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        height: 68,
      );

  static BottomSheetThemeData _lightBottomSheet() =>
      const BottomSheetThemeData(
        backgroundColor: Colors.white,
        elevation: 2,
        modalElevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      );

  static DialogThemeData _lightDialog() =>
      DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      );

  static CheckboxThemeData _lightCheckbox(ColorScheme cs) =>
      CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: border),
      );

  static SwitchThemeData _lightSwitch(ColorScheme cs) =>
      SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primary;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primary.withValues(alpha: 0.4);
          return border;
        }),
      );

  static DividerThemeData _lightDivider() =>
      DividerThemeData(color: border.withValues(alpha: 0.6), thickness: 1, space: 1);

  static PopupMenuThemeData _popupMenu() =>
      PopupMenuThemeData(
        color: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );

  static ScrollbarThemeData _scrollbar() =>
      ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(border),
        radius: const Radius.circular(8),
        thickness: WidgetStateProperty.all(4),
      );

  // ── Dark-specific component themes ────────────────────────

  static AppBarTheme _darkAppBarTheme(ColorScheme cs, TextTheme tt) =>
      AppBarTheme(
        backgroundColor: cs.surfaceContainerLow,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleSpacing: 16,
        titleTextStyle: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface),
        shape: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6), width: 1)),
      );

  static CardThemeData _darkCardTheme(ColorScheme cs) =>
      CardThemeData(
        color: cs.surfaceContainerLow,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cs.outlineVariant, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      );

  static InputDecorationTheme _darkInputTheme(ColorScheme cs) =>
      InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: cs.onSurfaceVariant),
        prefixIconColor: cs.onSurfaceVariant,
        floatingLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary),
      );

  static NavigationBarThemeData _darkNavBar(ColorScheme cs) =>
      NavigationBarThemeData(
        backgroundColor: cs.surfaceContainer,
        // Indikator dibuat transparan agar navbar seragam — status terpilih
        // tetap terlihat dari warna ikon & label yang berbeda.
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        height: 68,
      );

  static BottomSheetThemeData _darkBottomSheet(ColorScheme cs) =>
      BottomSheetThemeData(
        backgroundColor: cs.surfaceContainerLow,
        elevation: 2,
        modalElevation: 2,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      );

  static DialogThemeData _darkDialog(ColorScheme cs) =>
      DialogThemeData(
        backgroundColor: cs.surfaceContainerHigh,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      );

  static CheckboxThemeData _darkCheckbox(ColorScheme cs) =>
      CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: cs.outlineVariant),
      );

  static SwitchThemeData _darkSwitch(ColorScheme cs) =>
      SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primary;
          return cs.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primary.withValues(alpha: 0.4);
          return cs.outlineVariant;
        }),
      );

  static DividerThemeData _darkDivider(ColorScheme cs) =>
      DividerThemeData(color: cs.outlineVariant, thickness: 1, space: 1);

  static PopupMenuThemeData _darkPopupMenu(ColorScheme cs) =>
      PopupMenuThemeData(
        color: cs.surfaceContainer,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );

  static ScrollbarThemeData _darkScrollbar(ColorScheme cs) =>
      ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(cs.outlineVariant),
        radius: const Radius.circular(8),
        thickness: WidgetStateProperty.all(4),
      );

  // ── Theme-mode-aware Dropdown ──
  static DropdownMenuThemeData _dropDown(ColorScheme cs) =>
      DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: border.withValues(alpha: 0.6)),
          ),
        ),
      );

  static DropdownMenuThemeData _darkDropDown(ColorScheme cs) =>
      DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cs.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cs.outlineVariant),
          ),
        ),
      );

  // ── Convenience shortcuts ──────────────────────────────────
  // NOTE: These use light-mode colors by default.
  // For dark-mode-aware widgets, prefer Theme.of(context).colorScheme or M3 Card widget.

  // ── Theme-mode-aware helpers ───────────────────────────────
  // Use these in widgets so the same code renders correctly in
  // both light and dark mode.

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color textPrimaryOf(BuildContext context) =>
      isDark(context) ? Theme.of(context).colorScheme.onSurface : textPrimary;

  static Color textSecondaryOf(BuildContext context) =>
      isDark(context) ? Theme.of(context).colorScheme.onSurfaceVariant : textSecondary;

  static Color textHintOf(BuildContext context) =>
      isDark(context) ? Theme.of(context).colorScheme.outline : textHint;

  static Color borderOf(BuildContext context) =>
      isDark(context) ? Theme.of(context).colorScheme.outlineVariant : border;

  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? Theme.of(context).colorScheme.surface : surface;

  static BoxDecoration cardDecorationOf(BuildContext context) {
    if (!isDark(context)) return cardDecoration;
    final cs = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
    );
  }

  static BoxDecoration gradientHeaderOf(BuildContext context) => isDark(context)
      ? const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF115E59), Color(0xFF0F766E), Color(0xFF0D9488)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
        )
      : gradientHeader;

  static double get cardRadius => 20;

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: border.withValues(alpha: 0.5)),
      );

  static BoxDecoration get gradientHeader => BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryDark, primary, primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
      );

}
