import 'package:flutter/material.dart';

/// Brand palette for "La Tercia · Chicxulub Puerto".
///
/// These are the fixed brand neutrals (creams, browns, borders, semantic
/// colors) that define the identity regardless of the customizable
/// primary/secondary accent colors chosen in Settings.
class LaTerciaColors {
  LaTerciaColors._();

  // Core brand
  static const burntOrange = Color(0xFFC1560F); // primary accent
  static const gold = Color(0xFFF1AA3F); // secondary accent (active nav)
  static const goldDark = Color(0xFFE0912A);
  static const darkBrown = Color(0xFF1B120B); // top bar / KDS-ish dark
  static const cocoa = Color(0xFF4A3C28); // strong text
  static const tan = Color(0xFF8A6F3F); // muted text
  static const tanLight = Color(0xFFA1906F); // subtle text

  // Surfaces
  static const appBg = Color(0xFFECE3D4); // general app background (beige)
  static const cream = Color(0xFFFBF6EC); // panels
  static const creamAlt = Color(0xFFFFFDF8); // cards
  static const surfaceVariant = Color(0xFFF6ECD8); // table headers, tints
  static const surfaceSoft = Color(0xFFFBEACB);

  // Borders
  static const border = Color(0xFFE6DAC4);
  static const borderStrong = Color(0xFFE3D6BF);

  // Semantic
  static const success = Color(0xFF3F9D54);
  static const successLight = Color(0xFF4FAE63);
  static const successBg = Color(0xFFE2F0DA);
  static const danger = Color(0xFFE31919);

  // Order types
  static const mesa = Color(0xFFE0912A); // dine-in
  static const llevar = Color(0xFF5F89A6); // takeaway (cool blue)
  static const delivery = Color(0xFF8A5CC0); // delivery (purple)
  static const deliveryBg = Color(0xFFECE6F6);

  // Category accents
  static const catCaliente = Color(0xFFE0912A);
  static const catFria = Color(0xFF5F89A6);
  static const catPostre = Color(0xFFD06771);
  static const catExtra = Color(0xFF7FA06A);

  // KDS (dark slate/blue theme)
  static const kdsBg = Color(0xFF0F1521);
  static const kdsPanel = Color(0xFF151D2B);
  static const kdsCard = Color(0xFF18202E);
  static const kdsBorder = Color(0xFF232F42);
  static const kdsMuted = Color(0xFF5F7288);
  static const kdsText = Color(0xFFDDE6F2);
  static const kdsNoteBg = Color(0xFF2A2413);
  static const kdsNoteText = Color(0xFFE9C46A);

  // KDS timer states
  static const timerOk = Color(0xFF5FCE76);
  static const timerWarn = Color(0xFFF1AA3F);
  static const timerLate = Color(0xFFFF5B5B);
}

const _serif = 'DM Serif Display';
const _sans = 'Poppins';

Color _hex(String hex) => Color(int.parse(hex.replaceFirst('#', '0xFF')));

