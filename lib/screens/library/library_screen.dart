import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../theme/app_colors.dart';
import '../../providers/library_provider.dart';
import '../../jellyfin/jellyfin_open_api.swagger.dart';
import 'widgets/library_grid.dart';
import 'widgets/library_filters.dart';

/// Écran d'une bibliothèque spécifique
class LibraryScreen extends ConsumerStatefulWidget {
  final BaseItemDto library;

  const LibraryScreen({
    super.key,
    required this.library,
  });

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500) {
      final libraryId = widget.library.id;
      if (libraryId != null) {
        ref.read(libraryProvider(libraryId).notifier).loadNextPage();
      }
    }
  }

  IconData _getLibraryIcon(dynamic collectionType) {
    final typeStr = collectionType?.toString().toLowerCase() ?? '';
    switch (typeStr) {
      case 'movies':
        return IconsaxPlusBold.video;
      case 'tvshows':
        return IconsaxPlusBold.monitor;
      case 'music':
        return IconsaxPlusBold.music;
      case 'books':
        return IconsaxPlusBold.book;
      case 'photos':
        return IconsaxPlusBold.gallery;
      default:
        return IconsaxPlusBold.folder_2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final libraryId = widget.library.id;
    
    if (libraryId == null) {
      return Scaffold(
        backgroundColor: AppColors.background1,
        appBar: AppBar(
          backgroundColor: AppColors.background2,
          title: const Text('Erreur'),
        ),
        body: const Center(
          child: Text('ID de bibliothèque invalide'),
        ),
      );
    }

    final libraryState = ref.watch(libraryProvider(libraryId));
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: AppColors.background1,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // AppBar
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.background2,
            foregroundColor: AppColors.text6,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(IconsaxPlusLinear.arrow_left),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                Icon(
                  _getLibraryIcon(widget.library.collectionType),
                  color: AppColors.jellyfinPurple,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.library.name ?? 'Bibliothèque',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.text6,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              // Bouton de recherche
              IconButton(
                icon: const Icon(IconsaxPlusLinear.search_normal),
                onPressed: () {
                  // TODO: Implémenter la recherche
                },
              ),
              // Bouton de filtres
              IconButton(
                icon: Icon(
                  _showFilters ? IconsaxPlusBold.filter : IconsaxPlusLinear.filter,
                  color: _showFilters ? AppColors.jellyfinPurple : AppColors.text4,
                ),
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
              ),
            ],
          ),

          // Filtres (si affichés)
          if (_showFilters)
            SliverToBoxAdapter(
              child: LibraryFilters(
                libraryId: libraryId,
                collectionType: widget.library.collectionType,
              ),
            ),

          // Informations de la bibliothèque
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 32 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre d'items
                  Text(
                    '${libraryState.totalCount} élément${libraryState.totalCount > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.text3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Grille d'items
          if (libraryState.error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        IconsaxPlusLinear.danger,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur de chargement',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        libraryState.error!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.text3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(libraryProvider(libraryId).notifier).refresh();
                        },
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (libraryState.items.isEmpty && libraryState.isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(64),
                child: Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.jellyfinPurple,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chargement...',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.text3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (libraryState.items.isEmpty && !libraryState.isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        IconsaxPlusLinear.folder_open,
                        size: 64,
                        color: AppColors.text2,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun élément',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.text3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            LibraryGrid(
              items: libraryState.items,
              isDesktop: isDesktop,
            ),

          // Indicateur de chargement en bas
          if (libraryState.isLoading && libraryState.items.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.jellyfinPurple,
                  ),
                ),
              ),
            ),

          // Espace en bas
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }
}

