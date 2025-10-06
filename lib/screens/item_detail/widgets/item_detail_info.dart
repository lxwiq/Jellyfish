import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../theme/app_colors.dart';
import '../../../jellyfin/jellyfin_open_api.swagger.dart';
import '../../../providers/services_provider.dart';
import '../../../services/custom_cache_manager.dart';
import '../../../widgets/horizontal_carousel.dart';

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
          _buildGenreCarousel(context),
          const SizedBox(height: 32),
        ],

        // Tags
        if (item.tags != null && item.tags!.isNotEmpty) ...[
          _buildSectionTitle(context, 'Tags', IconsaxPlusLinear.tag),
          const SizedBox(height: 16),
          _buildTagCarousel(context),
          const SizedBox(height: 32),
        ],

        // Studios avec logos
        if (item.studios != null && item.studios!.isNotEmpty) ...[
          _buildSectionTitle(context, 'Studios', IconsaxPlusLinear.building),
          const SizedBox(height: 16),
          _buildStudioCarousel(jellyfinService),
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

    // Années de diffusion pour les séries
    if (item.type?.value == 'Series') {
      final startYear = item.productionYear;
      if (startYear != null) {
        String yearDisplay = startYear.toString();

        // Si la série a une date de fin
        if (item.endDate != null) {
          final endYear = item.endDate!.year;
          if (endYear != startYear) {
            yearDisplay = '$startYear-$endYear';
          }
        } else if (item.status?.toLowerCase() != 'ended') {
          // Si la série est en cours
          yearDisplay = '$startYear-';
        }

        infos.add({
          'label': 'Années de diffusion',
          'value': yearDisplay,
        });
      }
    } else {
      // Année pour les films et autres
      if (item.productionYear != null && item.premiereDate == null) {
        infos.add({
          'label': 'Année',
          'value': item.productionYear.toString(),
        });
      }
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

    // Statut (avec traduction pour les séries)
    if (item.status != null && item.status!.isNotEmpty) {
      String statusDisplay = item.status!;

      // Traduire les statuts courants pour les séries
      if (item.type?.value == 'Series') {
        final statusLower = item.status!.toLowerCase();
        switch (statusLower) {
          case 'continuing':
            statusDisplay = 'En production';
            break;
          case 'ended':
            statusDisplay = 'Terminée';
            break;
          case 'unreleased':
            statusDisplay = 'À venir';
            break;
          default:
            // Capitaliser la première lettre pour les autres statuts
            statusDisplay = statusLower[0].toUpperCase() + statusLower.substring(1);
        }
      }

      infos.add({
        'label': 'Statut',
        'value': statusDisplay,
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

  Widget _buildGenreCarousel(BuildContext context) {
    final genreChips = item.genres!.map((genre) {
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
    }).toList();

    return HorizontalCarousel(
      height: 40,
      spacing: 8,
      children: genreChips,
    );
  }

  Widget _buildTagCarousel(BuildContext context) {
    final tagChips = item.tags!.map((tag) {
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
    }).toList();

    return HorizontalCarousel(
      height: 40,
      spacing: 8,
      children: tagChips,
    );
  }

  Widget _buildStudioCarousel(dynamic jellyfinService) {
    return Builder(
      builder: (context) {
        final studioWidgets = item.studios!.map((studio) {
          if (studio.id != null) {
            final logoUrl = jellyfinService.getLogoUrl(studio.id!, maxHeight: 60);
            if (logoUrl != null) {
              return CachedNetworkImage(
                imageUrl: logoUrl,
                height: 60,
                fit: BoxFit.contain,
                cacheManager: CustomCacheManager(),
                placeholder: (context, url) => const SizedBox(height: 60, width: 120),
                errorWidget: (context, url, error) => _buildStudioName(context, studio.name),
              );
            }
          }
          return _buildStudioName(context, studio.name);
        }).toList();

        return HorizontalCarousel(
          height: 60,
          spacing: 24,
          children: studioWidgets,
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
