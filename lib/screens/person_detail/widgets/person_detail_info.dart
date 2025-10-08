import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../theme/app_colors.dart';
import '../../../jellyfin/jellyfin_open_api.swagger.dart';

/// Widget affichant les informations biographiques d'une personne
class PersonDetailInfo extends StatelessWidget {
  final BaseItemDto person;

  const PersonDetailInfo({
    super.key,
    required this.person,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nom complet
        Text(
          person.name ?? 'Inconnu',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.text1,
          ),
        ),

        const SizedBox(height: 8),

        // Informations de base
        if (person.premiereDate != null || person.endDate != null)
          _buildInfoRow(
            context,
            IconsaxPlusLinear.calendar,
            _buildDateInfo(),
          ),

        if (person.productionLocations != null && person.productionLocations!.isNotEmpty)
          _buildInfoRow(
            context,
            IconsaxPlusLinear.location,
            person.productionLocations!.join(', '),
          ),

        // Biographie
        if (person.overview != null && person.overview!.isNotEmpty) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(
                IconsaxPlusLinear.document_text,
                size: 24,
                color: AppColors.jellyfinPurple,
              ),
              const SizedBox(width: 12),
              Text(
                'Biographie',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            person.overview!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.text2,
              height: 1.6,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.text3,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.text2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildDateInfo() {
    final birthYear = person.premiereDate?.year;
    final deathYear = person.endDate?.year;

    if (birthYear != null && deathYear != null) {
      return '$birthYear - $deathYear';
    } else if (birthYear != null) {
      final age = DateTime.now().year - birthYear;
      return '$birthYear ($age ans)';
    } else if (deathYear != null) {
      return 'Décédé(e) en $deathYear';
    }

    return '';
  }
}

