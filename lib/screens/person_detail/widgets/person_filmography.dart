import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/item_detail_provider.dart';
import '../../../jellyfin/jellyfin_open_api.swagger.dart';
import '../../home/widgets/poster_card.dart';
import '../../../widgets/card_constants.dart';

/// Widget affichant la filmographie d'une personne
class PersonFilmography extends ConsumerWidget {
  final String personId;
  final bool isDesktop;

  const PersonFilmography({
    super.key,
    required this.personId,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(personItemsProvider(personId));
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return itemsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        // Grouper les items par type
        final movies = items.where((item) => item.type?.value == 'Movie').toList();
        final series = items.where((item) => item.type?.value == 'Series').toList();
        final episodes = items.where((item) => item.type?.value == 'Episode').toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Films
            if (movies.isNotEmpty) ...[
              _buildSectionTitle(context, 'Films', movies.length),
              const SizedBox(height: 16),
              _buildItemGrid(movies, isDesktop, isTablet),
              const SizedBox(height: 32),
            ],

            // Séries
            if (series.isNotEmpty) ...[
              _buildSectionTitle(context, 'Séries', series.length),
              const SizedBox(height: 16),
              _buildItemGrid(series, isDesktop, isTablet),
              const SizedBox(height: 32),
            ],

            // Épisodes
            if (episodes.isNotEmpty) ...[
              _buildSectionTitle(context, 'Épisodes', episodes.length),
              const SizedBox(height: 16),
              _buildItemGrid(episodes, isDesktop, isTablet),
            ],
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.jellyfinPurple,
        ),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, int count) {
    return Row(
      children: [
        Icon(
          IconsaxPlusLinear.video_play,
          size: 24,
          color: AppColors.jellyfinPurple,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.text1,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.jellyfinPurple.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.jellyfinPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemGrid(List<BaseItemDto> items, bool isDesktop, bool isTablet) {
    final crossAxisCount = isDesktop ? 6 : (isTablet ? 4 : 3);
    final sizes = CardSizeHelper.getSizes(isDesktop, isTablet);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: sizes.posterWidth / sizes.posterTotalHeight,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return PosterCard(
          item: item,
          isDesktop: isDesktop,
          isTablet: isTablet,
        );
      },
    );
  }
}

