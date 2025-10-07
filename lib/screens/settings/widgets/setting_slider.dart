import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Widget pour un paramètre avec slider
class SettingSlider extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final String Function(double)? valueFormatter;
  final Color? iconColor;

  const SettingSlider({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
    this.valueFormatter,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              
              // Label
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
              
              // Valeur actuelle
              Text(
                valueFormatter != null ? valueFormatter!(value) : value.toStringAsFixed(0),
                style: const TextStyle(
                  color: AppColors.jellyfinPurple,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.jellyfinPurple,
              inactiveTrackColor: AppColors.surface1,
              thumbColor: AppColors.jellyfinPurple,
              overlayColor: AppColors.jellyfinPurple.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

