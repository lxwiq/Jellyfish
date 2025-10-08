import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/item_detail_provider.dart';
import '../../../widgets/card_constants.dart';
import '../../../widgets/horizontal_carousel.dart';
import '../../home/widgets/poster_card.dart';

/// Widget affichant les items similaires
class ItemDetailSimilar extends ConsumerWidget {
  final String itemId;
  final bool isDesktop;

  const ItemDetailSimilar({
    super.key,
    required this.itemId,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final similarItemsAsync = ref.watch(similarItemsProvider(itemId));

    // Calculer la hauteur basée sur les constantes
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final sizes = CardSizeHelper.getSizes(isDesktop, isTablet);
    final sectionHeight = sizes.posterTotalHeight;

    return similarItemsAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  IconsaxPlusLinear.heart,
                  size: 24,
                  color: AppColors.jellyfinPurple,
                ),
                const SizedBox(width: 12),
                Text(
                  'Suggestions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            HorizontalCarousel(
              height: sectionHeight,
              spacing: 12,
              children: items.map((item) {
                return PosterCard(
                  item: item,
                  isDesktop: isDesktop,
                  isTablet: isTablet,
                );
              }).toList(),
            ),
          ],
        );
      },
      loading: () => SizedBox(
        height: sectionHeight,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.jellyfinPurple,
          ),
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

