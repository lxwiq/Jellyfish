import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/downloaded_item.dart';
import '../models/download_status.dart';
import '../providers/offline_download_provider.dart';

/// Card affichant la progression d'un téléchargement
class DownloadProgressCard extends ConsumerWidget {
  final DownloadedItem item;

  const DownloadProgressCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showDetails(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Thumbnail
                  _buildThumbnail(),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        _buildStatusText(context),
                        const SizedBox(height: 4),
                        _buildSizeText(context),
                      ],
                    ),
                  ),

                  // Actions
                  _buildActionButton(context, ref),
                ],
              ),

              // Progress bar
              if (item.isDownloading || item.isPaused) ...[
                const SizedBox(height: 12),
                _buildProgressBar(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Construit le thumbnail
  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 80,
        height: 120,
        child: item.imageUrl != null
            ? CachedNetworkImage(
                imageUrl: item.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.movie),
                ),
              )
            : Container(
                color: Colors.grey[800],
                child: const Icon(Icons.movie),
              ),
      ),
    );
  }

  /// Construit le texte de statut
  Widget _buildStatusText(BuildContext context) {
    final color = _getStatusColor();
    final icon = _getStatusIcon();
    final text = _getStatusText();

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Construit le texte de taille
  Widget _buildSizeText(BuildContext context) {
    final parts = <String>[
      item.formattedSize,
      item.quality.label,
    ];

    if (item.downloadSpeed != null && item.isDownloading) {
      parts.add(item.downloadSpeed!);
    }

    if (item.estimatedTimeRemaining != null && item.isDownloading) {
      parts.add('ETA: ${item.estimatedTimeRemaining}');
    }

    return Text(
      parts.join(' • '),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  /// Construit la barre de progression
  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: item.progress,
          backgroundColor: Colors.grey[800],
        ),
        const SizedBox(height: 4),
        Text(
          item.progressPercentage,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  /// Construit le bouton d'action
  Widget _buildActionButton(BuildContext context, WidgetRef ref) {
    if (item.isDownloading) {
      return IconButton(
        onPressed: () => _pauseDownload(ref),
        icon: const Icon(Icons.pause),
        tooltip: 'Pause',
      );
    }

    if (item.isPaused || item.isFailed) {
      return IconButton(
        onPressed: () => _resumeDownload(ref),
        icon: const Icon(Icons.play_arrow),
        tooltip: 'Resume',
      );
    }

    if (item.isCompleted) {
      return IconButton(
        onPressed: () => _showOptions(context, ref),
        icon: const Icon(Icons.more_vert),
        tooltip: 'Options',
      );
    }

    return const SizedBox.shrink();
  }

  /// Obtient la couleur du statut
  Color _getStatusColor() {
    switch (item.status) {
      case DownloadStatus.downloading:
        return Colors.blue;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.paused:
        return Colors.orange;
      case DownloadStatus.pending:
        return Colors.grey;
      case DownloadStatus.cancelled:
        return Colors.grey;
    }
  }

  /// Obtient l'icône du statut
  IconData _getStatusIcon() {
    switch (item.status) {
      case DownloadStatus.downloading:
        return Icons.download;
      case DownloadStatus.completed:
        return Icons.check_circle;
      case DownloadStatus.failed:
        return Icons.error;
      case DownloadStatus.paused:
        return Icons.pause_circle;
      case DownloadStatus.pending:
        return Icons.hourglass_empty;
      case DownloadStatus.cancelled:
        return Icons.cancel;
    }
  }

  /// Obtient le texte du statut
  String _getStatusText() {
    switch (item.status) {
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.pending:
        return 'Pending';
      case DownloadStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Met en pause le téléchargement
  Future<void> _pauseDownload(WidgetRef ref) async {
    final service = ref.read(offlineDownloadServiceProvider);
    await service.pauseDownload(item.id);
  }

  /// Reprend le téléchargement
  Future<void> _resumeDownload(WidgetRef ref) async {
    final service = ref.read(offlineDownloadServiceProvider);
    await service.resumeDownload(item.id);
  }

  /// Affiche les détails
  void _showDetails(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description != null) ...[
              Text(item.description!),
              const SizedBox(height: 16),
            ],
            _buildDetailRow('Status', _getStatusText()),
            _buildDetailRow('Quality', item.quality.label),
            _buildDetailRow('Size', item.formattedSize),
            _buildDetailRow('Progress', item.progressPercentage),
            if (item.errorMessage != null)
              _buildDetailRow('Error', item.errorMessage!),
          ],
        ),
        actions: [
          if (item.canCancel)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelDownload(context, ref);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cancel'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Construit une ligne de détail
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche les options
  void _showOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
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
              title: const Text('Delete'),
              onTap: () {
                Navigator.of(context).pop();
                _deleteDownload(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Annule le téléchargement
  Future<void> _cancelDownload(BuildContext context, WidgetRef ref) async {
    final service = ref.read(offlineDownloadServiceProvider);
    await service.cancelDownload(item.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download cancelled')),
      );
    }
  }

  /// Supprime le téléchargement
  Future<void> _deleteDownload(BuildContext context, WidgetRef ref) async {
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
      await service.deleteDownload(item.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download deleted')),
        );
      }
    }
  }
}

