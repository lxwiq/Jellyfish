import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jellyfish/theme/app_colors.dart';
import 'package:jellyfish/services/custom_cache_manager.dart';

/// Header avec backdrop et poster pour l'écran de détails
class MediaDetailHeader extends StatelessWidget {
  final String? backdropUrl;
  final String? posterUrl;
  final String title;
  final double? voteAverage;
  final bool isDesktop;

  const MediaDetailHeader({
    super.key,
    this.backdropUrl,
    this.posterUrl,
    required this.title,
    this.voteAverage,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: isDesktop ? 400 : 300,
      pinned: true,
      backgroundColor: AppColors.background2,
      foregroundColor: AppColors.text6,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.text6,
            shadows: [
              Shadow(
                color: Colors.black,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image de fond (backdrop)
            if (backdropUrl != null)
              CachedNetworkImage(
                imageUrl: backdropUrl!,
                fit: BoxFit.cover,
                cacheManager: CustomCacheManager(),
                placeholder: (context, url) => Container(
                  color: AppColors.background3,
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.background3,
                ),
              )
            else
              Container(color: AppColors.background3),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Poster et note en bas à gauche
            Positioned(
              bottom: 16,
              left: isDesktop ? 32 : 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Poster
                  if (posterUrl != null)
                    Container(
                      width: isDesktop ? 120 : 80,
                      height: isDesktop ? 180 : 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: posterUrl!,
                          fit: BoxFit.cover,
                          cacheManager: CustomCacheManager(),
                          placeholder: (context, url) => Container(
                            color: AppColors.surface1,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.surface1,
                            child: const Icon(
                              Icons.movie,
                              color: AppColors.text3,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Note
                  if (voteAverage != null && voteAverage! > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              voteAverage!.toStringAsFixed(1),
                              style: const TextStyle(
                                color: AppColors.text6,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              ' / 10',
                              style: TextStyle(
                                color: AppColors.text4,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

