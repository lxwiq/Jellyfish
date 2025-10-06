import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../theme/app_colors.dart';
import '../../providers/item_detail_provider.dart';
import '../../jellyfin/jellyfin_open_api.swagger.dart';
import 'widgets/item_detail_header.dart';
import 'widgets/item_detail_info.dart';
import 'widgets/item_detail_cast.dart';
import 'widgets/item_detail_similar.dart';

/// Écran de détails d'un item (film, série, épisode, etc.)
class ItemDetailScreen extends ConsumerWidget {
  final String itemId;
  final BaseItemDto? initialItem; // Item initial pour affichage immédiat

  const ItemDetailScreen({
    super.key,
    required this.itemId,
    this.initialItem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemDetailAsync = ref.watch(itemDetailProvider(itemId));
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: AppColors.background1,
      body: itemDetailAsync.when(
        data: (item) {
          if (item == null) {
            return _buildError(context, 'Item introuvable');
          }
          return _buildContent(context, ref, item, isDesktop);
        },
        loading: () {
          // Si on a un item initial, l'afficher pendant le chargement
          if (initialItem != null) {
            return _buildContent(context, ref, initialItem!, isDesktop);
          }
          return _buildLoading();
        },
        error: (error, stack) => _buildError(context, error.toString()),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, BaseItemDto item, bool isDesktop) {
    return CustomScrollView(
      slivers: [
        // Header avec image backdrop et boutons d'action
        ItemDetailHeader(item: item, isDesktop: isDesktop),

        // Informations principales
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 32 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ItemDetailInfo(item: item),
                
                const SizedBox(height: 32),

                // Cast et équipe
                if (item.people != null && item.people!.isNotEmpty) ...[
                  ItemDetailCast(people: item.people!),
                  const SizedBox(height: 32),
                ],

                // Items similaires
                ItemDetailSimilar(
                  itemId: item.id!,
                  isDesktop: isDesktop,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.jellyfinPurple,
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              IconsaxPlusLinear.danger,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.text3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}

