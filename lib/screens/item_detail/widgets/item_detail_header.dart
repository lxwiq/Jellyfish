import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/home_provider.dart';
import '../../../jellyfin/jellyfin_open_api.swagger.dart';
import '../../../providers/services_provider.dart';
import '../../../widgets/resume_play_button.dart';
import '../../video_player/video_player_screen.dart';

/// Header de la page de détails avec backdrop et informations principales
class ItemDetailHeader extends ConsumerWidget {
  final BaseItemDto item;
  final bool isDesktop;

  const ItemDetailHeader({
    super.key,
    required this.item,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backdropUrl = getItemBackdropUrl(ref, item, maxWidth: 1920);
    final posterUrl = getItemImageUrl(ref, item, maxWidth: 400);

    return SliverAppBar(
      expandedHeight: isDesktop ? 450 : 350,
      pinned: true,
      backgroundColor: AppColors.background2,
      foregroundColor: AppColors.text6,
      leading: IconButton(
        icon: const Icon(IconsaxPlusLinear.arrow_left),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image backdrop
            if (backdropUrl != null)
              CachedNetworkImage(
                imageUrl: backdropUrl,
                fit: BoxFit.cover,
                memCacheWidth: 1920,
                placeholder: (context, url) => Container(
                  color: AppColors.surface1,
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.surface1,
                ),
              )
            else
              Container(
                color: AppColors.surface1,
              ),

            // Gradient overlay - plus sombre pour mieux voir le texte
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.8),
                    AppColors.background1,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),

            // Contenu en bas
            Positioned(
              left: isDesktop ? 32 : 16,
              right: isDesktop ? 32 : 16,
              bottom: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Poster
                  if (posterUrl != null)
                    Container(
                      width: isDesktop ? 150 : 100,
                      height: isDesktop ? 225 : 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: posterUrl,
                          fit: BoxFit.cover,
                          memCacheWidth: 400,
                          placeholder: (context, url) => Container(
                            color: AppColors.surface1,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.surface1,
                            child: const Icon(
                              IconsaxPlusLinear.video_square,
                              size: 40,
                              color: AppColors.text3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  const SizedBox(width: 16),

                  // Titre et infos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo ou Titre
                        _buildTitleOrLogo(context, ref),

                        const SizedBox(height: 8),

                        // Infos rapides (année, durée, note)
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            if (item.productionYear != null)
                              _buildInfoChip(
                                context,
                                item.productionYear.toString(),
                                IconsaxPlusLinear.calendar,
                              ),
                            if (item.runTimeTicks != null)
                              _buildInfoChip(
                                context,
                                _formatRuntime(item.runTimeTicks!),
                                IconsaxPlusLinear.clock,
                              ),
                            if (item.officialRating != null)
                              _buildInfoChip(
                                context,
                                item.officialRating!,
                                IconsaxPlusLinear.shield_tick,
                              ),
                            if (item.communityRating != null)
                              _buildInfoChip(
                                context,
                                '⭐ ${item.communityRating!.toStringAsFixed(1)}',
                                null,
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Boutons d'action
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ResumePlayButton(
                              item: item,
                              onPressed: () {
                                if (item.id != null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => VideoPlayerScreen(
                                        itemId: item.id!,
                                        item: item,
                                        startPositionTicks: item.userData?.playbackPositionTicks,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Ajouter aux favoris
                              },
                              icon: Icon(
                                item.userData?.isFavorite == true
                                    ? IconsaxPlusBold.heart
                                    : IconsaxPlusLinear.heart,
                              ),
                              label: const Text('Favoris'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white54),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildInfoChip(BuildContext context, String text, IconData? icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white24,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleOrLogo(BuildContext context, WidgetRef ref) {
    final jellyfinService = ref.watch(jellyfinServiceProvider);

    // Vérifier si un logo existe
    final hasLogo = item.imageTags != null &&
                    item.imageTags!.containsKey('Logo') &&
                    item.id != null;

    if (hasLogo) {
      final logoUrl = jellyfinService.getLogoUrl(
        item.id!,
        tag: item.imageTags!['Logo'],
        maxHeight: 120,
      );

      if (logoUrl != null) {
        return CachedNetworkImage(
          imageUrl: logoUrl,
          height: 120,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
          placeholder: (context, url) => _buildTitleText(context),
          errorWidget: (context, url, error) => _buildTitleText(context),
        );
      }
    }

    return _buildTitleText(context);
  }

  Widget _buildTitleText(BuildContext context) {
    return Text(
      item.name ?? 'Sans titre',
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 8,
          ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _formatRuntime(int ticks) {
    final minutes = (ticks / 10000000 / 60).round();
    if (minutes < 60) {
      return '${minutes}min';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h${remainingMinutes > 0 ? ' ${remainingMinutes}min' : ''}';
  }
}

