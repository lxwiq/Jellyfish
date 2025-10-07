import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/home_provider.dart';
import '../../../jellyfin/jellyfin_open_api.swagger.dart';
import '../../item_detail/item_detail_screen.dart';
import '../../../services/custom_cache_manager.dart';
import '../../../widgets/card_constants.dart';
import '../../../widgets/series_episode_badge.dart';
import '../../../widgets/downloaded_badge.dart';

/// Carte poster simple pour afficher un film/série
class PosterCard extends ConsumerWidget {
  final BaseItemDto item;
  final double? width; // Optionnel, calculé automatiquement si non fourni
  final bool? isDesktop;
  final bool? isTablet;

  const PosterCard({
    super.key,
    required this.item,
    this.width,
    this.isDesktop,
    this.isTablet,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Déterminer la largeur et les paramètres d'écran
    final screenWidth = MediaQuery.of(context).size.width;
    final effectiveIsDesktop = isDesktop ?? screenWidth >= 900;
    final effectiveIsTablet = isTablet ?? (screenWidth >= 600 && screenWidth < 900);

    final sizes = CardSizeHelper.getSizes(effectiveIsDesktop, effectiveIsTablet);
    final cardWidth = width ?? sizes.posterWidth;

    // Optimiser les paramètres d'image
    final optimalWidth = CardConstants.getOptimalImageWidth(cardWidth);

    // Déterminer le type d'item
    final isEpisode = item.type?.value == 'Episode';
    final isSeries = item.type?.value == 'Series';

    // Pour les épisodes, utiliser le poster de la série parente
    final imageUrl = getItemPosterUrl(ref, item, maxWidth: optimalWidth);

    // Titre et sous-titre
    final String title;
    final String? subtitle;

    if (isEpisode) {
      // Pour les épisodes : afficher le nom de la série
      title = item.seriesName ?? item.name ?? 'Sans titre';
      // Sous-titre : S1:E1 - Episode 1
      final seasonNum = item.parentIndexNumber ?? 0;
      final episodeNum = item.indexNumber ?? 0;
      final episodeName = item.name ?? '';
      subtitle = 'S$seasonNum:E$episodeNum${episodeName.isNotEmpty ? ' - $episodeName' : ''}';
    } else {
      // Pour les films et séries : afficher le nom de l'item
      title = item.name ?? 'Sans titre';
      subtitle = getSeriesMetadata(item);
    }

    return SizedBox(
      width: cardWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image avec ratio d'aspect fixe
          AspectRatio(
            aspectRatio: CardConstants.posterAspectRatio,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (item.id != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ItemDetailScreen(
                              itemId: item.id!,
                              initialItem: item,
                            ),
                          ),
                        );
                      }
                    },
                    child: Stack(
                      children: [
                        // Image
                        Positioned.fill(
                          child: imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  memCacheWidth: optimalWidth,
                                  cacheManager: CustomCacheManager(),
                                  placeholder: (context, url) => Container(
                                    color: AppColors.surface1,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.jellyfinPurple,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: AppColors.surface1,
                                    child: const Center(
                                      child: Icon(
                                        IconsaxPlusLinear.video_square,
                                        size: 40,
                                        color: AppColors.text3,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  color: AppColors.surface1,
                                  child: const Center(
                                    child: Icon(
                                      IconsaxPlusLinear.video_square,
                                      size: 40,
                                      color: AppColors.text3,
                                    ),
                                  ),
                                ),
                        ),
                        // Badge d'épisodes pour les séries
                        if (isSeries)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: SeriesEpisodeBadge(
                              item: item,
                              size: cardWidth * 0.18, // Taille proportionnelle à la carte
                            ),
                          ),
                        // Badge de téléchargement
                        if (item.id != null)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: DownloadedBadge(
                              itemId: item.id!,
                              size: cardWidth * 0.15,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Titre avec hauteur fixe pour éviter la déformation
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.text1,
              height: 1.2,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Sous-titre (métadonnées de la série ou info de l'épisode)
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.text3,
                height: 1.2,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

