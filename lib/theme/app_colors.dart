import 'package:flutter/material.dart';

/// Palette de couleurs pour le thème dark du client Jellyfin
class AppColors {
  AppColors._();

  // Arrière-plans
  static const Color background1 = Color(0xFF09090B); // #09090b
  static const Color background2 = Color(0xFF18181B); // #18181b
  static const Color background3 = Color(0xFF27272A); // #27272a

  // Surfaces
  static const Color surface1 = Color(0xFF3F3F46); // #3f3f46
  static const Color surface2 = Color(0xFF52525B); // #52525b

  // Textes et icônes (du plus sombre au plus clair)
  static const Color text1 = Color(0xFF71717A); // #71717a
  static const Color text2 = Color(0xFFA1A1AA); // #a1a1aa
  static const Color text3 = Color(0xFFD4D4D8); // #d4d4d8
  static const Color text4 = Color(0xFFE4E4E7); // #e4e4e7
  static const Color text5 = Color(0xFFF4F4F5); // #f4f4f5
  static const Color text6 = Color(0xFFFAFAFA); // #fafafa

  // Couleurs d'accent Jellyfin
  static const Color jellyfinPurple = Color(0xFF00A4DC);
  static const Color jellyfinBlue = Color(0xFF0078D4);

  // Couleurs système
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
}
