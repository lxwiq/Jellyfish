import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/downloaded_item.dart';
import '../models/download_status.dart';
import '../providers/offline_download_provider.dart';
import '../theme/app_colors.dart';
import 'liquid_fill_progress_image.dart';

/// Card affichant la progression d'un téléchargement
class DownloadProgressCard extends ConsumerWidget {
  final DownloadedItem item;

  const DownloadProgressCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Écouter les mises à jour en temps réel pour cet item
    final itemStreamAsync = ref.watch(downloadedItemStreamProvider(item.id));

    // Utiliser l'item du stream s'il est disponible, sinon utiliser l'item initial
    final currentItem = itemStreamAsync.whenOrNull(
      data: (streamItem) => streamItem,
    ) ?? item;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _showDetails(context, ref, currentItem),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Liquid Fill Progress Image
              _buildLiquidFillThumbnail(currentItem),
              const SizedBox(width: 16),

              // Info et Actions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    if (currentItem.itemType == 'Episode' && currentItem.metadata != null)
                      _buildEpisodeInfo(context, currentItem)
                    else
                      Text(
                        currentItem.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),

                    // Statut
                    _buildStatusText(context, currentItem),
                    const SizedBox(height: 4),

                    // Taille et vitesse
                    _buildSizeText(context, currentItem),
                    const SizedBox(height: 12),

