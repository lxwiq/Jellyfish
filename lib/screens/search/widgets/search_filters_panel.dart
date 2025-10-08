import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:jellyfish/jellyfin/jellyfin_open_api.swagger.dart';
import 'package:jellyfish/models/search_filters.dart';
import 'package:jellyfish/providers/search_provider.dart';
import 'package:jellyfish/theme/app_colors.dart';

/// Panel de filtres pour la recherche globale
class SearchFiltersPanel extends ConsumerStatefulWidget {
  final bool isDesktop;

  const SearchFiltersPanel({
    super.key,
    this.isDesktop = false,
  });

  @override
  ConsumerState<SearchFiltersPanel> createState() => _SearchFiltersPanelState();
}

class _SearchFiltersPanelState extends ConsumerState<SearchFiltersPanel> {
  bool _showGenres = false;
  bool _showStudios = false;
  bool _showTags = false;
  bool _showYears = false;

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(searchFiltersProvider);
    final genresAsync = ref.watch(availableGenresProvider);
    final studiosAsync = ref.watch(availableStudiosProvider);
    final tagsAsync = ref.watch(availableTagsProvider);
    final yearsAsync = ref.watch(availableYearsProvider);

    return Container(
      color: AppColors.background2,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(widget.isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec bouton de réinitialisation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtres',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text6,
                  ),
                ),
                if (filters.hasActiveFilters)
                  TextButton.icon(
                    onPressed: () {
                      ref.read(searchFiltersProvider.notifier).state = filters.clear();
                    },
                    icon: const Icon(IconsaxPlusLinear.refresh, size: 18),
                    label: const Text('Réinitialiser'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.jellyfinPurple,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 24),

            // Type de média
            _buildSectionTitle('Type de média'),
            const SizedBox(height: 12),
            _buildMediaTypeChips(filters),

            const SizedBox(height: 24),

            // Note minimale
            _buildSectionTitle('Note minimale'),
            const SizedBox(height: 12),
            _buildRatingSlider(filters),

            const SizedBox(height: 24),

            // Statut
            _buildSectionTitle('Statut'),
            const SizedBox(height: 12),
            _buildStatusFilters(filters),

            const SizedBox(height: 24),

            // Genres
            _buildExpandableSection(
              title: 'Genres',
              isExpanded: _showGenres,
              onToggle: () => setState(() => _showGenres = !_showGenres),
              selectedCount: filters.genres?.length ?? 0,
              child: genresAsync.when(
                data: (genres) => _buildMultiSelectChips(
                  items: genres,
                  selectedItems: filters.genres ?? [],
                  onToggle: (genre) => _toggleGenre(genre, filters),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Erreur de chargement'),
              ),
            ),

            const SizedBox(height: 16),

            // Studios
            _buildExpandableSection(
              title: 'Studios',
              isExpanded: _showStudios,
              onToggle: () => setState(() => _showStudios = !_showStudios),
              selectedCount: filters.studios?.length ?? 0,
              child: studiosAsync.when(
                data: (studios) => _buildMultiSelectChips(
                  items: studios,
                  selectedItems: filters.studios ?? [],
                  onToggle: (studio) => _toggleStudio(studio, filters),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Erreur de chargement'),
              ),
            ),

            const SizedBox(height: 16),

            // Tags
            _buildExpandableSection(
              title: 'Tags',
              isExpanded: _showTags,
              onToggle: () => setState(() => _showTags = !_showTags),
              selectedCount: filters.tags?.length ?? 0,
              child: tagsAsync.when(
                data: (tags) => _buildMultiSelectChips(
                  items: tags,
                  selectedItems: filters.tags ?? [],
                  onToggle: (tag) => _toggleTag(tag, filters),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Erreur de chargement'),
              ),
            ),

            const SizedBox(height: 16),

            // Années
            _buildExpandableSection(
              title: 'Années',
              isExpanded: _showYears,
              onToggle: () => setState(() => _showYears = !_showYears),
              selectedCount: filters.years?.length ?? 0,
              child: yearsAsync.when(
                data: (years) => _buildMultiSelectChips(
                  items: years.map((y) => y.toString()).toList(),
                  selectedItems: filters.years?.map((y) => y.toString()).toList() ?? [],
                  onToggle: (year) => _toggleYear(int.parse(year), filters),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Erreur de chargement'),
              ),
            ),

            const SizedBox(height: 24),

            // Tri
            _buildSectionTitle('Tri'),
            const SizedBox(height: 12),
            _buildSortOptions(filters),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.text5,
      ),
    );
  }

  Widget _buildMediaTypeChips(SearchFilters filters) {
    final types = [
      _MediaTypeOption('Films', BaseItemKind.movie, IconsaxPlusBold.video_square),
      _MediaTypeOption('Séries', BaseItemKind.series, IconsaxPlusBold.monitor),
      _MediaTypeOption('Épisodes', BaseItemKind.episode, IconsaxPlusBold.video_play),
      _MediaTypeOption('Collections', BaseItemKind.boxset, IconsaxPlusBold.folder_2),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final isSelected = filters.itemTypes?.contains(type.kind) ?? false;
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(type.icon, size: 16),
              const SizedBox(width: 6),
              Text(type.label),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) => _toggleMediaType(type.kind, filters),
          backgroundColor: AppColors.surface1,
          selectedColor: AppColors.jellyfinPurple.withValues(alpha: 0.3),
          checkmarkColor: AppColors.jellyfinPurple,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.jellyfinPurple : AppColors.text5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          side: BorderSide(
            color: isSelected ? AppColors.jellyfinPurple : AppColors.surface2,
            width: isSelected ? 1.5 : 1,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatingSlider(SearchFilters filters) {
    final rating = filters.minRating ?? 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              IconsaxPlusBold.star_1,
              color: AppColors.jellyfinPurple,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              rating > 0 ? '${rating.toStringAsFixed(1)}+' : 'Toutes',
              style: TextStyle(
                color: AppColors.text6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Slider(
          value: rating,
          min: 0,
          max: 10,
          divisions: 20,
          activeColor: AppColors.jellyfinPurple,
          inactiveColor: AppColors.surface2,
          onChanged: (value) {
            ref.read(searchFiltersProvider.notifier).state = filters.copyWith(
              minRating: value > 0 ? value : null,
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusFilters(SearchFilters filters) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text('Favoris'),
          selected: filters.isFavorite == true,
          onSelected: (selected) {
            ref.read(searchFiltersProvider.notifier).state = filters.copyWith(
              isFavorite: selected ? true : null,
            );
          },
          avatar: Icon(
            IconsaxPlusBold.heart,
            size: 16,
            color: filters.isFavorite == true ? AppColors.jellyfinPurple : AppColors.text4,
          ),
          backgroundColor: AppColors.surface1,
          selectedColor: AppColors.jellyfinPurple.withValues(alpha: 0.3),
          labelStyle: TextStyle(
            color: filters.isFavorite == true ? AppColors.jellyfinPurple : AppColors.text5,
          ),
        ),
        FilterChip(
          label: const Text('Non vus'),
          selected: filters.isUnplayed == true,
          onSelected: (selected) {
            ref.read(searchFiltersProvider.notifier).state = filters.copyWith(
              isUnplayed: selected ? true : null,
            );
          },
          avatar: Icon(
            IconsaxPlusBold.eye_slash,
            size: 16,
            color: filters.isUnplayed == true ? AppColors.jellyfinPurple : AppColors.text4,
          ),
          backgroundColor: AppColors.surface1,
          selectedColor: AppColors.jellyfinPurple.withValues(alpha: 0.3),
          labelStyle: TextStyle(
            color: filters.isUnplayed == true ? AppColors.jellyfinPurple : AppColors.text5,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required int selectedCount,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  isExpanded ? IconsaxPlusBold.arrow_down_1 : IconsaxPlusBold.arrow_right_3,
                  size: 20,
                  color: AppColors.text5,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.text5,
                  ),
                ),
                if (selectedCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.jellyfinPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$selectedCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 12),
          child,
        ],
      ],
    );
  }

  Widget _buildMultiSelectChips({
    required List<String> items,
    required List<String> selectedItems,
    required Function(String) onToggle,
  }) {
    if (items.isEmpty) {
      return const Text(
        'Aucun élément disponible',
        style: TextStyle(color: AppColors.text3),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selectedItems.contains(item);
        return FilterChip(
          label: Text(item),
          selected: isSelected,
          onSelected: (_) => onToggle(item),
          backgroundColor: AppColors.surface1,
          selectedColor: AppColors.jellyfinPurple.withValues(alpha: 0.3),
          checkmarkColor: AppColors.jellyfinPurple,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.jellyfinPurple : AppColors.text5,
            fontSize: 13,
          ),
          side: BorderSide(
            color: isSelected ? AppColors.jellyfinPurple : AppColors.surface2,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSortOptions(SearchFilters filters) {
    return DropdownButtonFormField<SortOption>(
      initialValue: SortOption.options.firstWhere(
        (opt) => opt.sortBy == filters.sortBy && opt.sortOrder == filters.sortOrder,
        orElse: () => SortOption.options.first,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dropdownColor: AppColors.surface1,
      style: const TextStyle(color: AppColors.text6),
      items: SortOption.options.map((option) {
        return DropdownMenuItem(
          value: option,
          child: Text(option.label),
        );
      }).toList(),
      onChanged: (option) {
        if (option != null) {
          ref.read(searchFiltersProvider.notifier).state = filters.copyWith(
            sortBy: option.sortBy,
            sortOrder: option.sortOrder,
          );
        }
      },
    );
  }

  void _toggleMediaType(BaseItemKind kind, SearchFilters filters) {
    final currentTypes = List<BaseItemKind>.from(filters.itemTypes ?? []);
    if (currentTypes.contains(kind)) {
      currentTypes.remove(kind);
    } else {
      currentTypes.add(kind);
    }
    ref.read(searchFiltersProvider.notifier).state = filters.copyWith(
      itemTypes: currentTypes.isEmpty ? null : currentTypes,
    );
  }

  void _toggleGenre(String genre, SearchFilters filters) {
    final currentGenres = List<String>.from(filters.genres ?? []);
    if (currentGenres.contains(genre)) {
      currentGenres.remove(genre);
    } else {
      currentGenres.add(genre);
    }
    ref.read(searchFiltersProvider.notifier).state = filters.copyWith(
      genres: currentGenres.isEmpty ? null : currentGenres,
    );
  }

  void _toggleStudio(String studio, SearchFilters filters) {
    final currentStudios = List<String>.from(filters.studios ?? []);
    if (currentStudios.contains(studio)) {
      currentStudios.remove(studio);
    } else {
      currentStudios.add(studio);
    }
    ref.read(searchFiltersProvider.notifier).state = filters.copyWith(
      studios: currentStudios.isEmpty ? null : currentStudios,
    );
  }

  void _toggleTag(String tag, SearchFilters filters) {
    final currentTags = List<String>.from(filters.tags ?? []);
    if (currentTags.contains(tag)) {
      currentTags.remove(tag);
    } else {
      currentTags.add(tag);
    }
    ref.read(searchFiltersProvider.notifier).state = filters.copyWith(
      tags: currentTags.isEmpty ? null : currentTags,
    );
  }

  void _toggleYear(int year, SearchFilters filters) {
    final currentYears = List<int>.from(filters.years ?? []);
    if (currentYears.contains(year)) {
      currentYears.remove(year);
    } else {
      currentYears.add(year);
    }
    ref.read(searchFiltersProvider.notifier).state = filters.copyWith(
      years: currentYears.isEmpty ? null : currentYears,
    );
  }
}

class _MediaTypeOption {
  final String label;
  final BaseItemKind kind;
  final IconData icon;

  _MediaTypeOption(this.label, this.kind, this.icon);
}

