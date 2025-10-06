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
    final imageUrl = getItemImageUrl(ref, item, maxWidth: optimalWidth);
    final title = item.name ?? 'Sans titre';

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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