/// Tema claro del POS / Admin. [primaryHex]/[secondaryHex] vienen de Settings
/// (colores de acento personalizables); los neutros de marca son constantes.
ThemeData buildTheme(String primaryHex, String secondaryHex) {
  final primary = _hex(primaryHex);
  final secondary = _hex(secondaryHex);

  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    primary: primary,
    secondary: secondary,
    brightness: Brightness.light,
  ).copyWith(
    surface: LaTerciaColors.appBg,
    onSurface: LaTerciaColors.darkBrown,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: LaTerciaColors.creamAlt,
    surfaceContainer: LaTerciaColors.cream,
    surfaceContainerHigh: LaTerciaColors.surfaceVariant,
    outlineVariant: LaTerciaColors.border,
    error: LaTerciaColors.danger,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: LaTerciaColors.appBg,
    fontFamily: _sans,
  );

  return base.copyWith(
    textTheme: _textTheme(base.textTheme),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: LaTerciaColors.border),
      ),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: LaTerciaColors.darkBrown,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: _serif,
        fontSize: 22,
        color: Colors.white,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        textStyle: const TextStyle(
            fontFamily: _sans, fontWeight: FontWeight.w600, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: LaTerciaColors.cocoa,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        side: const BorderSide(color: LaTerciaColors.border),
        textStyle:
            const TextStyle(fontFamily: _sans, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        side: BorderSide(color: primary.withValues(alpha: 0.5)),
        textStyle:
            const TextStyle(fontFamily: _sans, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle:
            const TextStyle(fontFamily: _sans, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: primary,
      side: const BorderSide(color: LaTerciaColors.border),
      // labelStyle must set an explicit color: Material3's ChoiceChip/
      // FilterChip render with invisible (transparent-resolving) text
      // otherwise, since neither state has a theme-derived fallback here.
      labelStyle: const TextStyle(
        fontFamily: _sans,
        fontWeight: FontWeight.w500,
        fontSize: 13,
        color: LaTerciaColors.cocoa,
      ),
      secondaryLabelStyle:
          const TextStyle(fontFamily: _sans, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LaTerciaColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LaTerciaColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 1.6),
      ),
      hintStyle: const TextStyle(color: LaTerciaColors.tanLight),
      labelStyle: const TextStyle(color: LaTerciaColors.tan),
    ),
    dividerTheme: const DividerThemeData(
      color: LaTerciaColors.border,
      thickness: 1,
      space: 1,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: LaTerciaColors.creamAlt,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: const TextStyle(
        fontFamily: _serif,
        fontSize: 24,
        color: LaTerciaColors.darkBrown,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

/// Tema oscuro de la Cocina (KDS), siempre azul pizarra, independiente de
/// Settings.
ThemeData buildKdsTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: LaTerciaColors.kdsBg,
    fontFamily: _sans,
    colorScheme: const ColorScheme.dark(
      primary: LaTerciaColors.gold,
      secondary: LaTerciaColors.burntOrange,
      surface: LaTerciaColors.kdsPanel,
      onSurface: LaTerciaColors.kdsText,
      error: LaTerciaColors.timerLate,
    ),
  );

  return base.copyWith(
    textTheme: _textTheme(base.textTheme, onDark: true),
    cardTheme: CardThemeData(
      color: LaTerciaColors.kdsCard,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

TextTheme _textTheme(TextTheme base, {bool onDark = false}) {
  final display = onDark ? Colors.white : LaTerciaColors.darkBrown;
  final body = onDark ? LaTerciaColors.kdsText : LaTerciaColors.cocoa;
  return base.copyWith(
    displayLarge:
        base.displayLarge?.copyWith(fontFamily: _serif, color: display),
    displayMedium:
        base.displayMedium?.copyWith(fontFamily: _serif, color: display),
    displaySmall:
        base.displaySmall?.copyWith(fontFamily: _serif, color: display),
    headlineLarge:
        base.headlineLarge?.copyWith(fontFamily: _serif, color: display),
    headlineMedium:
        base.headlineMedium?.copyWith(fontFamily: _serif, color: display),
    headlineSmall:
        base.headlineSmall?.copyWith(fontFamily: _serif, color: display),
    titleLarge: base.titleLarge?.copyWith(fontFamily: _serif, color: display),
    titleMedium: base.titleMedium
        ?.copyWith(fontFamily: _sans, fontWeight: FontWeight.w600, color: body),
    titleSmall: base.titleSmall
        ?.copyWith(fontFamily: _sans, fontWeight: FontWeight.w600, color: body),
    bodyLarge: base.bodyLarge?.copyWith(fontFamily: _sans, color: body),
    bodyMedium: base.bodyMedium?.copyWith(fontFamily: _sans, color: body),
    bodySmall: base.bodySmall?.copyWith(fontFamily: _sans, color: body),
    labelLarge: base.labelLarge
        ?.copyWith(fontFamily: _sans, fontWeight: FontWeight.w600, color: body),
    labelMedium: base.labelMedium?.copyWith(fontFamily: _sans, color: body),
    labelSmall: base.labelSmall?.copyWith(fontFamily: _sans, color: body),
  );
}
