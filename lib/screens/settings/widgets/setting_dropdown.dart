import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../theme/app_colors.dart';

/// Widget pour un paramètre avec dropdown
class SettingDropdown<T> extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final Color? iconColor;

  const SettingDropdown({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.items,
    required this.onChanged,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          
          const SizedBox(width: 8),
          
          // Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              underline: const SizedBox.shrink(),
              dropdownColor: AppColors.background3,
              style: const TextStyle(
                color: AppColors.text6,
                fontSize: 14,
              ),
              icon: const Icon(
                IconsaxPlusLinear.arrow_down_1,
                size: 16,
                color: AppColors.text4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

