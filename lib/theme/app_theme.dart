import 'package:flutter/material.dart';

/// Palette « Fonte & disques », thème sombre.
///
/// Le fond rappelle la fonte des barres et des haltères, le texte la craie,
/// et les accents reprennent le code couleur officiel des disques de
/// compétition (rouge 25 kg, bleu 20 kg, jaune 15 kg, vert 10 kg, blanc 5 kg),
/// éclaircis pour rester lisibles sur fond sombre.
/// Chaque accent a un rôle unique dans l'interface :
/// - bleu : actions principales ;
/// - rouge : records personnels ;
/// - jaune : objectif hebdomadaire (flammes) et temps de repos ;
/// - vert : séries validées, progression.
class AppColors {
  AppColors._();

  // Fonds et surfaces, du plus profond au plus en relief
  static const Color background = Color(0xFF101215);
  static const Color surface = Color(0xFF181B1F);
  static const Color surfaceRaised = Color(0xFF22262B);
  static const Color line = Color(0xFF2B3036);

  // Textes
  static const Color text = Color(0xFFF1F1EC);
  static const Color textSoft = Color(0xFFA0A6AD);
  static const Color textFaint = Color(0xFF6B7178);

  /// Fond des éléments sélectionnés (puces, segments) : couleur craie,
  /// avec [onInverse] pour le texte posé dessus.
  static const Color inverse = text;
  static const Color onInverse = background;

  // Couleurs des disques
  static const Color plateRed = Color(0xFFFF4D3D);
  static const Color plateBlue = Color(0xFF3D6BFF);
  static const Color plateYellow = Color(0xFFFFC233);
  static const Color plateGreen = Color(0xFF2FBF71);
  static const Color plateGrey = Color(0xFF8A9099);
  static const Color plateWhite = Color(0xFFF1F1EC);

  // Rôles
  static const Color primary = plateBlue;
  static const Color record = plateRed;
  static const Color flame = plateYellow;
  static const Color rest = plateYellow;
  static const Color success = plateGreen;
  static const Color error = Color(0xFFFF5449);

  /// Couleurs proposées pour identifier une séance.
  static const List<Color> sessionColors = [
    plateRed,
    plateBlue,
    plateYellow,
    plateGreen,
    plateGrey,
    plateWhite,
  ];

  /// Couleur d'une séance à partir de l'index enregistré.
  ///
  /// Les anciens index (palette de 8 couleurs) restent valides grâce au modulo.
  static Color sessionColor(String? storedIndex) {
    final index = int.tryParse(storedIndex ?? '') ?? 0;
    return sessionColors[index.abs() % sessionColors.length];
  }

  /// Couleur lisible pour un texte ou une icône posé sur [background].
  static Color onColor(Color background) {
    return background.computeLuminance() > 0.45 ? AppColors.background : Colors.white;
  }
}

/// Espacements, sur une grille de 4 points.
class AppSpace {
  AppSpace._();

  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Marge horizontale des écrans.
  static const double page = 20;
}

/// Rayons d'arrondi, du plus discret au plus marqué.
class AppRadius {
  AppRadius._();

  static const double s = 10;
  static const double m = 14;
  static const double l = 20;
}

/// Styles de texte.
///
/// Barlow pour le texte courant ; Barlow Condensed très grasse pour les
/// chiffres et les titres, à la manière des marquages sur les disques.
/// Les chiffres utilisent des chasses fixes pour ne pas « sauter » quand
/// une valeur change (chrono, compteurs).
class AppText {
  AppText._();

  static const String _sans = 'Barlow';
  static const String _condensed = 'BarlowCondensed';
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// Très grands chiffres : compte à rebours, records.
  static const TextStyle figureXL = TextStyle(
    fontFamily: _condensed,
    fontWeight: FontWeight.w800,
    fontSize: 64,
    height: 1.0,
    letterSpacing: -1,
    color: AppColors.text,
    fontFeatures: _tabular,
  );

  /// Grands chiffres : statistiques mises en avant.
  static const TextStyle figureL = TextStyle(
    fontFamily: _condensed,
    fontWeight: FontWeight.w800,
    fontSize: 36,
    height: 1.0,
    letterSpacing: -0.5,
    color: AppColors.text,
    fontFeatures: _tabular,
  );

  /// Chiffres moyens : séries, chrono, valeurs de liste.
  static const TextStyle figureM = TextStyle(
    fontFamily: _condensed,
    fontWeight: FontWeight.w700,
    fontSize: 22,
    height: 1.1,
    color: AppColors.text,
    fontFeatures: _tabular,
  );

  /// Titre d'écran.
  static const TextStyle display = TextStyle(
    fontFamily: _condensed,
    fontWeight: FontWeight.w800,
    fontSize: 34,
    height: 1.05,
    letterSpacing: -0.3,
    color: AppColors.text,
  );

  /// Titre de bloc ou de carte importante.
  static const TextStyle title = TextStyle(
    fontFamily: _sans,
    fontWeight: FontWeight.w700,
    fontSize: 20,
    height: 1.2,
    color: AppColors.text,
  );

  /// Intitulé de section ou d'élément de liste.
  static const TextStyle heading = TextStyle(
    fontFamily: _sans,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 1.25,
    color: AppColors.text,
  );

  /// Texte courant.
  static const TextStyle body = TextStyle(
    fontFamily: _sans,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 1.4,
    color: AppColors.text,
  );

  /// Libellé secondaire (sous-titres, métadonnées).
  static const TextStyle label = TextStyle(
    fontFamily: _sans,
    fontWeight: FontWeight.w500,
    fontSize: 13,
    height: 1.3,
    color: AppColors.textSoft,
  );

  /// Petit texte d'appoint (unités, dates).
  static const TextStyle caption = TextStyle(
    fontFamily: _sans,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 1.3,
    color: AppColors.textFaint,
  );
}

/// Thème Material de l'application.
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m));
    const buttonText = TextStyle(fontFamily: 'Barlow', fontWeight: FontWeight.w600, fontSize: 16);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Barlow',
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.text,
        onSecondary: AppColors.background,
        error: AppColors.error,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.text,
        onSurfaceVariant: AppColors.textSoft,
        outline: AppColors.line,
        outlineVariant: AppColors.line,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.title,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.surfaceRaised,
          disabledForegroundColor: AppColors.textFaint,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 48),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.line, width: 1.5),
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: buttonText,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.text),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.l, vertical: AppSpace.l),
        hintStyle: AppText.body.copyWith(color: AppColors.textFaint),
        labelStyle: AppText.body.copyWith(color: AppColors.textSoft),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionHandleColor: AppColors.primary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.surfaceRaised,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppText.caption.copyWith(
            color: selected ? AppColors.text : AppColors.textFaint,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? AppColors.text : AppColors.textFaint,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.inverse,
        contentTextStyle: AppText.body.copyWith(color: AppColors.onInverse),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.m)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.l)),
        titleTextStyle: AppText.title,
        contentTextStyle: AppText.body.copyWith(color: AppColors.textSoft),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.line,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSoft,
        textColor: AppColors.text,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : null,
        ),
        side: const BorderSide(color: AppColors.textFaint, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.inverse,
          borderRadius: BorderRadius.circular(AppRadius.s),
        ),
        textStyle: AppText.caption.copyWith(color: AppColors.onInverse),
      ),
    );
  }
}
