import 'package:flutter/material.dart';
import 'package:jellyfish/theme/app_colors.dart';

/// Titre de section cohérent pour Jellyseerr
/// Suit le pattern utilisé dans home_screen.dart
class JellyseerrSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onSeeAll;
  final bool isDesktop;

  const JellyseerrSectionTitle({
    super.key,
    required this.title,
    required this.icon,
    this.onSeeAll,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.jellyfinPurple,
            size: isDesktop ? 28 : 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text6,
                    fontSize: isDesktop ? 24 : 20,
                  ),
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Voir tout',
                    style: TextStyle(
                      color: AppColors.jellyfinPurple,
                      fontSize: isDesktop ? 14 : 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: AppColors.jellyfinPurple,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

