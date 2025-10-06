/// Constantes pour les cartes et images
/// Définit les ratios d'aspect, tailles et paramètres standardisés
class CardConstants {
  CardConstants._();

  // Ratios d'aspect standardisés
  static const double posterAspectRatio = 2/3; // Format poster classique (largeur/hauteur)
  static const double episodeAspectRatio = 16/9; // Format épisode/backdrop
  static const double mediaAspectRatio = 16/9; // Format média en cours de lecture

  // Tailles des cartes par type d'écran
  static const CardSizes mobile = CardSizes(
    posterWidth: 120,
    episodeWidth: 140,
    mediaWidth: 260,
  );

  static const CardSizes tablet = CardSizes(
    posterWidth: 140,
    episodeWidth: 160,
    mediaWidth: 280,
  );

  static const CardSizes desktop = CardSizes(
    posterWidth: 160,
    episodeWidth: 180,
    mediaWidth: 320,
  );

  // Hauteurs des zones de texte (fixes pour éviter la déformation)
  // Espacement + titre (2 lignes à 12px avec height 1.2) = 6 + (12 * 1.2 * 2) = 6 + 28.8 ≈ 35
  static const double posterTextHeight = 35.0;

  // Espacement + titre (1 ligne) + espacement + sous-titre = 6 + 14.4 + 2 + 13.2 ≈ 36
  static const double textAreaHeight = 36.0;

  // Paramètres d'optimisation des images
  static int getOptimalImageWidth(double displayWidth) {
    // Retourne une largeur optimisée pour le cache (multiple de 50)
    return ((displayWidth * 1.5).ceil() ~/ 50) * 50;
  }

  static int getOptimalImageHeight(double displayWidth, double aspectRatio) {
    final height = displayWidth / aspectRatio;
    return ((height * 1.5).ceil() ~/ 50) * 50;
  }
}

/// Classe pour définir les tailles des cartes selon le type d'écran
class CardSizes {
  final double posterWidth;
  final double episodeWidth;
  final double mediaWidth;

  const CardSizes({
    required this.posterWidth,
    required this.episodeWidth,
    required this.mediaWidth,
  });

  // Calcul des hauteurs basées sur les ratios d'aspect
  double get posterHeight => posterWidth / CardConstants.posterAspectRatio;
  double get episodeHeight => episodeWidth / CardConstants.episodeAspectRatio;
  double get mediaHeight => mediaWidth / CardConstants.mediaAspectRatio;

  // Hauteurs totales incluant la zone de texte
  // Pour poster: image + espacement + titre (2 lignes)
  double get posterTotalHeight => posterHeight + CardConstants.posterTextHeight;
  // Pour épisode et média: image + espacement + titre + sous-titre
  double get episodeTotalHeight => episodeHeight + CardConstants.textAreaHeight;
  double get mediaTotalHeight => mediaHeight + CardConstants.textAreaHeight;
}

/// Helper pour obtenir les tailles selon le type d'écran
class CardSizeHelper {
  static CardSizes getSizes(bool isDesktop, bool isTablet) {
    if (isDesktop) return CardConstants.desktop;
    if (isTablet) return CardConstants.tablet;
    return CardConstants.mobile;
  }

  static CardSizes getSizesFromWidth(double screenWidth) {
    if (screenWidth >= 900) return CardConstants.desktop;
    if (screenWidth >= 600) return CardConstants.tablet;
    return CardConstants.mobile;
  }
}