                    // Boutons d'action
                    _buildActionButtons(context, ref, currentItem),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit l'affichage des informations d'épisode
  Widget _buildEpisodeInfo(BuildContext context, DownloadedItem currentItem) {
    final metadata = currentItem.metadata!;
    final seriesName = metadata['seriesName'] as String?;
    final seasonNumber = metadata['seasonNumber'] as int?;
    final episodeNumber = metadata['episodeNumber'] as int?;
    final episodeName = metadata['episodeName'] as String?;

    if (seriesName == null || seasonNumber == null || episodeNumber == null) {
      return Text(
        currentItem.title,
        style: Theme.of(context).textTheme.titleMedium,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    final episodeText = 'S$seasonNumber:E$episodeNumber';
    final episodeTitle = episodeName ?? 'Épisode $episodeNumber';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de la série
        Text(
          seriesName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        // S1E1 - Nom de l'épisode
        RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              TextSpan(
                text: episodeText,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const TextSpan(text: ' - '),
              TextSpan(text: episodeTitle),
            ],
          ),
        ),
      ],
    );
  }

  /// Construit le thumbnail avec effet de remplissage liquide
  Widget _buildLiquidFillThumbnail(DownloadedItem currentItem) {
    // Pour les téléchargements terminés, afficher l'image normale en couleur
    if (currentItem.isCompleted) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 100,
          height: 150,
          child: currentItem.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: currentItem.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[800],
                    child: const Icon(Icons.movie, size: 48),
                  ),
                )
              : Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.movie, size: 48),
                ),
        ),
      );
    }

    // Pour les téléchargements en cours, utiliser l'effet de remplissage liquide
    return LiquidFillProgressImage(
      imageUrl: currentItem.imageUrl,
      progress: currentItem.progress,
      width: 100,
      height: 150,
      borderRadius: BorderRadius.circular(8),
    );
  }

  /// Construit le texte de statut
  Widget _buildStatusText(BuildContext context, DownloadedItem currentItem) {
    final color = _getStatusColor(currentItem);
    final icon = _getStatusIcon(currentItem);
    final text = _getStatusText(currentItem);

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
  Widget _buildSizeText(BuildContext context, DownloadedItem currentItem) {
    final parts = <String>[
      currentItem.formattedSize,
      currentItem.quality.label,
    ];

    if (currentItem.downloadSpeed != null && currentItem.isDownloading) {
      parts.add(currentItem.downloadSpeed!);
    }

    if (currentItem.estimatedTimeRemaining != null && currentItem.isDownloading) {
      parts.add('ETA: ${currentItem.estimatedTimeRemaining}');
    }

    return Text(
      parts.join(' • '),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  /// Construit les boutons d'action
  Widget _buildActionButtons(BuildContext context, WidgetRef ref, DownloadedItem currentItem) {
    return Row(
      children: [
        // Bouton principal (pause/resume/play)
        if (currentItem.isDownloading)
          ElevatedButton.icon(
            onPressed: () => _pauseDownload(ref, currentItem),
            icon: const Icon(Icons.pause, size: 18),
            label: const Text('Pause'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          )
        else if (currentItem.isPaused || currentItem.isFailed)
          ElevatedButton.icon(
            onPressed: () => _resumeDownload(ref, currentItem),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Resume'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          )
        else if (currentItem.isCompleted)
          ElevatedButton.icon(
            onPressed: () => _playOffline(context, currentItem),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Play'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),

        const SizedBox(width: 8),

        // Bouton de suppression
        OutlinedButton.icon(
          onPressed: () => _deleteDownload(context, ref, currentItem),
          icon: const Icon(Icons.delete, size: 18),
          label: const Text('Delete'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
          ),
        ),
      ],
    );
  }



  /// Obtient la couleur du statut
  Color _getStatusColor(DownloadedItem currentItem) {
    switch (currentItem.status) {
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
  IconData _getStatusIcon(DownloadedItem currentItem) {
    switch (currentItem.status) {
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
  String _getStatusText(DownloadedItem currentItem) {
    switch (currentItem.status) {
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
  Future<void> _pauseDownload(WidgetRef ref, DownloadedItem currentItem) async {
    final service = ref.read(offlineDownloadServiceProvider);
    await service.pauseDownload(currentItem.id);
  }

  /// Reprend le téléchargement
  Future<void> _resumeDownload(WidgetRef ref, DownloadedItem currentItem) async {
    final service = ref.read(offlineDownloadServiceProvider);
    await service.resumeDownload(currentItem.id);
  }

  /// Lit le fichier téléchargé hors ligne
  Future<void> _playOffline(BuildContext context, DownloadedItem currentItem) async {
    try {
      // Vérifier que le fichier existe
      final file = File(currentItem.downloadPath);
      if (!await file.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File not found. Please re-download.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Créer un player local pour la lecture hors ligne
      final player = Player();
      final controller = VideoController(player);

      // Ouvrir le fichier local
      await player.open(Media('file://${currentItem.downloadPath}'), play: true);

      if (context.mounted) {
        // Naviguer vers un écran de lecture simple
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => _OfflineVideoPlayerScreen(
              controller: controller,
              player: player,
              title: currentItem.title,
            ),
          ),
        );

        // Nettoyer après la fermeture
        await player.dispose();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing offline: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Affiche les détails
  void _showDetails(BuildContext context, WidgetRef ref, DownloadedItem currentItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentItem.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentItem.description != null) ...[
              Text(currentItem.description!),
              const SizedBox(height: 16),
            ],
            _buildDetailRow('Status', _getStatusText(currentItem)),
            _buildDetailRow('Quality', currentItem.quality.label),
            _buildDetailRow('Size', currentItem.formattedSize),
            _buildDetailRow('Progress', currentItem.progressPercentage),
            if (currentItem.errorMessage != null)
              _buildDetailRow('Error', currentItem.errorMessage!),
          ],
        ),
        actions: [
          if (currentItem.canCancel)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cancelDownload(context, ref, currentItem);
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
  void _showOptions(BuildContext context, WidgetRef ref, DownloadedItem currentItem) {
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
                _deleteDownload(context, ref, currentItem);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Annule le téléchargement
  Future<void> _cancelDownload(BuildContext context, WidgetRef ref, DownloadedItem currentItem) async {
    final service = ref.read(offlineDownloadServiceProvider);
    await service.cancelDownload(currentItem.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download cancelled')),
      );
    }
  }

  /// Supprime le téléchargement
  Future<void> _deleteDownload(BuildContext context, WidgetRef ref, DownloadedItem currentItem) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Download'),
        content: Text('Are you sure you want to delete "${currentItem.title}"?'),
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

    if (confirmed == true) {
      try {
        final service = ref.read(offlineDownloadServiceProvider);
        await service.deleteDownload(currentItem.id);

        // Invalider les providers pour forcer le rafraîchissement
        ref.invalidate(activeDownloadsProvider);
        ref.invalidate(completedDownloadsProvider);
        ref.invalidate(failedDownloadsProvider);
        ref.invalidate(allDownloadsProvider);
        ref.invalidate(downloadStatsProvider);
        ref.invalidate(activeDownloadsCountProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${currentItem.title} deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting download: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

/// Écran simple pour la lecture vidéo hors ligne
class _OfflineVideoPlayerScreen extends StatefulWidget {
  final VideoController controller;
  final Player player;
  final String title;

  const _OfflineVideoPlayerScreen({
    required this.controller,
    required this.player,
    required this.title,
  });

  @override
  State<_OfflineVideoPlayerScreen> createState() => _OfflineVideoPlayerScreenState();
}

class _OfflineVideoPlayerScreenState extends State<_OfflineVideoPlayerScreen> {
  bool _showControls = true;
  BoxFit _videoFit = BoxFit.contain;

  @override
  void initState() {
    super.initState();
    // Mettre en plein écran
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Restaurer l'orientation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          children: [
            // Vidéo
            Center(
              child: Video(
                controller: widget.controller,
                fit: _videoFit,
              ),
            ),

            // Contrôles
            if (_showControls)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
                child: Column(
                  children: [
                    // Barre supérieure
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _videoFit == BoxFit.contain
                                    ? Icons.fit_screen
                                    : Icons.zoom_in_map,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _videoFit = _videoFit == BoxFit.contain
                                      ? BoxFit.cover
                                      : BoxFit.contain;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Bouton play/pause au centre
                    StreamBuilder<bool>(
                      stream: widget.player.stream.playing,
                      builder: (context, snapshot) {
                        final isPlaying = snapshot.data ?? false;
                        return IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 64,
                          ),
                          onPressed: () {
                            widget.player.playOrPause();
                          },
                        );
                      },
                    ),

                    const Spacer(),

                    // Barre inférieure avec timeline
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: StreamBuilder<Duration>(
                          stream: widget.player.stream.position,
                          builder: (context, positionSnapshot) {
                            final position = positionSnapshot.data ?? Duration.zero;
                            return StreamBuilder<Duration>(
                              stream: widget.player.stream.duration,
                              builder: (context, durationSnapshot) {
                                final duration = durationSnapshot.data ?? Duration.zero;
                                return Column(
                                  children: [
                                    Slider(
                                      value: duration.inMilliseconds > 0
                                          ? position.inMilliseconds.toDouble()
                                          : 0,
                                      min: 0,
                                      max: duration.inMilliseconds.toDouble(),
                                      activeColor: AppColors.jellyfinPurple,
                                      inactiveColor: Colors.white.withOpacity(0.3),
                                      onChanged: (value) {
                                        widget.player.seek(Duration(milliseconds: value.toInt()));
                                      },
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDuration(position),
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                        Text(
                                          _formatDuration(duration),
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}

