import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../theme/app_colors.dart';
import '../../../jellyfin/jellyfin_open_api.swagger.dart';
import '../../../widgets/fallback_image.dart';
import '../../../providers/home_provider.dart';
import '../../video_player/video_player_screen.dart';

/// Carte d'épisode améliorée pour la page de détails
class ItemDetailEpisodeCard extends ConsumerWidget {
  final BaseItemDto episode;
  final bool isDesktop;
  final bool isNextUp;

  const ItemDetailEpisodeCard({
    super.key,
    required this.episode,
    required this.isDesktop,
    this.isNextUp = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Récupérer les URLs d'image avec fallbacks
    final imageUrls = getItemCardBackdropUrls(ref, episode, maxWidth: 320);

    // Informations de l'épisode
    final episodeNumber = episode.indexNumber ?? 0;
    final episodeName = episode.name ?? 'Épisode $episodeNumber';
    final overview = episode.overview ?? '';

    // Progression
    final userData = episode.userData;
    final playbackPositionTicks = userData?.playbackPositionTicks ?? 0;
    final runtimeTicks = episode.runTimeTicks ?? 0;
    final hasProgress = playbackPositionTicks > 0 && runtimeTicks > 0;
    final progressPercentage = hasProgress ? playbackPositionTicks / runtimeTicks : 0.0;

    // État de visionnage
    final isWatched = userData?.played ?? false;
    final isFullyWatched = isWatched || (hasProgress && progressPercentage >= 0.95);

    // Dimensions compactes - juste milieu entre trop grand et trop petit
    final imageWidth = isDesktop ? 240.0 : 160.0;
    final imageHeight = imageWidth / (16 / 9);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isNextUp ? AppColors.background3 : AppColors.background2,
        borderRadius: BorderRadius.circular(12),
        border: isNextUp
            ? Border.all(color: AppColors.jellyfinPurple.withValues(alpha: 0.5), width: 2)
            : null,
      ),
      child: InkWell(
        onTap: () => _playEpisode(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image avec trickplay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: imageWidth,
                      height: imageHeight,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          FallbackImage(
                            imageUrls: imageUrls,
                            fit: BoxFit.cover,
                            memCacheWidth: 480,
                          ),
                          // Overlay si épisode déjà vu
                          if (isFullyWatched)
                            Container(
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Indicateur "À suivre"
                  if (isNextUp && !isFullyWatched)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.jellyfinPurple,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'À SUIVRE',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),

                  // Bouton play au centre
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.jellyfinPurple.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFullyWatched ? IconsaxPlusBold.refresh : IconsaxPlusBold.play,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  // Barre de progression
                  if (hasProgress && progressPercentage < 0.95)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: progressPercentage,
                        backgroundColor: Colors.black.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.jellyfinPurple),
                        minHeight: 3,
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 16),

              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Numéro et titre
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface1,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'E$episodeNumber',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.text4,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            episodeName,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.text5,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Durée et progression
                    Row(
                      children: [
                        if (runtimeTicks > 0) ...[
                          Icon(
                            IconsaxPlusLinear.clock,
                            size: 14,
                            color: AppColors.text3,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatRuntime(runtimeTicks),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.text3,
                            ),
                          ),
                        ],
                        if (hasProgress && progressPercentage < 0.95 && !isFullyWatched) ...[
                          const SizedBox(width: 12),
                          Text(
                            '${(progressPercentage * 100).toInt()}%',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.jellyfinPurple,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Synopsis (seulement sur desktop)
                    if (isDesktop && overview.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        overview,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.text4,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _playEpisode(BuildContext context, WidgetRef ref) {
    if (episode.id == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          itemId: episode.id!,
          item: episode,
          startPositionTicks: episode.userData?.playbackPositionTicks,
        ),
      ),
    );
  }

  String _formatRuntime(int ticks) {
    final minutes = (ticks / 10000000 / 60).round();
    if (minutes < 60) return '${minutes}min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h${remainingMinutes > 0 ? ' ${remainingMinutes}min' : ''}';
  }
}

