import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../theme/app_colors.dart';
import '../../../jellyfin/jellyfin_open_api.swagger.dart';
import '../../../providers/services_provider.dart';

/// Widget affichant le casting d'un item
class ItemDetailCast extends ConsumerWidget {
  final List<BaseItemPerson> people;

  const ItemDetailCast({
    super.key,
    required this.people,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Filtrer pour n'afficher que les acteurs
    final actors = people
        .where((p) => p.type?.value?.toLowerCase() == 'actor')
        .take(20)
        .toList();

    if (actors.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              IconsaxPlusLinear.user,
              size: 24,
              color: AppColors.jellyfinPurple,
            ),
            const SizedBox(width: 12),
            Text(
              'Casting',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.text1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: actors.length,
            itemBuilder: (context, index) {
              final person = actors[index];
              return _CastCard(person: person);
            },
          ),
        ),
      ],
    );
  }
}

class _CastCard extends ConsumerWidget {
  final BaseItemPerson person;

  const _CastCard({required this.person});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jellyfinService = ref.watch(jellyfinServiceProvider);
    final imageUrl = person.id != null && person.primaryImageTag != null
        ? jellyfinService.getImageUrl(
            person.id!,
            tag: person.primaryImageTag,
            maxWidth: 200,
          )
        : null;

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        memCacheWidth: 200,
                        placeholder: (context, url) => Container(
                          color: AppColors.surface1,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.jellyfinPurple,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.surface1,
                          child: const Center(
                            child: Icon(
                              IconsaxPlusLinear.user,
                              size: 40,
                              color: AppColors.text3,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.surface1,
                        child: const Center(
                          child: Icon(
                            IconsaxPlusLinear.user,
                            size: 40,
                            color: AppColors.text3,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Nom
          Text(
            person.name ?? 'Inconnu',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.text5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Rôle
          if (person.role != null && person.role!.isNotEmpty)
            Text(
              person.role!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.text3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

