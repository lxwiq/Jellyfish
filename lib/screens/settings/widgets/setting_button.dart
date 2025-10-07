import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../theme/app_colors.dart';

/// Widget pour un bouton d'action dans les settings
class SettingButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onPressed;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool isDanger;
  final bool isLoading;

  const SettingButton({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onPressed,
    this.iconColor,
    this.backgroundColor,
    this.isDanger = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = isDanger 
        ? AppColors.error 
        : (iconColor ?? AppColors.jellyfinPurple);
    
    final effectiveBackgroundColor = isDanger
        ? AppColors.error.withValues(alpha: 0.1)
        : (backgroundColor ?? AppColors.surface1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icône
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: effectiveIconColor,
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
                        style: TextStyle(
                          color: isDanger ? AppColors.error : AppColors.text6,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
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
                
                // Loading ou flèche
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.jellyfinPurple,
                    ),
                  )
                else
                  Icon(
                    IconsaxPlusLinear.arrow_right_3,
                    size: 20,
                    color: effectiveIconColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

