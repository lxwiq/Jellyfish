import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/home_provider.dart';
import '../../../jellyfin/jellyfin_open_api.swagger.dart';
import '../../item_detail/item_detail_screen.dart';
import '../../../widgets/card_constants.dart';
import '../../../widgets/series_episode_badge.dart';
import '../../../widgets/fallback_image.dart';

/// Carte pour afficher un média en cours de lecture
class MediaCard extends ConsumerWidget {
  final BaseItemDto item;
  final bool isDesktop;
  final bool? isTablet;

  const MediaCard({
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
    final cardWidth = sizes.mediaWidth;

    // Optimiser les paramètres d'image - utiliser backdrop au lieu de poster
    final optimalWidth = CardConstants.getOptimalImageWidth(cardWidth);
    final imageUrls = getItemCardBackdropUrls(ref, item, maxWidth: optimalWidth);
    final title = item.name ?? 'Sans titre';
    final subtitle = getResumeTimeText(item);
    final progress = getProgressPercentage(item);
    final metadata = getSeriesMetadata(item);
    final isSeries = item.type?.value == 'Series';

    return SizedBox(
      width: cardWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image avec ratio d'aspect fixe
          AspectRatio(
            aspectRatio: CardConstants.mediaAspectRatio,
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

                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
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
                    ),

                    // Bouton play
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.jellyfinPurple.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          IconsaxPlusBold.play,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),

                    // Barre de progression
                    if (progress > 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.jellyfinPurple,
                          ),
                          minHeight: 4,
                        ),
                      ),

                    // Badge d'épisodes pour les séries
                    if (isSeries)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: SeriesEpisodeBadge(
                          item: item,
                          size: cardWidth * 0.12, // Taille proportionnelle à la carte
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
          // Sous-titre (temps restant ou métadonnées de série)
          Text(
            metadata ?? (subtitle.isNotEmpty ? subtitle : ''),
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

