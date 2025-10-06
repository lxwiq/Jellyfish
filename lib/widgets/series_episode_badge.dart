import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../theme/app_colors.dart';
import '../jellyfin/jellyfin_open_api.swagger.dart';

/// Badge affichant le nombre d'épisodes restants à voir pour une série
/// Positionné en haut à droite de l'affiche
class SeriesEpisodeBadge extends StatelessWidget {
  final BaseItemDto item;
  final double size;

  const SeriesEpisodeBadge({
    super.key,
    required this.item,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    // Vérifier si c'est une série
    if (item.type?.value != 'Series') {
      return const SizedBox.shrink();
    }

    final unplayedCount = item.userData?.unplayedItemCount ?? 0;
    final hasUnplayedEpisodes = unplayedCount > 0;
    
    // Si aucun épisode non vu et pas de userData, ne rien afficher
    if (!hasUnplayedEpisodes && item.userData == null) {
      return const SizedBox.shrink();
    }

    // Badge pour série entièrement vue
    if (!hasUnplayedEpisodes) {
      return _buildCompletedBadge();
    }

    // Badge avec le nombre d'épisodes restants
    return _buildUnplayedBadge(unplayedCount);
  }

  /// Badge pour série entièrement vue (checkmark)
  Widget _buildCompletedBadge() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.jellyfinPurple,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          IconsaxPlusBold.tick_circle,
          color: Colors.white,
          size: size * 0.65,
        ),
      ),
    );
  }

  /// Badge avec le nombre d'épisodes non vus
  Widget _buildUnplayedBadge(int count) {
    final displayText = count > 99 ? '+99' : count.toString();
    final fontSize = count > 99 ? size * 0.38 : size * 0.45;

    // Calculer la largeur minimale en fonction du nombre de chiffres
    final minWidth = count > 99 ? size * 1.4 : size;

    return Container(
      constraints: BoxConstraints(
        minWidth: minWidth,
        minHeight: size,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.25,
      ),
      decoration: BoxDecoration(
        color: AppColors.jellyfinPurple,
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          displayText,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            height: 1.0,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

