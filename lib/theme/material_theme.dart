import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Configuration du thème Material Design dark pour l'application Jellyfin
class JellyfishMaterialTheme {
  JellyfishMaterialTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Schéma de couleurs personnalisé
      colorScheme: const ColorScheme.dark(
        primary: AppColors.jellyfinPurple,
        onPrimary: AppColors.text6,
        secondary: AppColors.jellyfinBlue,
        onSecondary: AppColors.text6,
        surface: AppColors.background2,
        onSurface: AppColors.text4,
        // background: AppColors.background1, // Deprecated
        // onBackground: AppColors.text4, // Deprecated
        error: AppColors.error,
        onError: AppColors.text6,
        outline: AppColors.text1,
        outlineVariant: AppColors.surface1,
        // surfaceVariant: AppColors.surface1, // Deprecated
        onSurfaceVariant: AppColors.text3,
        inverseSurface: AppColors.text6,
        onInverseSurface: AppColors.background1,
        inversePrimary: AppColors.jellyfinPurple,
        shadow: Colors.black54,
        scrim: Colors.black87,
        surfaceTint: AppColors.jellyfinPurple,
      ),

      // Configuration de l'AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background2,
        foregroundColor: AppColors.text6,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: AppColors.jellyfinPurple,
        titleTextStyle: TextStyle(
          color: AppColors.text6,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Configuration des cartes
      cardTheme: const CardThemeData(
        color: AppColors.background3,
        surfaceTintColor: AppColors.jellyfinPurple,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // Configuration des boutons élevés
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.jellyfinPurple,
          foregroundColor: AppColors.text6,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Configuration des boutons de texte
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.jellyfinPurple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Configuration des boutons outlined
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.jellyfinPurple,
          side: const BorderSide(color: AppColors.jellyfinPurple),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Configuration des champs de texte
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.text1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.text1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.jellyfinPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.text3),
        hintStyle: const TextStyle(color: AppColors.text2),
      ),

      // Configuration de la navigation bottom
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background2,
        selectedItemColor: AppColors.jellyfinPurple,
        unselectedItemColor: AppColors.text2,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Configuration des icônes
      iconTheme: const IconThemeData(
        color: AppColors.text4,
        size: 24,
      ),

      // Configuration des dividers
      dividerTheme: const DividerThemeData(
        color: AppColors.text1,
        thickness: 1,
        space: 1,
      ),

      // Configuration des listes
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: AppColors.surface1,
        textColor: AppColors.text4,
        iconColor: AppColors.text3,
        selectedColor: AppColors.jellyfinPurple,
      ),

      // Configuration des switches
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.jellyfinPurple;
          }
          return AppColors.text2;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.jellyfinPurple.withValues(alpha: 0.5);
          }
          return AppColors.surface1;
        }),
      ),

      // Configuration des checkboxes
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.jellyfinPurple;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.text6),
        side: const BorderSide(color: AppColors.text2),
      ),

      // Configuration des sliders
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.jellyfinPurple,
        inactiveTrackColor: AppColors.surface1,
        thumbColor: AppColors.jellyfinPurple,
        overlayColor: Color(0x2900A4DC),
        valueIndicatorColor: AppColors.jellyfinPurple,
        valueIndicatorTextStyle: TextStyle(color: AppColors.text6),
      ),

      // Configuration des snackbars
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surface2,
        contentTextStyle: TextStyle(color: AppColors.text6),
        actionTextColor: AppColors.jellyfinPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),

      // Configuration des dialogs
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.background3,
        surfaceTintColor: AppColors.jellyfinPurple,
        titleTextStyle: TextStyle(
          color: AppColors.text6,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: AppColors.text4,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // Configuration des floating action buttons
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.jellyfinPurple,
        foregroundColor: AppColors.text6,
        elevation: 6,
        shape: CircleBorder(),
      ),

      // Configuration des progress indicators
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.jellyfinPurple,
        linearTrackColor: AppColors.surface1,
        circularTrackColor: AppColors.surface1,
      ),

      // Configuration des tabs
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.jellyfinPurple,
        unselectedLabelColor: AppColors.text2,
        indicatorColor: AppColors.jellyfinPurple,
        dividerColor: AppColors.text1,
      ),
    );
  }
}
