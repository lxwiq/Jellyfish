import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/home_provider.dart';
import '../../../jellyfin/jellyfin_open_api.swagger.dart';
import '../../item_detail/item_detail_screen.dart';
import '../../../widgets/card_constants.dart';
import '../../../widgets/fallback_image.dart';

/// Carte pour afficher un épisode
class EpisodeCard extends ConsumerWidget {
  final BaseItemDto item;
  final bool isDesktop;
  final bool? isTablet;

  const EpisodeCard({
    super.key,
    required this.item,
    required this.isDesktop,
    this.isTablet,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Déterminer les tailles
    final screenWidth = MediaQuery.of(context).size.width;
    final effectiveIsTablet = isTablet ?? (screenWidth >= 600 && screenWidth < 900);
    final sizes = CardSizeHelper.getSizes(isDesktop, effectiveIsTablet);
    final cardWidth = sizes.episodeWidth;

    // Optimiser les paramètres d'image - utiliser backdrop pour les épisodes
    final optimalWidth = CardConstants.getOptimalImageWidth(cardWidth);
    final imageUrls = getItemCardBackdropUrls(ref, item, maxWidth: optimalWidth);
    final title = item.seriesName ?? item.name ?? 'Sans titre';
    final subtitle = 'S${item.parentIndexNumber ?? 0}:E${item.indexNumber ?? 0}';

    return SizedBox(
      width: cardWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image avec ratio d'aspect fixe
          AspectRatio(
            aspectRatio: CardConstants.episodeAspectRatio,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background3,
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
                child: Stack(
                  children: [
                    // Image avec fallbacks automatiques
                    Positioned.fill(
                      child: FallbackImage(
                        imageUrls: imageUrls,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        memCacheWidth: optimalWidth,
                      ),
                    ),

                    // Hover overlay
                    Positioned.fill(
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
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.5),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Titre
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.text6,
              fontWeight: FontWeight.w600,
              height: 1.2,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Sous-titre
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.text3,
              height: 1.2,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

