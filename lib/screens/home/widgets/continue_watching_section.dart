import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/home_provider.dart';
import 'media_card.dart';

/// Section "Reprise de lecture"
class ContinueWatchingSection extends ConsumerWidget {
  final bool isDesktop;
  final bool isTablet;

  const ContinueWatchingSection({
    super.key,
    required this.isDesktop,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumeItemsAsync = ref.watch(resumeItemsProvider);

    return resumeItemsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return _buildEmptySection(context, 'Aucun élément en cours de lecture');
        }

        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return MediaCard(
                item: item,
                isDesktop: isDesktop,
              );
            },
          ),
        );
      },
      loading: () => _buildLoadingSection(),
      error: (error, stack) => _buildErrorSection('Erreur de chargement'),
    );
  }

  Widget _buildEmptySection(BuildContext context, String message) {
    return Container(
      height: 200,
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
      height: 200,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorSection(String message) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Text(
        message,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }
}

