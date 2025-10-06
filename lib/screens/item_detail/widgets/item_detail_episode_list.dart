import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../theme/app_colors.dart';
import '../../../jellyfin/jellyfin_open_api.swagger.dart';
import '../../../providers/item_detail_provider.dart';
import 'item_detail_episode_card.dart';
import 'item_detail_episode_hero.dart';
import 'item_detail_season_selector.dart';

/// Widget affichant la liste des épisodes d'une série
class ItemDetailEpisodeList extends ConsumerWidget {
  final String seriesId;
  final bool isDesktop;

  const ItemDetailEpisodeList({
    super.key,
    required this.seriesId,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonsAsync = ref.watch(seasonsProvider(seriesId));
    final nextUpEpisodeAsync = ref.watch(nextUpEpisodeForSeriesProvider(seriesId));

    return seasonsAsync.when(
      data: (seasons) {
        if (seasons.isEmpty) {
          return const SizedBox.shrink();
        }

        // Filtrer les saisons spéciales si nécessaire
        final regularSeasons = seasons.where((s) {
          final indexNumber = s.indexNumber;
          return indexNumber != null && indexNumber > 0;
        }).toList();

        if (regularSeasons.isEmpty) {
          return const SizedBox.shrink();
        }

        // Déterminer la saison à afficher par défaut
        final selectedIndex = ref.watch(selectedSeasonIndexProvider(seriesId));
        
        // Si c'est la première fois, essayer de sélectionner la saison avec le prochain épisode
        if (selectedIndex == 0) {
          nextUpEpisodeAsync.whenData((nextUpEpisode) {
            if (nextUpEpisode != null && nextUpEpisode.seasonId != null) {
              final seasonIndex = regularSeasons.indexWhere(
                (s) => s.id == nextUpEpisode.seasonId,
              );
              if (seasonIndex >= 0 && seasonIndex != selectedIndex) {
                // Mettre à jour l'index sélectionné
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(selectedSeasonIndexProvider(seriesId).notifier).state = seasonIndex;
                });
              }
            }
          });
        }

        final selectedSeason = regularSeasons[selectedIndex];
        final episodesParams = EpisodeParams(
          seriesId: seriesId,
          seasonId: selectedSeason.id,
          seasonNumber: selectedSeason.indexNumber,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre de section
            Row(
              children: [
                Icon(
                  IconsaxPlusLinear.video_play,
                  size: 24,
                  color: AppColors.jellyfinPurple,
                ),
                const SizedBox(width: 12),
                Text(
                  'Épisodes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text1,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Sélecteur de saison
            ItemDetailSeasonSelector(
              seriesId: seriesId,
              seasons: regularSeasons,
            ),
            
            const SizedBox(height: 24),
            
            // Liste des épisodes
            _buildEpisodesList(context, ref, episodesParams, nextUpEpisodeAsync),
          ],
        );
      },
      loading: () => _buildLoading(),
      error: (error, stack) => _buildError(context, error.toString()),
    );
  }

  Widget _buildEpisodesList(
    BuildContext context,
    WidgetRef ref,
    EpisodeParams params,
    AsyncValue<BaseItemDto?> nextUpEpisodeAsync,
  ) {
    final episodesAsync = ref.watch(episodesProvider(params));

    return episodesAsync.when(
      data: (episodes) {
        if (episodes.isEmpty) {
          return _buildEmptyState(context);
        }

        // Déterminer quel épisode mettre en avant (hero)
        BaseItemDto? heroEpisode;
        bool isNextUp = false;

        nextUpEpisodeAsync.whenData((nextUpEpisode) {
          if (nextUpEpisode != null && nextUpEpisode.seasonId == params.seasonId) {
            heroEpisode = nextUpEpisode;
            isNextUp = true;
          }
        });

        // Si pas de prochain épisode, afficher le premier épisode
        if (heroEpisode == null) {
          heroEpisode = episodes.first;
          isNextUp = false;
        }

        // Trier les épisodes par numéro
        final sortedEpisodes = List<BaseItemDto>.from(episodes);
        sortedEpisodes.sort((a, b) {
          final aIndex = a.indexNumber ?? 0;
          final bIndex = b.indexNumber ?? 0;
          return aIndex.compareTo(bIndex);
        });

        // Calculer la hauteur maximale en fonction du nombre d'épisodes
        // Hauteur d'une carte d'épisode : ~110px (desktop) ou ~85px (mobile)
        final episodeCardHeight = isDesktop ? 110.0 : 85.0;
        final maxVisibleEpisodes = isDesktop ? 5 : 4;
        final maxHeight = episodeCardHeight * maxVisibleEpisodes;

        // Si peu d'épisodes, pas besoin de scroll
        final needsScroll = sortedEpisodes.length > maxVisibleEpisodes;
        final containerHeight = needsScroll
            ? maxHeight
            : sortedEpisodes.length * episodeCardHeight;

        final episodeWidgets = sortedEpisodes.map((episode) {
          final isHighlighted = episode.id == heroEpisode?.id;

          return ItemDetailEpisodeCard(
            episode: episode,
            isDesktop: isDesktop,
            isNextUp: isHighlighted,
          );
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero épisode en haut
            ItemDetailEpisodeHero(
              episode: heroEpisode!,
              isNextUp: isNextUp,
              isDesktop: isDesktop,
            ),

            const SizedBox(height: 24),

            // Titre "Tous les épisodes"
            Text(
              'Tous les épisodes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.text5,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            // Liste des épisodes
            Container(
              constraints: BoxConstraints(
                maxHeight: containerHeight,
              ),
              child: needsScroll
                  ? ListView(
                      shrinkWrap: true,
                      children: episodeWidgets,
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: episodeWidgets,
                    ),
            ),
          ],
        );
      },
      loading: () => _buildLoading(),
      error: (error, stack) => _buildError(context, error.toString()),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(
          color: AppColors.jellyfinPurple,
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              IconsaxPlusLinear.danger,
              size: 48,
              color: AppColors.text3,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.text4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.text3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              IconsaxPlusLinear.video_slash,
              size: 48,
              color: AppColors.text3,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun épisode disponible',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.text4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

