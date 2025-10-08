import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../theme/app_colors.dart';
import '../../../jellyfin/jellyfin_open_api.swagger.dart';
import '../../../providers/services_provider.dart';
import '../../../services/custom_cache_manager.dart';

/// Header de la page de détails d'une personne avec photo et nom
class PersonDetailHeader extends ConsumerWidget {
  final BaseItemDto person;
  final bool isDesktop;

  const PersonDetailHeader({
    super.key,
    required this.person,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jellyfinService = ref.watch(jellyfinServiceProvider);
    final primaryImageTag = person.imageTags?['Primary'] as String?;
    final imageUrl = person.id != null && primaryImageTag != null
        ? jellyfinService.getImageUrl(
            person.id!,
            tag: primaryImageTag,
            maxWidth: 800,
          )
        : null;

    return SliverAppBar(
      expandedHeight: isDesktop ? 400 : 300,
      pinned: true,
      backgroundColor: AppColors.background2,
      foregroundColor: AppColors.text6,
      leading: IconButton(
        icon: const Icon(IconsaxPlusLinear.arrow_left),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          person.name ?? 'Inconnu',
          style: TextStyle(
            color: AppColors.text6,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image de la personne
            if (imageUrl != null)
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                cacheManager: CustomCacheManager(),
                placeholder: (context, url) => Container(
                  color: AppColors.surface1,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.jellyfinPurple,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => _buildPlaceholder(),
              )
            else
              _buildPlaceholder(),

            // Gradient overlay
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.background2.withValues(alpha: 0.8),
                      AppColors.background2,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surface1,
      child: const Center(
        child: Icon(
          IconsaxPlusLinear.user,
          size: 120,
          color: AppColors.text3,
        ),
      ),
    );
  }
}

