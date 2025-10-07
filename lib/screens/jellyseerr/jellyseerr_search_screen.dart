import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:jellyfish/theme/app_colors.dart';
import 'package:jellyfish/providers/jellyseerr_provider.dart';
import 'package:jellyfish/models/jellyseerr_models.dart';
import 'widgets/jellyseerr_media_card.dart';

/// Écran de recherche dédié pour Jellyseerr
/// Design cohérent avec le reste de l'application
class JellyseerrSearchScreen extends ConsumerStatefulWidget {
  const JellyseerrSearchScreen({super.key});

  @override
  ConsumerState<JellyseerrSearchScreen> createState() =>
      _JellyseerrSearchScreenState();
}

class _JellyseerrSearchScreenState
    extends ConsumerState<JellyseerrSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _searchQuery = query.trim();
      _isSearching = true;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Scaffold(
      backgroundColor: AppColors.background1,
      appBar: AppBar(
        backgroundColor: AppColors.background2,
        foregroundColor: AppColors.text6,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/icons/jellyseerr.png',
              width: 28,
              height: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Rechercher',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.text6,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            color: AppColors.background2,
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: AppColors.text6),
              decoration: InputDecoration(
                hintText: 'Rechercher des films, séries...',
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
              onSubmitted: _performSearch,
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // Résultats de recherche
          Expanded(
            child: _isSearching && _searchQuery.isNotEmpty
                ? _buildSearchResults(isDesktop, isTablet)
                : _buildEmptyState(isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(bool isDesktop, bool isTablet) {
    final searchAsync = ref.watch(jellyseerrSearchProvider(_searchQuery));

    return searchAsync.when(
      data: (response) {
        if (response.results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  IconsaxPlusBold.search_normal,
                  size: 64,
                  color: AppColors.text2,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun résultat pour "$_searchQuery"',
                  style: TextStyle(
                    fontSize: isDesktop ? 18 : 16,
                    color: AppColors.text4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Essayez avec d\'autres mots-clés',
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 13,
                    color: AppColors.text3,
                  ),
                ),
              ],
            ),
          );
        }

        return _buildMediaGrid(response.results, isDesktop, isTablet);
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.jellyfinPurple,
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
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
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isDesktop ? 14 : 13,
                color: AppColors.text3,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _performSearch(_searchQuery),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.jellyfinPurple,
                foregroundColor: AppColors.text6,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGrid(
    List<MediaSearchResult> media,
    bool isDesktop,
    bool isTablet,
  ) {
    int crossAxisCount;
    if (isDesktop) {
      crossAxisCount = 6;
    } else if (isTablet) {
      crossAxisCount = 4;
    } else {
      crossAxisCount = 3;
    }

    return GridView.builder(
      padding: EdgeInsets.all(isDesktop ? 32 : 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.55,
        crossAxisSpacing: isDesktop ? 24 : 12,
        mainAxisSpacing: isDesktop ? 24 : 12,
      ),
      itemCount: media.length,
      itemBuilder: (context, index) {
        return JellyseerrMediaCard(
          media: media[index],
          isDesktop: isDesktop,
          isTablet: isTablet,
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDesktop) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            IconsaxPlusBold.search_normal,
            size: 80,
            color: AppColors.text2,
          ),
          const SizedBox(height: 24),
          Text(
            'Recherchez vos films et séries préférés',
            style: TextStyle(
              fontSize: isDesktop ? 20 : 18,
              color: AppColors.text5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Utilisez la barre de recherche ci-dessus',
            style: TextStyle(
              fontSize: isDesktop ? 14 : 13,
              color: AppColors.text3,
            ),
          ),
        ],
      ),
    );
  }
}

