import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/home_provider.dart';
import '../../../jellyfin/jellyfin_open_api.swagger.dart';
import '../../item_detail/item_detail_screen.dart';
import '../../../services/custom_cache_manager.dart';

/// Carte pour afficher un épisode
class EpisodeCard extends ConsumerWidget {
  final BaseItemDto item;
  final bool isDesktop;

  const EpisodeCard({
    super.key,
    required this.item,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = getItemImageUrl(ref, item, maxWidth: 400);
    final title = item.seriesName ?? item.name ?? 'Sans titre';
    final subtitle = 'S${item.parentIndexNumber ?? 0}:E${item.indexNumber ?? 0}';

    return Container(
      width: isDesktop ? 160 : 140,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
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
                    // Image ou placeholder
                    if (imageUrl != null)
                      Positioned.fill(
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          memCacheWidth: 400,
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
                                color: AppColors.text2,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        color: AppColors.surface1,
                        child: const Center(
                          child: Icon(
                            IconsaxPlusLinear.video_square,
                            size: 40,
                            color: AppColors.text2,
                          ),
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
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.text6,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.text3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

