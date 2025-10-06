import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/item_detail_provider.dart';
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
            SizedBox(
              height: isDesktop ? 280 : 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: PosterCard(
                      item: item,
                      width: isDesktop ? 180 : 130,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.jellyfinPurple,
          ),
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

