import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:jellyfish/theme/app_colors.dart';

/// Section d'informations du média (date, durée, genres)
class MediaInfoSection extends StatelessWidget {
  final String? releaseDate;
  final int? runtime;
  final List<String> genres;
  final bool isDesktop;

  const MediaInfoSection({
    super.key,
    this.releaseDate,
    this.runtime,
    required this.genres,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 16,
        vertical: 16,
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          // Date de sortie
          if (releaseDate != null)
            _buildInfoChip(
              icon: IconsaxPlusBold.calendar,
              label: releaseDate!,
            ),

          // Durée
          if (runtime != null && runtime! > 0)
            _buildInfoChip(
              icon: IconsaxPlusBold.clock,
              label: _formatRuntime(runtime!),
            ),

          // Genres
          ...genres.map((genre) => _buildGenreChip(genre)),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.surface2,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.jellyfinPurple,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.text5,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreChip(String genre) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.jellyfinPurple.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.jellyfinPurple.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        genre,
        style: const TextStyle(
          color: AppColors.jellyfinPurple,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatRuntime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}min';
    }
    return '${mins}min';
  }
}

