import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../theme/app_colors.dart';
import '../../providers/item_detail_provider.dart';
import '../../jellyfin/jellyfin_open_api.swagger.dart';
import 'widgets/person_detail_header.dart';
import 'widgets/person_detail_info.dart';
import 'widgets/person_filmography.dart';

/// Écran de détails d'une personne (acteur, réalisateur, etc.)
class PersonDetailScreen extends ConsumerWidget {
  final String personId;
  final String? personName;

  const PersonDetailScreen({
    super.key,
    required this.personId,
    this.personName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personDetailAsync = ref.watch(personDetailProvider(personId));
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: AppColors.background1,
      body: personDetailAsync.when(
        data: (person) {
          if (person == null) {
            return _buildError(context, 'Personne introuvable');
          }
          return _buildContent(context, ref, person, isDesktop);
        },
        loading: () => _buildLoading(),
        error: (error, stack) => _buildError(context, error.toString()),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, BaseItemDto person, bool isDesktop) {
    return CustomScrollView(
      slivers: [
        // Header avec image et nom
        PersonDetailHeader(person: person, isDesktop: isDesktop),

        // Informations principales
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 32 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations biographiques
                PersonDetailInfo(person: person),

                const SizedBox(height: 32),

                // Filmographie
                PersonFilmography(
                  personId: person.id!,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            IconsaxPlusLinear.danger,
            size: 64,
            color: AppColors.text3,
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.text1,
              fontWeight: FontWeight.bold,
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
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(IconsaxPlusLinear.arrow_left),
            label: const Text('Retour'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.jellyfinPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

