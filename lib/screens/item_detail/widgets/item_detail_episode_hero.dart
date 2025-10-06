import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../theme/app_colors.dart';
import '../../../jellyfin/jellyfin_open_api.swagger.dart';
import '../../../widgets/fallback_image.dart';
import '../../../providers/home_provider.dart';
import '../../video_player/video_player_screen.dart';

/// Widget hero pour afficher l'épisode en cours ou le premier épisode
class ItemDetailEpisodeHero extends ConsumerWidget {
  final BaseItemDto episode;
  final bool isNextUp;
  final bool isDesktop;

  const ItemDetailEpisodeHero({
    super.key,
    required this.episode,
    required this.isNextUp,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Récupérer les URLs d'image avec fallbacks
    final imageUrlsNullable = getItemCardBackdropUrls(ref, episode, maxWidth: 800);
    final imageUrls = imageUrlsNullable.whereType<String>().toList();

    // Informations de l'épisode
    final episodeNumber = episode.indexNumber ?? 0;
    final seasonNumber = episode.parentIndexNumber ?? 1;
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

    // Mise en page différente selon desktop/mobile
    if (isDesktop) {
      return _buildDesktopLayout(context, ref, episodeNumber, seasonNumber, episodeName, overview, hasProgress, progressPercentage, isFullyWatched, runtimeTicks, imageUrls);
    } else {
      return _buildMobileLayout(context, ref, episodeNumber, seasonNumber, episodeName, overview, hasProgress, progressPercentage, isFullyWatched, runtimeTicks, imageUrls);
    }
  }

  // Layout desktop : image à gauche, infos à droite
  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    int episodeNumber,
    int seasonNumber,
    String episodeName,
    String overview,
    bool hasProgress,
    double progressPercentage,
    bool isFullyWatched,
    int runtimeTicks,
    List<String> imageUrls,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image à gauche (40% de la largeur)
          Expanded(
            flex: 4,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FallbackImage(
                  imageUrls: imageUrls,
                  fit: BoxFit.cover,
                  memCacheWidth: 800,
                ),
              ),
            ),
          ),

          const SizedBox(width: 24),

          // Informations à droite (60% de la largeur)
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                  // Badge "À suivre" ou "Épisode 1"
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isNextUp ? AppColors.jellyfinPurple : AppColors.surface1,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isNextUp ? 'À SUIVRE' : 'PREMIER ÉPISODE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                // Titre de l'épisode
                Text(
                  'S$seasonNumber:E$episodeNumber - $episodeName',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.text5,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Synopsis
                if (overview.isNotEmpty)
                  Text(
                    overview,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.text4,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 20),

                // Boutons d'action
                Row(
                  children: [
                    // Bouton Play/Replay
                    ElevatedButton.icon(
                      onPressed: () => _playEpisode(context, ref, episode),
                      icon: Icon(
                        isFullyWatched ? IconsaxPlusBold.refresh : IconsaxPlusBold.play,
                        size: 18,
                      ),
                      label: Text(
                        isFullyWatched ? 'Revoir' : (hasProgress ? 'Reprendre' : 'Lire'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.jellyfinPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Durée et progression
                    if (runtimeTicks > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface1,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              IconsaxPlusLinear.clock,
                              size: 14,
                              color: AppColors.text4,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatRuntime(runtimeTicks),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.text4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (hasProgress && !isFullyWatched) ...[
                              const SizedBox(width: 8),
                              Text(
                                '• ${(progressPercentage * 100).toInt()}%',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.jellyfinPurple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),

                // Barre de progression
                if (hasProgress && !isFullyWatched) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progressPercentage,
                      backgroundColor: AppColors.surface1,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.jellyfinPurple),
                      minHeight: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Layout mobile : image en haut, infos en bas (comme avant)
  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    int episodeNumber,
    int seasonNumber,
    String episodeName,
    String overview,
    bool hasProgress,
    double progressPercentage,
    bool isFullyWatched,
    int runtimeTicks,
    List<String> imageUrls,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            // Image de fond
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FallbackImage(
                      imageUrls: imageUrls,
                      fit: BoxFit.cover,
                      memCacheWidth: 800,
                    ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Contenu
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge "À suivre" ou "Épisode 1"
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isNextUp ? AppColors.jellyfinPurple : AppColors.surface1,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isNextUp ? 'À SUIVRE' : 'PREMIER ÉPISODE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Titre de l'épisode
                  Text(
                    'S$seasonNumber:E$episodeNumber - $episodeName',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Bouton Play/Replay
                  ElevatedButton.icon(
                    onPressed: () => _playEpisode(context, ref, episode),
                    icon: Icon(
                      isFullyWatched ? IconsaxPlusBold.refresh : IconsaxPlusBold.play,
                      size: 16,
                    ),
                    label: Text(
                      isFullyWatched ? 'Revoir' : (hasProgress ? 'Reprendre' : 'Lire'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.jellyfinPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  // Barre de progression
                  if (hasProgress && !isFullyWatched) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progressPercentage,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.jellyfinPurple),
                        minHeight: 3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _playEpisode(BuildContext context, WidgetRef ref, BaseItemDto episode) {
    if (episode.id == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          itemId: episode.id!,
          startPositionTicks: episode.userData?.playbackPositionTicks,
        ),
      ),
    );
  }

  String _formatRuntime(int ticks) {
    final duration = Duration(microseconds: ticks ~/ 10);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }
}

