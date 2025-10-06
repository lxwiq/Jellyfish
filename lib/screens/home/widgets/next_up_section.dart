import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/home_provider.dart';
import '../../../widgets/card_constants.dart';
import 'episode_card.dart';

/// Section "Prochains épisodes"
class NextUpSection extends ConsumerWidget {
  final bool isDesktop;
  final bool isTablet;

  const NextUpSection({
    super.key,
    required this.isDesktop,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextUpAsync = ref.watch(nextUpEpisodesProvider);

    // Calculer la hauteur basée sur les constantes
    final sizes = CardSizeHelper.getSizes(isDesktop, isTablet);
    final sectionHeight = sizes.episodeTotalHeight;

    return nextUpAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return _buildEmptySection(context, 'Aucun prochain épisode', sectionHeight);
        }

        return SizedBox(
          height: sectionHeight,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              },
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: EpisodeCard(
                    item: item,
                    isDesktop: isDesktop,
                    isTablet: isTablet,
                  ),
                );
              },
            ),
          ),
        );
      },
      loading: () => _buildLoadingSection(sectionHeight),
      error: (error, stack) => _buildErrorSection('Erreur de chargement', sectionHeight),
    );
  }

  Widget _buildEmptySection(BuildContext context, String message, double height) {
    return Container(
      height: height,
      alignment: Alignment.center,
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildLoadingSection(double height) {
    return SizedBox(
      height: height,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorSection(String message, double height) {
    return Container(
      height: height,
      alignment: Alignment.center,
      child: Text(
        message,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }
}

