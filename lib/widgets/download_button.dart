import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../jellyfin/jellyfin_open_api.swagger.dart';
import '../models/download_status.dart';
import '../providers/offline_download_provider.dart';
import '../providers/services_provider.dart';

/// Bouton de téléchargement pour un item Jellyfin
class DownloadButton extends ConsumerWidget {
  final BaseItemDto item;
  final bool showLabel;

  const DownloadButton({
    super.key,
    required this.item,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (item.id == null) {
      return const SizedBox.shrink();
    }

    final downloadedItemAsync = ref.watch(
      downloadedItemByJellyfinIdProvider(item.id!),
    );

    return downloadedItemAsync.when(
      data: (downloadedItem) {
        if (downloadedItem == null) {
          // Pas encore téléchargé
          return _buildDownloadButton(context, ref);
        }

        // Déjà téléchargé ou en cours
        return _buildStatusButton(context, ref, downloadedItem);
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => const Icon(Icons.error),
    );
  }

  /// Bouton pour démarrer un téléchargement
  Widget _buildDownloadButton(BuildContext context, WidgetRef ref) {
    return showLabel
        ? ElevatedButton.icon(
            onPressed: () => _showQualityDialog(context, ref),
            icon: const Icon(Icons.download),
            label: const Text('Download'),
          )
        : IconButton(
            onPressed: () => _showQualityDialog(context, ref),
            icon: const Icon(Icons.download),
            tooltip: 'Download',
          );
  }

  /// Bouton affichant le statut du téléchargement
  Widget _buildStatusButton(
    BuildContext context,
    WidgetRef ref,
    downloadedItem,
  ) {
    final status = downloadedItem.status as DownloadStatus;

    switch (status) {
      case DownloadStatus.downloading:
        return _buildDownloadingButton(context, ref, downloadedItem);

      case DownloadStatus.completed:
        return _buildCompletedButton(context, ref, downloadedItem);

      case DownloadStatus.paused:
        return _buildPausedButton(context, ref, downloadedItem);

      case DownloadStatus.failed:
        return _buildFailedButton(context, ref, downloadedItem);

      case DownloadStatus.pending:
        return _buildPendingButton(context, ref, downloadedItem);

      default:
        return _buildDownloadButton(context, ref);
    }
  }

  /// Bouton pour un téléchargement en cours
  Widget _buildDownloadingButton(
    BuildContext context,
    WidgetRef ref,
    downloadedItem,
  ) {
    final progress = downloadedItem.progress as double;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
          ),
        ),
        IconButton(
          onPressed: () => _pauseDownload(ref, downloadedItem.id as String),
          icon: const Icon(Icons.pause, size: 20),
          tooltip: 'Pause',
        ),
      ],
    );
  }

  /// Bouton pour un téléchargement terminé
  Widget _buildCompletedButton(
    BuildContext context,
    WidgetRef ref,
    downloadedItem,
  ) {
    return showLabel
        ? ElevatedButton.icon(
            onPressed: () => _showDownloadOptions(context, ref, downloadedItem),
            icon: const Icon(Icons.check_circle, color: Colors.green),
            label: const Text('Downloaded'),
          )
        : IconButton(
            onPressed: () => _showDownloadOptions(context, ref, downloadedItem),
            icon: const Icon(Icons.check_circle, color: Colors.green),
            tooltip: 'Downloaded',
          );
  }

  /// Bouton pour un téléchargement en pause
  Widget _buildPausedButton(
    BuildContext context,
    WidgetRef ref,
    downloadedItem,
  ) {
    return IconButton(
      onPressed: () => _resumeDownload(ref, downloadedItem.id as String),
      icon: const Icon(Icons.play_arrow, color: Colors.orange),
      tooltip: 'Resume',
    );
  }

  /// Bouton pour un téléchargement échoué
  Widget _buildFailedButton(
    BuildContext context,
    WidgetRef ref,
    downloadedItem,
  ) {
    return IconButton(
      onPressed: () => _retryDownload(context, ref, downloadedItem),
      icon: const Icon(Icons.error, color: Colors.red),
      tooltip: 'Retry',
    );
  }

  /// Bouton pour un téléchargement en attente
  Widget _buildPendingButton(
    BuildContext context,
    WidgetRef ref,
    downloadedItem,
  ) {
    return const IconButton(
      onPressed: null,
      icon: Icon(Icons.hourglass_empty),
      tooltip: 'Pending',
    );
  }

  /// Affiche le dialogue de sélection de qualité
  Future<void> _showQualityDialog(BuildContext context, WidgetRef ref) async {
    final quality = await showDialog<DownloadQuality>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Quality'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: DownloadQuality.values.map((q) {
            return ListTile(
              title: Text(q.label),
              subtitle: Text(q.description),
              onTap: () => Navigator.of(context).pop(q),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (quality != null && context.mounted) {
      await _startDownload(context, ref, quality);
    }
  }

  /// Démarre un téléchargement
  Future<void> _startDownload(
    BuildContext context,
    WidgetRef ref,
    DownloadQuality quality,
  ) async {
    try {
      // Vérifier les permissions avant de démarrer le téléchargement
      final permissionService = ref.read(permissionServiceProvider);
      final hasPermissions = await permissionService.requestDownloadPermissions();

      if (!hasPermissions && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Permissions required to download content'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => permissionService.openAppSettings(),
            ),
          ),
        );
        return;
      }

      final service = ref.read(offlineDownloadServiceProvider);
      await service.downloadItem(item, quality);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download started: ${item.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start download: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Met en pause un téléchargement
  Future<void> _pauseDownload(WidgetRef ref, String downloadId) async {
    final service = ref.read(offlineDownloadServiceProvider);
    await service.pauseDownload(downloadId);
  }

  /// Reprend un téléchargement
  Future<void> _resumeDownload(WidgetRef ref, String downloadId) async {
    final service = ref.read(offlineDownloadServiceProvider);
    await service.resumeDownload(downloadId);
  }

  /// Réessaye un téléchargement échoué
  Future<void> _retryDownload(
    BuildContext context,
    WidgetRef ref,
    downloadedItem,
  ) async {
    final service = ref.read(offlineDownloadServiceProvider);
    await service.resumeDownload(downloadedItem.id as String);
  }

  /// Affiche les options pour un téléchargement terminé
  Future<void> _showDownloadOptions(
    BuildContext context,
    WidgetRef ref,
    downloadedItem,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Play Offline'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Implémenter la lecture hors ligne
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Download'),
              onTap: () async {
                Navigator.of(context).pop();
                await _deleteDownload(context, ref, downloadedItem.id as String);
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

  /// Supprime un téléchargement
  Future<void> _deleteDownload(
    BuildContext context,
    WidgetRef ref,
    String downloadId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Download'),
        content: const Text('Are you sure you want to delete this download?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final service = ref.read(offlineDownloadServiceProvider);
      await service.deleteDownload(downloadId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download deleted')),
        );
      }
    }
  }
}

