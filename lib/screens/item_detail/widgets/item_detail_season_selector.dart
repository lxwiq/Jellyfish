import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../jellyfin/jellyfin_open_api.swagger.dart';
import '../../../providers/item_detail_provider.dart';

/// Widget pour sélectionner une saison d'une série
class ItemDetailSeasonSelector extends ConsumerWidget {
  final String seriesId;
  final List<BaseItemDto> seasons;

  const ItemDetailSeasonSelector({
    super.key,
    required this.seriesId,
    required this.seasons,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedSeasonIndexProvider(seriesId));

    if (seasons.isEmpty) {
      return const SizedBox.shrink();
    }

    // Créer les chips de saisons
    final seasonChips = List.generate(seasons.length, (index) {
      final season = seasons[index];
      final seasonName = season.name ?? 'Saison ${season.indexNumber ?? index + 1}';
      final isSelected = index == selectedIndex;

      return InkWell(
        onTap: () {
          ref.read(selectedSeasonIndexProvider(seriesId).notifier).state = index;
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.jellyfinPurple : AppColors.background3,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.jellyfinPurple : AppColors.surface1,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            seasonName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isSelected ? Colors.white : AppColors.text5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      );
    });

    return SizedBox(
      height: 50,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          },
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: seasonChips.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) => seasonChips[index],
        ),
      ),
    );
  }
}

