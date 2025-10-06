import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../jellyfin/jellyfin_open_api.swagger.dart';
import '../../../widgets/card_constants.dart';
import '../../home/widgets/poster_card.dart';

/// Grille d'items de la bibliothèque
class LibraryGrid extends ConsumerWidget {
  final List<BaseItemDto> items;
  final bool isDesktop;

  const LibraryGrid({
    super.key,
    required this.items,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    // Utiliser les tailles standardisées
    final sizes = CardSizeHelper.getSizes(isDesktop, isTablet);
    final itemWidth = sizes.posterWidth;
    final itemHeight = sizes.posterTotalHeight;

    // Calculer le nombre de colonnes en fonction de la largeur
    int crossAxisCount;

    if (isDesktop) {
      crossAxisCount = (screenWidth / 200).floor().clamp(3, 8);
    } else if (isTablet) {
      crossAxisCount = (screenWidth / 160).floor().clamp(3, 6);
    } else {
      crossAxisCount = (screenWidth / 140).floor().clamp(2, 4);
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 16,
      ),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: itemWidth / itemHeight, // Ratio basé sur les constantes
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

