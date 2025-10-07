import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../theme/app_colors.dart';

/// Widget pour afficher une ligne de paramètre avec label, valeur et action
class SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;

  const SettingTile({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icône
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.jellyfinPurple).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor ?? AppColors.jellyfinPurple,
              ),
            ),
            const SizedBox(width: 12),
            
            // Label et subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.text6,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppColors.text3,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Valeur ou trailing widget
            if (trailing != null)
              trailing!
            else if (value != null) ...[
              const SizedBox(width: 8),
              Text(
                value!,
                style: const TextStyle(
                  color: AppColors.text4,
                  fontSize: 14,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                const Icon(
                  IconsaxPlusLinear.arrow_right_3,
                  size: 16,
                  color: AppColors.text3,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

