import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../theme/app_colors.dart';
import '../jellyfin/jellyfin_open_api.swagger.dart';

/// Bouton de lecture avec progress bar pour reprendre une vidéo
class ResumePlayButton extends StatelessWidget {
  final BaseItemDto item;
  final VoidCallback onPressed;

  const ResumePlayButton({
    super.key,
    required this.item,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final userData = item.userData;
    final playbackPositionTicks = userData?.playbackPositionTicks ?? 0;
    final runtimeTicks = item.runTimeTicks ?? 0;
    
    // Si pas de progression ou vidéo terminée (>95%), afficher bouton normal
    if (playbackPositionTicks == 0 || runtimeTicks == 0) {
      return _buildNormalPlayButton();
    }
    
    final progressPercentage = playbackPositionTicks / runtimeTicks;
    
    // Si la vidéo est presque terminée (>95%), afficher bouton normal
    if (progressPercentage > 0.95) {
      return _buildNormalPlayButton();
    }
    
    // Sinon, afficher le bouton avec progress bar
    return _buildResumeButton(progressPercentage);
  }

  Widget _buildNormalPlayButton() {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(IconsaxPlusBold.play),
      label: const Text('Lire'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.jellyfinPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildResumeButton(double progressPercentage) {
    final remainingTime = _formatRemainingTime();

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.jellyfinPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ligne principale avec icône et texte
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                IconsaxPlusBold.play,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Reprendre',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (remainingTime.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  remainingTime,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 6),

          // Progress bar compacte
          Container(
            height: 3,
            width: 120, // Largeur fixe pour garder le bouton compact
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1.5),
              color: Colors.white.withValues(alpha: 0.3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progressPercentage.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1.5),
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRemainingTime() {
    final userData = item.userData;
    if (userData == null) return '';
    
    final playbackPositionTicks = userData.playbackPositionTicks ?? 0;
    final runtimeTicks = item.runTimeTicks ?? 0;
    
    if (runtimeTicks == 0) return '';
    
    final remainingTicks = runtimeTicks - playbackPositionTicks;
    final remainingMinutes = (remainingTicks / 600000000).round();
    
    if (remainingMinutes < 60) {
      return '$remainingMinutes min restantes';
    } else {
      final hours = remainingMinutes ~/ 60;
      final minutes = remainingMinutes % 60;
      return '${hours}h${minutes > 0 ? ' ${minutes}min' : ''} restantes';
    }
  }

}
