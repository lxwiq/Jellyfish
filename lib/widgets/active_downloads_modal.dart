import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../providers/offline_download_provider.dart';
import '../theme/app_colors.dart';
import 'liquid_fill_progress_image.dart';

/// Modal affichant les téléchargements actifs
class ActiveDownloadsModal extends ConsumerWidget {
  const ActiveDownloadsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDownloadsAsync = ref.watch(activeDownloadsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppColors.background2,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(context),
          
          const Divider(height: 1),
          
          // Liste des téléchargements
          Expanded(
            child: activeDownloadsAsync.when(
              data: (downloads) {
                if (downloads.isEmpty) {
                  return _buildEmptyState();
                }
                
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: downloads.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final download = downloads[index];
                    return _buildDownloadCard(context, ref, download);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text(
                  'Erreur: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.jellyfinPurple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              IconsaxPlusBold.document_download,
              color: AppColors.jellyfinPurple,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Téléchargements en cours',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.text6,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(IconsaxPlusLinear.close_circle),
            color: AppColors.text4,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.text1.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              IconsaxPlusLinear.document_download,
              size: 64,
              color: AppColors.text3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun téléchargement en cours',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.text5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos téléchargements apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.text3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadCard(BuildContext context, WidgetRef ref, download) {
    final progress = download.progress;
    final speed = _formatSpeed(download.downloadSpeed ?? 0);
    final eta = _formatETA(download.estimatedTimeRemaining);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.text1.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Image avec effet liquid fill
          if (download.imageUrl != null)
            LiquidFillProgressImage(
              imageUrl: download.imageUrl!,
              progress: progress,
              width: 60,
              height: 90,
              borderRadius: BorderRadius.circular(8),
            )
          else
            Container(
              width: 60,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.text1.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                IconsaxPlusLinear.video_square,
                color: AppColors.text3,
                size: 32,
              ),
            ),
          
          const SizedBox(width: 12),
          
          // Informations
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                Text(
                  download.title ?? 'Sans titre',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text6,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                // Barre de progression
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.text1.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.jellyfinPurple,
                    ),
                    minHeight: 6,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Stats
                Row(
                  children: [
                    // Pourcentage
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.jellyfinPurple,
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Vitesse
                    if (speed.isNotEmpty) ...[
                      const Icon(
                        IconsaxPlusLinear.flash,
                        size: 14,
                        color: AppColors.text4,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        speed,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.text4,
                        ),
                      ),
                    ],
                    
                    const Spacer(),
                    
                    // ETA
                    if (eta.isNotEmpty)
                      Text(
                        eta,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.text4,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond <= 0) return '';
    
    if (bytesPerSecond < 1024) {
      return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    } else if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
  }

  String _formatETA(int? seconds) {
    if (seconds == null || seconds <= 0) return '';
    
    if (seconds < 60) {
      return '${seconds}s restantes';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '${minutes}min restantes';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '${hours}h ${minutes}min restantes';
    }
  }
}

