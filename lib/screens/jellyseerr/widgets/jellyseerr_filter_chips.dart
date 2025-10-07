import 'package:flutter/material.dart';
import 'package:jellyfish/theme/app_colors.dart';
import 'package:jellyfish/models/jellyseerr_models.dart';

/// Widget de chips de filtrage pour les genres
/// Horizontal scrollable avec design cohérent
class JellyseerrFilterChips extends StatelessWidget {
  final List<Genre> genres;
  final List<int> selectedGenreIds;
  final Function(int) onGenreToggle;
  final bool isDesktop;

  const JellyseerrFilterChips({
    super.key,
    required this.genres,
    required this.selectedGenreIds,
    required this.onGenreToggle,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    if (genres.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16),
        itemCount: genres.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final genre = genres[index];
          final isSelected = selectedGenreIds.contains(genre.id);

          return FilterChip(
            label: Text(genre.name),
            selected: isSelected,
            onSelected: (selected) => onGenreToggle(genre.id),
            backgroundColor: AppColors.surface1,
            selectedColor: AppColors.jellyfinPurple.withValues(alpha: 0.3),
            checkmarkColor: AppColors.jellyfinPurple,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.jellyfinPurple : AppColors.text5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
            side: BorderSide(
              color: isSelected
                  ? AppColors.jellyfinPurple
                  : AppColors.surface2,
              width: isSelected ? 1.5 : 1,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }
}

