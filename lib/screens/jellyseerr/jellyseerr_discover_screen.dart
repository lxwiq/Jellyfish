import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jellyfish/providers/jellyseerr_provider.dart';
import 'package:jellyfish/models/jellyseerr_models.dart';
import 'package:jellyfish/widgets/card_constants.dart';
import 'jellyseerr_media_detail_screen.dart';

/// Écran de découverte de contenu Jellyseerr
class JellyseerrDiscoverScreen extends ConsumerStatefulWidget {
  const JellyseerrDiscoverScreen({super.key});

  @override
  ConsumerState<JellyseerrDiscoverScreen> createState() =>
      _JellyseerrDiscoverScreenState();
}

class _JellyseerrDiscoverScreenState
    extends ConsumerState<JellyseerrDiscoverScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(jellyseerrAuthStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Découvrir'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(jellyseerrAuthStateProvider.notifier).logout();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tendances', icon: Icon(Icons.trending_up)),
            Tab(text: 'Films', icon: Icon(Icons.movie)),
            Tab(text: 'Séries', icon: Icon(Icons.tv)),
          ],
        ),
      ),
      body: _searchQuery != null
          ? _buildSearchResults()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTrendingTab(),
                _buildMoviesTab(),
                _buildTvTab(),
              ],
            ),
    );
  }

  Widget _buildTrendingTab() {
    final trendingAsync = ref.watch(jellyseerrTrendingProvider(1));

    return trendingAsync.when(
      data: (response) => _buildMediaGrid(response.results),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(jellyseerrTrendingProvider),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoviesTab() {
    final moviesAsync = ref.watch(jellyseerrPopularMoviesProvider(1));

    return moviesAsync.when(
      data: (response) => _buildMediaGrid(response.results),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(jellyseerrPopularMoviesProvider),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTvTab() {
    final tvAsync = ref.watch(jellyseerrPopularTvProvider(1));

    return tvAsync.when(
      data: (response) => _buildMediaGrid(response.results),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(jellyseerrPopularTvProvider),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGrid(List<MediaSearchResult> media) {
    if (media.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun contenu disponible',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(jellyseerrTrendingProvider);
        ref.invalidate(jellyseerrPopularMoviesProvider);
        ref.invalidate(jellyseerrPopularTvProvider);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isDesktop = screenWidth >= 900;
          final isTablet = screenWidth >= 600 && screenWidth < 900;

          // Calculer le nombre de colonnes en fonction de la largeur
          int crossAxisCount;
          double horizontalPadding;

          if (isDesktop) {
            crossAxisCount = (screenWidth / 200).floor().clamp(3, 8);
            horizontalPadding = 32;
          } else if (isTablet) {
            crossAxisCount = (screenWidth / 160).floor().clamp(3, 6);
            horizontalPadding = 16;
          } else {
            crossAxisCount = (screenWidth / 140).floor().clamp(2, 4);
            horizontalPadding = 16;
          }

          // Calculer le ratio d'aspect : poster (2/3) + zone de texte (~50px)
          // Pour éviter les overflows, on utilise un ratio qui laisse de l'espace pour le texte
          const double textAreaHeight = 50.0;
          final double posterHeight = 1.0 / CardConstants.posterAspectRatio; // 1.5 pour ratio 2/3
          final double totalHeightRatio = posterHeight + (textAreaHeight / 100); // Normaliser
          final double childAspectRatio = 1.0 / totalHeightRatio;

          return GridView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 16,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: media.length,
            itemBuilder: (context, index) {
              final item = media[index];
              return _buildMediaCard(item, 0);
            },
          );
        },
      ),
    );
  }

  Widget _buildMediaCard(MediaSearchResult media, double cardWidth) {
    final posterUrl = media.posterPath != null
        ? 'https://image.tmdb.org/t/p/w500${media.posterPath}'
        : null;

    return GestureDetector(
      onTap: () => _showMediaDetails(media),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image avec ratio d'aspect fixe
          AspectRatio(
            aspectRatio: CardConstants.posterAspectRatio,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: posterUrl != null
                    ? Image.network(
                        posterUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Icon(Icons.movie, size: 48),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Icon(Icons.movie, size: 48),
                        ),
                      ),
              ),
            ),
          ),
          // Zone de texte flexible
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  media.displayTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
                if (media.voteAverage != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        media.voteAverage!.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchQuery == null || _searchQuery!.isEmpty) {
      return const Center(child: Text('Entrez un terme de recherche'));
    }

    final searchAsync = ref.watch(jellyseerrSearchProvider(_searchQuery!));

    return searchAsync.when(
      data: (response) {
        if (response.results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Aucun résultat trouvé'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = null;
                    });
                  },
                  child: const Text('Retour'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Résultats pour "$_searchQuery"',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _searchQuery = null;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(child: _buildMediaGrid(response.results)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = null;
                });
              },
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechercher'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Titre du film ou de la série',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Navigator.pop(context);
              setState(() {
                _searchQuery = value;
              });
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                setState(() {
                  _searchQuery = controller.text;
                });
              }
            },
            child: const Text('Rechercher'),
          ),
        ],
      ),
    );
  }

  void _showMediaDetails(MediaSearchResult media) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JellyseerrMediaDetailScreen(
          mediaId: media.id,
          mediaType: media.mediaType,
        ),
      ),
    );
  }
}
