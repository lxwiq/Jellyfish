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
          print('📥 Update reçue: ${item.title} - ${item.progressPercentage} - ${item.status}');

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
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.storage,
            label: 'Storage',
            value: stats.formattedSize,
          ),
          _buildStatItem(
            icon: Icons.download,
            label: 'Active',
            value: stats.activeCount.toString(),
          ),
          _buildStatItem(
            icon: Icons.check_circle,
            label: 'Completed',
            value: stats.completedCount.toString(),
          ),
          _buildStatItem(
            icon: Icons.error,
            label: 'Failed',
            value: stats.failedCount.toString(),
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
  }) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
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
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
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

