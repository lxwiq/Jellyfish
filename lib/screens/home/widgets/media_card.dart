import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/home_provider.dart';
import '../../../jellyfin/jellyfin_open_api.swagger.dart';
import '../../item_detail/item_detail_screen.dart';
import '../../../services/custom_cache_manager.dart';

/// Carte pour afficher un média en cours de lecture
class MediaCard extends ConsumerWidget {
  final BaseItemDto item;
  final bool isDesktop;

  const MediaCard({
    super.key,
    required this.item,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = getItemImageUrl(ref, item, maxWidth: 600);
    final title = item.name ?? 'Sans titre';
    final subtitle = getResumeTimeText(item);
    final progress = getProgressPercentage(item);

    return Container(
      width: isDesktop ? 320 : 280,
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
                          memCacheWidth: 600,
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

