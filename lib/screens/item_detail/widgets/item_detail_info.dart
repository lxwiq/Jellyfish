import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../theme/app_colors.dart';
import '../../../jellyfin/jellyfin_open_api.swagger.dart';
import '../../../providers/services_provider.dart';
import '../../../services/custom_cache_manager.dart';

/// Widget affichant les informations détaillées d'un item
class ItemDetailInfo extends ConsumerWidget {
  final BaseItemDto item;

  const ItemDetailInfo({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jellyfinService = ref.watch(jellyfinServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Synopsis
        if (item.overview != null && item.overview!.isNotEmpty) ...[
          _buildSectionTitle(context, 'Synopsis', IconsaxPlusLinear.document_text),
          const SizedBox(height: 16),
          Text(
            item.overview!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.text4,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
        ],

        // Informations
        _buildSectionTitle(context, 'Informations', IconsaxPlusLinear.info_circle),
        const SizedBox(height: 16),
        _buildInfoGrid(context),

        const SizedBox(height: 32),

        // Genres
        if (item.genres != null && item.genres!.isNotEmpty) ...[
          _buildSectionTitle(context, 'Genres', IconsaxPlusLinear.category),
          const SizedBox(height: 16),
          _buildGenreChips(context),
          const SizedBox(height: 32),
        ],

        // Tags
        if (item.tags != null && item.tags!.isNotEmpty) ...[
          _buildSectionTitle(context, 'Tags', IconsaxPlusLinear.tag),
          const SizedBox(height: 16),
          _buildTagChips(context),
          const SizedBox(height: 32),
        ],

        // Studios avec logos
        if (item.studios != null && item.studios!.isNotEmpty) ...[
          _buildSectionTitle(context, 'Studios', IconsaxPlusLinear.building),
          const SizedBox(height: 16),
          _buildStudioLogos(jellyfinService),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
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
      ],
    );
  }

  Widget _buildInfoGrid(BuildContext context) {
    final infos = <Map<String, String>>[];

    // Réalisateur(s)
    if (item.people != null) {
      final directors = item.people!
          .where((p) => p.type?.value?.toLowerCase() == 'director')
          .map((p) => p.name ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
      if (directors.isNotEmpty) {
        infos.add({
          'label': directors.length > 1 ? 'Réalisateurs' : 'Réalisateur',
          'value': directors.join(', '),
        });
      }
    }

    // Scénaristes
    if (item.people != null) {
      final writers = item.people!
          .where((p) => p.type?.value?.toLowerCase() == 'writer')
          .map((p) => p.name ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
      if (writers.isNotEmpty) {
        infos.add({
          'label': writers.length > 1 ? 'Scénaristes' : 'Scénariste',
          'value': writers.join(', '),
        });
      }
    }

    // Date de sortie
    if (item.premiereDate != null) {
      infos.add({
        'label': 'Date de sortie',
        'value': _formatDate(item.premiereDate!),
      });
    }

    // Année
    if (item.productionYear != null && item.premiereDate == null) {
      infos.add({
        'label': 'Année',
        'value': item.productionYear.toString(),
      });
    }

    // Durée
    if (item.runTimeTicks != null) {
      infos.add({
        'label': 'Durée',
        'value': _formatRuntime(item.runTimeTicks!),
      });
    }

    // Classification
    if (item.officialRating != null) {
      infos.add({
        'label': 'Classification',
        'value': item.officialRating!,
      });
    }

    // Note communautaire
    if (item.communityRating != null) {
      infos.add({
        'label': 'Note',
        'value': '⭐ ${item.communityRating!.toStringAsFixed(1)}/10',
      });
    }


    // Note critique
    if (item.criticRating != null) {
      infos.add({
        'label': 'Note critique',
        'value': '${item.criticRating!.toStringAsFixed(0)}%',
      });
    }

    // Titre original
    if (item.originalTitle != null &&
        item.originalTitle!.isNotEmpty &&
        item.originalTitle != item.name) {
      infos.add({
        'label': 'Titre original',
        'value': item.originalTitle!,
      });
    }

    // Statut
    if (item.status != null && item.status!.isNotEmpty) {
      infos.add({
        'label': 'Statut',
        'value': item.status!,
      });
    }

    // Nombre de saisons
    if (item.childCount != null && item.type?.value == 'Series') {
      infos.add({
        'label': 'Saisons',
        'value': '${item.childCount} saison${item.childCount! > 1 ? 's' : ''}',
      });
    }

    return Wrap(
      spacing: 24,
      runSpacing: 16,
      children: infos.map((info) {
        return SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info['label']!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.text3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                info['value']!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.text5,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGenreChips(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: item.genres!.map((genre) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.background3,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.jellyfinPurple.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            genre,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.text5,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTagChips(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: item.tags!.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.text3.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            tag,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.text4,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStudioLogos(dynamic jellyfinService) {
    return Builder(
      builder: (context) {
        return Wrap(
          spacing: 24,
          runSpacing: 16,
          children: item.studios!.map((studio) {
            if (studio.id != null) {
              final logoUrl = jellyfinService.getLogoUrl(studio.id!, maxHeight: 50);
              if (logoUrl != null) {
                return CachedNetworkImage(
                  imageUrl: logoUrl,
                  height: 50,
                  fit: BoxFit.contain,
                  cacheManager: CustomCacheManager(),
                  placeholder: (context, url) => const SizedBox(height: 50, width: 100),
                  errorWidget: (context, url, error) => _buildStudioName(context, studio.name),
                );
              }
            }
            return _buildStudioName(context, studio.name);
          }).toList(),
        );
      },
    );
  }

  Widget _buildStudioName(BuildContext context, String? name) {
    if (name == null || name.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background3,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surface1, width: 1),
      ),
      child: Text(
        name,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.text5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatRuntime(int ticks) {
    final minutes = (ticks / 10000000 / 60).round();
    if (minutes < 60) return '${minutes}min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h${remainingMinutes > 0 ? ' ${remainingMinutes}min' : ''}';
  }
}
