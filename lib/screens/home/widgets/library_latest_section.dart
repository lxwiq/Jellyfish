import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/home_provider.dart';
import '../../../jellyfin/jellyfin_open_api.swagger.dart';
import '../../library/library_screen.dart';
import 'poster_card.dart';

/// Section affichant les derniers éléments ajoutés par bibliothèque
class LibraryLatestSection extends ConsumerWidget {
  final bool isDesktop;
  final bool isTablet;

  const LibraryLatestSection({
    super.key,
    required this.isDesktop,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final librariesAsync = ref.watch(userLibrariesProvider);

    return librariesAsync.when(
      data: (libraries) {
        if (libraries.isEmpty) {
          return _buildEmptySection(context, 'Aucune bibliothèque disponible');
        }

        return Column(
          children: [
            for (final library in libraries) ...[
              _LibraryCarousel(
                library: library,
                isDesktop: isDesktop,
                isTablet: isTablet,
              ),
              const SizedBox(height: 32),
            ],
          ],
        );
      },
      loading: () => _buildLoadingSection(),
      error: (error, stack) => _buildErrorSection('Erreur de chargement des bibliothèques'),
    );
  }

  Widget _buildEmptySection(BuildContext context, String message) {
    return Container(
      height: 240,
      alignment: Alignment.center,
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildLoadingSection() {
    return const SizedBox(
      height: 240,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorSection(String message) {
    return Container(
      height: 240,
      alignment: Alignment.center,
      child: Text(
        message,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }
}

/// Widget pour afficher un carousel d'une bibliothèque
class _LibraryCarousel extends ConsumerWidget {
  final BaseItemDto library;
  final bool isDesktop;
  final bool isTablet;

  const _LibraryCarousel({
    required this.library,
    required this.isDesktop,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryId = library.id;
    if (libraryId == null) return const SizedBox.shrink();

    final latestItemsAsync = ref.watch(latestItemsByLibraryProvider(libraryId));

    return latestItemsAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre de la bibliothèque
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    _getLibraryIcon(library.collectionType),
                    size: 24,
                    color: AppColors.jellyfinPurple,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    library.name ?? 'Sans nom',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.text1,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => LibraryScreen(library: library),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Voir tout',
                          style: TextStyle(
                            color: AppColors.jellyfinPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          IconsaxPlusLinear.arrow_right_3,
                          size: 16,
                          color: AppColors.jellyfinPurple,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Carousel horizontal
            SizedBox(
              height: isDesktop ? 280 : (isTablet ? 240 : 220),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: PosterCard(
                      item: item,
                      width: isDesktop ? 180 : (isTablet ? 150 : 130),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
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
}

