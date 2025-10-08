import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:jellyfish/models/search_filters.dart';
import 'package:jellyfish/providers/search_provider.dart';
import 'package:jellyfish/screens/search/widgets/search_filters_panel.dart';
import 'package:jellyfish/theme/app_colors.dart';
import 'package:jellyfish/widgets/card_constants.dart';
import '../home/widgets/poster_card.dart';

/// Page de recherche globale avec filtres avancés
class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    // Initialiser le contrôleur avec le terme de recherche actuel
    final currentFilters = ref.read(searchFiltersProvider);
    _searchController.text = currentFilters.searchTerm ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Annuler le timer précédent
    _debounceTimer?.cancel();

    // Créer un nouveau timer pour la recherche en temps réel
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final currentFilters = ref.read(searchFiltersProvider);
      ref.read(searchFiltersProvider.notifier).state = currentFilters.copyWith(
        searchTerm: value.isEmpty ? null : value,
      );
    });
  }

  void _clearSearch() {
    _searchController.clear();
    final currentFilters = ref.read(searchFiltersProvider);
    ref.read(searchFiltersProvider.notifier).state = currentFilters.copyWith(
      searchTerm: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final filters = ref.watch(searchFiltersProvider);
    final searchResults = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: AppColors.background1,
      body: Row(
        children: [
          // Contenu principal
          Expanded(
            child: CustomScrollView(
              slivers: [
                // AppBar
                SliverAppBar(
                  floating: true,
                  snap: true,
                  backgroundColor: AppColors.background2,
                  foregroundColor: AppColors.text6,
                  elevation: 0,
                  title: Row(
                    children: [
                      Icon(
                        IconsaxPlusBold.search_normal,
                        color: AppColors.jellyfinPurple,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Recherche',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.text6,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    // Bouton filtres (mobile/tablet)
                    if (!isDesktop)
                      Stack(
                        children: [
                          IconButton(
                            icon: Icon(
                              _showFilters ? IconsaxPlusBold.filter : IconsaxPlusLinear.filter,
                            ),
                            color: _showFilters ? AppColors.jellyfinPurple : AppColors.text4,
                            tooltip: 'Filtres',
                            onPressed: () {
                              setState(() {
                                _showFilters = !_showFilters;
                              });
                            },
                          ),
                          if (filters.activeFiltersCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.jellyfinPurple,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '${filters.activeFiltersCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),

                // Barre de recherche
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.background2,
                    padding: EdgeInsets.fromLTRB(
                      isDesktop ? 32 : 16,
                      0,
                      isDesktop ? 32 : 16,
                      16,
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(color: AppColors.text6),
                      decoration: InputDecoration(
                        hintText: 'Rechercher des films, séries, épisodes...',
                        hintStyle: const TextStyle(color: AppColors.text3),
                        prefixIcon: const Icon(
                          IconsaxPlusLinear.search_normal,
                          color: AppColors.jellyfinPurple,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: AppColors.text4,
                                ),
                                onPressed: _clearSearch,
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.surface1,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.jellyfinPurple,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ),

                // Filtres actifs (chips)
                if (filters.hasActiveFilters)
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 32 : 16,
                        vertical: 8,
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _buildActiveFilterChips(filters),
                      ),
                    ),
                  ),

                // Résultats
                _buildResults(searchResults, isDesktop, isTablet),
              ],
            ),
          ),

          // Panel de filtres (desktop uniquement)
          if (isDesktop)
            SizedBox(
              width: 320,
              child: SearchFiltersPanel(isDesktop: isDesktop),
            ),
        ],
      ),

      // Bottom sheet pour les filtres (mobile/tablet)
      bottomSheet: !isDesktop && _showFilters
          ? DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background2,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      // Handle
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.text2,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Filtres
                      Expanded(
                        child: SearchFiltersPanel(isDesktop: false),
                      ),
                    ],
                  ),
                );
              },
            )
          : null,
    );
  }

  List<Widget> _buildActiveFilterChips(SearchFilters filters) {
    final chips = <Widget>[];

    if (filters.itemTypes?.isNotEmpty ?? false) {
      chips.add(_buildFilterChip(
        '${filters.itemTypes!.length} type(s)',
        () {
          ref.read(searchFiltersProvider.notifier).state = filters.copyWith(itemTypes: null);
        },
      ));
    }

    if (filters.genres?.isNotEmpty ?? false) {
      chips.add(_buildFilterChip(
        '${filters.genres!.length} genre(s)',
        () {
          ref.read(searchFiltersProvider.notifier).state = filters.copyWith(genres: null);
        },
      ));
    }

    if (filters.studios?.isNotEmpty ?? false) {
      chips.add(_buildFilterChip(
        '${filters.studios!.length} studio(s)',
        () {
          ref.read(searchFiltersProvider.notifier).state = filters.copyWith(studios: null);
        },
      ));
    }

    if (filters.tags?.isNotEmpty ?? false) {
      chips.add(_buildFilterChip(
        '${filters.tags!.length} tag(s)',
        () {
          ref.read(searchFiltersProvider.notifier).state = filters.copyWith(tags: null);
        },
      ));
    }

    if (filters.years?.isNotEmpty ?? false) {
      chips.add(_buildFilterChip(
        '${filters.years!.length} année(s)',
        () {
          ref.read(searchFiltersProvider.notifier).state = filters.copyWith(years: null);
        },
      ));
    }

    if (filters.minRating != null) {
      chips.add(_buildFilterChip(
        'Note ${filters.minRating!.toStringAsFixed(1)}+',
        () {
          ref.read(searchFiltersProvider.notifier).state = filters.copyWith(minRating: null);
        },
      ));
    }

    return chips;
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: AppColors.jellyfinPurple.withValues(alpha: 0.2),
      labelStyle: const TextStyle(
        color: AppColors.jellyfinPurple,
        fontSize: 13,
      ),
      deleteIconColor: AppColors.jellyfinPurple,
    );
  }

  Widget _buildResults(AsyncValue searchResults, bool isDesktop, bool isTablet) {
    return searchResults.when(
      data: (results) {
        if (results.items?.isEmpty ?? true) {
          return SliverFillRemaining(
            child: _buildEmptyState(isDesktop),
          );
        }

        return _buildGrid(results.items!, isDesktop, isTablet);
      },
      loading: () => const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.jellyfinPurple,
          ),
        ),
      ),
      error: (error, stack) => SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                IconsaxPlusBold.danger,
                size: 64,
                color: AppColors.text2,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur lors de la recherche',
                style: TextStyle(
                  fontSize: isDesktop ? 18 : 16,
                  color: AppColors.text4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(
                  fontSize: isDesktop ? 14 : 13,
                  color: AppColors.text3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDesktop) {
    final filters = ref.watch(searchFiltersProvider);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            filters.hasActiveFilters
                ? IconsaxPlusBold.search_normal
                : IconsaxPlusLinear.search_normal,
            size: 80,
            color: AppColors.text2,
          ),
          const SizedBox(height: 24),
          Text(
            filters.hasActiveFilters
                ? 'Aucun résultat trouvé'
                : 'Commencez votre recherche',
            style: TextStyle(
              fontSize: isDesktop ? 20 : 18,
              color: AppColors.text4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            filters.hasActiveFilters
                ? 'Essayez de modifier vos filtres'
                : 'Utilisez la barre de recherche ou les filtres',
            style: TextStyle(
              fontSize: isDesktop ? 15 : 14,
              color: AppColors.text3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List items, bool isDesktop, bool isTablet) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sizes = CardSizeHelper.getSizes(isDesktop, isTablet);
    final itemWidth = sizes.posterWidth;
    final itemHeight = sizes.posterTotalHeight;

    int crossAxisCount;
    if (isDesktop) {
      // Soustraire la largeur du panel de filtres
      final availableWidth = screenWidth - 320;
      crossAxisCount = (availableWidth / 200).floor().clamp(3, 8);
    } else if (isTablet) {
      crossAxisCount = (screenWidth / 160).floor().clamp(3, 6);
    } else {
      crossAxisCount = (screenWidth / 140).floor().clamp(2, 4);
    }

    return SliverPadding(
      padding: EdgeInsets.all(isDesktop ? 32 : 16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: itemWidth / itemHeight,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            return PosterCard(
              item: item,
              isDesktop: isDesktop,
              isTablet: isTablet,
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }
}

