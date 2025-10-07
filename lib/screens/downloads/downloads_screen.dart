import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/downloaded_item.dart';
import '../../providers/offline_download_provider.dart';
import '../../widgets/download_progress_card.dart';

/// Écran principal de gestion des téléchargements
class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Rafraîchir automatiquement toutes les 2 secondes pour les téléchargements actifs
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        ref.invalidate(activeDownloadsProvider);
        ref.invalidate(downloadStatsProvider);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Activer le listener de progression pour l'actualisation automatique
    ref.watch(downloadProgressListenerProvider);

    // Écouter le stream de progression pour afficher des notifications et logs
    ref.listen<AsyncValue<DownloadedItem>>(
      downloadProgressStreamProvider,
      (previous, next) {
        next.whenData((item) {
          // Log pour debug
          debugPrint('📥 Update reçue: ${item.title} - ${item.progressPercentage} - ${item.status}');

          if (item.isCompleted && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.title} downloaded successfully'),
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (item.isFailed && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.title} download failed'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
      },
    );

    final statsAsync = ref.watch(downloadStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active', icon: Icon(Icons.download)),
            Tab(text: 'Completed', icon: Icon(Icons.check_circle)),
            Tab(text: 'Failed', icon: Icon(Icons.error)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showSettings(context),
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats header
          statsAsync.when(
            data: (stats) => _buildStatsHeader(stats),
            loading: () => const LinearProgressIndicator(),
            error: (error, stack) => const SizedBox.shrink(),
          ),

          // Tabs content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActiveTab(),
                _buildCompletedTab(),
                _buildFailedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit l'en-tête des statistiques
  Widget _buildStatsHeader(DownloadStats stats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.storage_rounded,
            label: 'Storage',
            value: stats.formattedSize,
            color: Colors.blue,
          ),
          _buildStatItem(
            icon: Icons.download_rounded,
            label: 'Active',
            value: stats.activeCount.toString(),
            color: Colors.orange,
          ),
          _buildStatItem(
            icon: Icons.check_circle_rounded,
            label: 'Done',
            value: stats.completedCount.toString(),
            color: Colors.green,
          ),
          _buildStatItem(
            icon: Icons.error_rounded,
            label: 'Failed',
            value: stats.failedCount.toString(),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  /// Construit un élément de statistique
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  /// Construit l'onglet des téléchargements actifs
  Widget _buildActiveTab() {
    final activeDownloadsAsync = ref.watch(activeDownloadsProvider);

    return activeDownloadsAsync.when(
      data: (downloads) {
        if (downloads.isEmpty) {
          return _buildEmptyState(
            icon: Icons.download,
            message: 'No active downloads',
          );
        }

        // Garder le RefreshIndicator pour permettre un rafraîchissement manuel
        // mais l'actualisation se fait maintenant automatiquement via le stream
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(activeDownloadsProvider);
            ref.invalidate(downloadStatsProvider);
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: downloads.length,
            itemBuilder: (context, index) {
              return DownloadProgressCard(item: downloads[index]);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  /// Construit l'onglet des téléchargements terminés
  Widget _buildCompletedTab() {
    final completedDownloadsAsync = ref.watch(completedDownloadsProvider);

    return completedDownloadsAsync.when(
      data: (downloads) {
        if (downloads.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle,
            message: 'No completed downloads',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(completedDownloadsProvider);
            ref.invalidate(downloadStatsProvider);
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: downloads.length,
            itemBuilder: (context, index) {
              return DownloadProgressCard(item: downloads[index]);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  /// Construit l'onglet des téléchargements échoués
  Widget _buildFailedTab() {
    final failedDownloadsAsync = ref.watch(failedDownloadsProvider);

    return failedDownloadsAsync.when(
      data: (downloads) {
        if (downloads.isEmpty) {
          return _buildEmptyState(
            icon: Icons.error,
            message: 'No failed downloads',
          );
        }

        return Column(
          children: [
            // Bouton pour réessayer tous
            if (downloads.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () => _retryAllFailed(downloads),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry All'),
                ),
              ),

            // Liste des téléchargements échoués avec RefreshIndicator
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(failedDownloadsProvider);
                  ref.invalidate(downloadStatsProvider);
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: downloads.length,
                  itemBuilder: (context, index) {
                    return DownloadProgressCard(item: downloads[index]);
                  },
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  /// Construit un état vide
  Widget _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[800]?.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start downloading content to watch offline',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Construit un état d'erreur
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error: $error',
            style: const TextStyle(fontSize: 18, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Réessaye tous les téléchargements échoués
  Future<void> _retryAllFailed(List<DownloadedItem> downloads) async {
    final service = ref.read(offlineDownloadServiceProvider);

    for (final download in downloads) {
      await service.resumeDownload(download.id);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Retrying ${downloads.length} downloads'),
        ),
      );
    }
  }

  /// Affiche les paramètres
  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('Clear Failed Downloads'),
              onTap: () {
                Navigator.of(context).pop();
                _clearFailedDownloads();
              },
            ),
            ListTile(
              leading: const Icon(Icons.pause),
              title: const Text('Pause All Downloads'),
              onTap: () {
                Navigator.of(context).pop();
                _pauseAllDownloads();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Nettoie les téléchargements échoués
  Future<void> _clearFailedDownloads() async {
    final storageService = ref.read(offlineStorageServiceProvider);
    await storageService.cleanupFailedDownloads();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed downloads cleared')),
      );

      // Rafraîchir les données
      ref.invalidate(failedDownloadsProvider);
      ref.invalidate(downloadStatsProvider);
    }
  }

  /// Met en pause tous les téléchargements
  Future<void> _pauseAllDownloads() async {
    final activeDownloads = await ref.read(activeDownloadsProvider.future);
    final service = ref.read(offlineDownloadServiceProvider);

    for (final download in activeDownloads) {
      if (download.isDownloading) {
        await service.pauseDownload(download.id);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All downloads paused')),
      );
    }
  }
}

