import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jellyfish/models/jellyseerr_models.dart';
import 'package:jellyfish/theme/app_colors.dart';
import 'package:jellyfish/widgets/card_constants.dart';
import 'package:jellyfish/services/custom_cache_manager.dart';
import '../jellyseerr_media_detail_screen.dart';

/// Carte réutilisable pour afficher un média Jellyseerr
/// Suit les patterns de design de l'application (CardConstants, AppColors, etc.)
class JellyseerrMediaCard extends StatelessWidget {
  final MediaSearchResult media;
  final bool isDesktop;
  final bool isTablet;

  const JellyseerrMediaCard({
    super.key,
    required this.media,
    this.isDesktop = false,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    // Utiliser les tailles standardisées
    final sizes = CardSizeHelper.getSizes(isDesktop, isTablet);
    final cardWidth = sizes.posterWidth;
    final cardHeight = sizes.posterTotalHeight;

    final posterUrl = media.posterPath != null
        ? 'https://image.tmdb.org/t/p/w500${media.posterPath}'
        : null;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => JellyseerrMediaDetailScreen(
              mediaId: media.id,
              mediaType: media.mediaType,
            ),
          ),
        );
      },
      child: Container(
        width: cardWidth,
        height: cardHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du poster
            Container(
              width: cardWidth,
              height: cardWidth / CardConstants.posterAspectRatio,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.surface1,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (posterUrl != null)
                      CachedNetworkImage(
                        imageUrl: posterUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: CardConstants.getOptimalImageWidth(cardWidth),
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
                          child: const Icon(
                            Icons.movie,
                            size: 48,
                            color: AppColors.text3,
                          ),
                        ),
                      )
                    else
                      Container(
                        color: AppColors.surface1,
                        child: const Icon(
                          Icons.movie,
                          size: 48,
                          color: AppColors.text3,
                        ),
                      ),
                    
                    // Badge de type de média
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              media.mediaType == 'movie'
                                  ? Icons.movie
                                  : Icons.tv,
                              size: 12,
                              color: AppColors.text6,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              media.mediaType == 'movie' ? 'Film' : 'Série',
                              style: const TextStyle(
                                color: AppColors.text6,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Note
                    if (media.voteAverage != null && media.voteAverage! > 0)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                size: 12,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                media.voteAverage!.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: AppColors.text6,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Titre
            SizedBox(
              height: CardConstants.posterTextHeight,
              child: Text(
                media.title ?? media.name ?? 'Sans titre',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.text6,
                  fontSize: isDesktop ? 13 : 12,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

