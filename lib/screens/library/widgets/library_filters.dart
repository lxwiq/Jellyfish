import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/library_provider.dart';
import '../../../jellyfin/jellyfin_open_api.swagger.dart';

/// Widget de filtres pour la bibliothèque
class LibraryFilters extends ConsumerWidget {
  final String libraryId;
  final dynamic collectionType;

  const LibraryFilters({
    super.key,
    required this.libraryId,
    this.collectionType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider(libraryId));

    return Container(
      color: AppColors.background2,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Row(
            children: [
              const Icon(
                IconsaxPlusBold.filter,
                size: 20,
                color: AppColors.jellyfinPurple,
              ),
              const SizedBox(width: 8),
              Text(
                'Filtres et tri',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tri
          _buildSortSection(context, ref, libraryState),
          
          const SizedBox(height: 16),

          // Filtres par type (si applicable)
          if (_shouldShowTypeFilter(collectionType))
            _buildTypeFilterSection(context, ref, libraryState),
        ],
      ),
    );
  }

  Widget _buildSortSection(BuildContext context, WidgetRef ref, LibraryState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trier par',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.text4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSortChip(
              context,
              ref,
              'Nom',
              ItemSortBy.sortname,
              state.sortBy == ItemSortBy.sortname,
            ),
            _buildSortChip(
              context,
              ref,
              'Date d\'ajout',
              ItemSortBy.datecreated,
              state.sortBy == ItemSortBy.datecreated,
            ),
            _buildSortChip(
              context,
              ref,
              'Date de sortie',
              ItemSortBy.premieredate,
              state.sortBy == ItemSortBy.premieredate,
            ),
            _buildSortChip(
              context,
              ref,
              'Note',
              ItemSortBy.communityrating,
              state.sortBy == ItemSortBy.communityrating,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Ordre de tri
        Row(
          children: [
            _buildOrderChip(
              context,
              ref,
              'Croissant',
              SortOrder.ascending,
              state.sortOrder == SortOrder.ascending,
              IconsaxPlusLinear.arrow_up_3,
            ),
            const SizedBox(width: 8),
            _buildOrderChip(
              context,
              ref,
              'Décroissant',
              SortOrder.descending,
              state.sortOrder == SortOrder.descending,
              IconsaxPlusLinear.arrow_down,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    ItemSortBy sortBy,
    bool isSelected,
  ) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          final currentOrder = ref.read(libraryProvider(libraryId)).sortOrder;
          ref.read(libraryProvider(libraryId).notifier).changeSorting(sortBy, currentOrder);
        }
      },
      selectedColor: AppColors.jellyfinPurple.withValues(alpha: 0.2),
      checkmarkColor: AppColors.jellyfinPurple,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.jellyfinPurple : AppColors.text4,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.jellyfinPurple : AppColors.surface1,
      ),
    );
  }

  Widget _buildOrderChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    SortOrder order,
    bool isSelected,
    IconData icon,
  ) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? AppColors.jellyfinPurple : AppColors.text4,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          final currentSortBy = ref.read(libraryProvider(libraryId)).sortBy;
          ref.read(libraryProvider(libraryId).notifier).changeSorting(currentSortBy, order);
        }
      },
      selectedColor: AppColors.jellyfinPurple.withValues(alpha: 0.2),
      checkmarkColor: AppColors.jellyfinPurple,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.jellyfinPurple : AppColors.text4,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.jellyfinPurple : AppColors.surface1,
      ),
    );
  }

  Widget _buildTypeFilterSection(BuildContext context, WidgetRef ref, LibraryState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de contenu',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.text4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _getTypeFilters(collectionType).map((filter) {
            final isSelected = state.itemTypeFilter?.contains(filter.type) ?? false;
            return FilterChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (selected) {
                List<BaseItemKind>? newFilter;
                if (selected) {
                  newFilter = [...?state.itemTypeFilter, filter.type];
                } else {
                  newFilter = state.itemTypeFilter?.where((t) => t != filter.type).toList();
                  if (newFilter?.isEmpty ?? true) newFilter = null;
                }
                ref.read(libraryProvider(libraryId).notifier).changeItemTypeFilter(newFilter);
              },
              selectedColor: AppColors.jellyfinPurple.withValues(alpha: 0.2),
              checkmarkColor: AppColors.jellyfinPurple,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.jellyfinPurple : AppColors.text4,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.jellyfinPurple : AppColors.surface1,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  bool _shouldShowTypeFilter(dynamic collectionType) {
    final typeStr = collectionType?.toString().toLowerCase() ?? '';
    return typeStr == 'movies' || typeStr == 'tvshows';
  }

  List<_TypeFilter> _getTypeFilters(dynamic collectionType) {
    final typeStr = collectionType?.toString().toLowerCase() ?? '';
    
    if (typeStr == 'movies') {
      return [
        _TypeFilter('Films', BaseItemKind.movie),
        _TypeFilter('Collections', BaseItemKind.boxset),
      ];
    } else if (typeStr == 'tvshows') {
      return [
        _TypeFilter('Séries', BaseItemKind.series),
        _TypeFilter('Épisodes', BaseItemKind.episode),
      ];
    }
    
    return [];
  }
}

class _TypeFilter {
  final String label;
  final BaseItemKind type;

  _TypeFilter(this.label, this.type);
}

