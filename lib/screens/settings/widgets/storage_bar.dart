import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Widget pour afficher une barre de progression du stockage
class StorageBar extends StatelessWidget {
  final String label;
  final int usedBytes;
  final int? totalBytes;
  final Color? color;

  const StorageBar({
    super.key,
    required this.label,
    required this.usedBytes,
    this.totalBytes,
    this.color,
  });

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final usedFormatted = _formatBytes(usedBytes);
    final totalFormatted = totalBytes != null ? _formatBytes(totalBytes!) : null;
    final progress = totalBytes != null && totalBytes! > 0
        ? (usedBytes / totalBytes!).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label et valeurs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.text6,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                totalFormatted != null 
                    ? '$usedFormatted / $totalFormatted'
                    : usedFormatted,
                style: const TextStyle(
                  color: AppColors.text4,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surface1,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? AppColors.jellyfinPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

