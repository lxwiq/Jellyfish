import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jellyfish/theme/app_colors.dart';
import 'package:jellyfish/services/custom_cache_manager.dart';
import 'package:jellyfish/widgets/horizontal_carousel.dart';
import 'package:jellyfish/models/jellyseerr_models.dart';

/// Section du casting avec photos des acteurs
class MediaCastSection extends StatelessWidget {
  final List<CastMember> cast;
  final bool isDesktop;

  const MediaCastSection({
    super.key,
    required this.cast,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    if (cast.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 16,
            vertical: 16,
          ),
          child: Text(
            'Casting',
            style: TextStyle(
              fontSize: isDesktop ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text6,
            ),
          ),
        ),
        HorizontalCarousel(
          height: isDesktop ? 220 : 180,
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16),
          spacing: 12,
          children: cast.take(15).map((member) {
            return _buildCastCard(member);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCastCard(CastMember member) {
    final profileUrl = member.profilePath != null
        ? 'https://image.tmdb.org/t/p/w185${member.profilePath}'
        : null;

    return SizedBox(
      width: isDesktop ? 140 : 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo de l'acteur
          Container(
            width: isDesktop ? 140 : 110,
            height: isDesktop ? 160 : 130,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.surface1,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: profileUrl != null
                  ? CachedNetworkImage(
                      imageUrl: profileUrl,
                      fit: BoxFit.cover,
                      cacheManager: CustomCacheManager(),
                      placeholder: (context, url) => Container(
                        color: AppColors.surface1,
                        child: const Icon(
                          Icons.person,
                          size: 48,
                          color: AppColors.text3,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.surface1,
                        child: const Icon(
                          Icons.person,
                          size: 48,
                          color: AppColors.text3,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.surface1,
                      child: const Icon(
                        Icons.person,
                        size: 48,
                        color: AppColors.text3,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          // Nom de l'acteur
          Text(
            member.name ?? 'Inconnu',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isDesktop ? 13 : 12,
              fontWeight: FontWeight.w600,
              color: AppColors.text6,
            ),
          ),
          // Nom du personnage
          if (member.character != null && member.character!.isNotEmpty)
            Text(
              member.character!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isDesktop ? 12 : 11,
                color: AppColors.text4,
              ),
            ),
        ],
      ),
    );
  }
}
