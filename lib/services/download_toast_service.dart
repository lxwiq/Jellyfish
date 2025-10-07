import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/downloaded_item.dart';
import '../models/download_status.dart';
import '../providers/offline_download_provider.dart';
import '../theme/app_colors.dart';

/// Service pour afficher des toasts lors des changements d'état des téléchargements
class DownloadToastService {
  static final DownloadToastService instance = DownloadToastService._();
  DownloadToastService._();

  final Map<String, DownloadStatus> _lastKnownStatus = {};
  BuildContext? _context;

  /// Initialise le service avec le contexte
  void initialize(BuildContext context) {
    _context = context;
  }

  /// Écoute les changements de statut des téléchargements
  void listenToDownloads(WidgetRef ref) {
    ref.listen<AsyncValue<DownloadedItem>>(
      downloadProgressStreamProvider,
      (previous, next) {
        next.whenData((item) {
          _handleDownloadUpdate(item);
        });
      },
    );
  }

  /// Gère les mises à jour de téléchargement
  void _handleDownloadUpdate(DownloadedItem item) {
    final lastStatus = _lastKnownStatus[item.id];
    final currentStatus = item.status;

    // Mettre à jour le statut connu
    _lastKnownStatus[item.id] = currentStatus;

    // Si c'est la première fois qu'on voit cet item, ne pas afficher de toast
    if (lastStatus == null) {
      return;
    }

    // Détecter les changements de statut importants
    if (lastStatus != currentStatus) {
      switch (currentStatus) {
        case DownloadStatus.completed:
          _showCompletedToast(item);
          break;
        case DownloadStatus.failed:
          _showFailedToast(item);
          break;
        default:
          break;
      }
    }
  }

  /// Affiche un toast pour un téléchargement terminé
  void _showCompletedToast(DownloadedItem item) {
    if (_context == null || !_context!.mounted) return;

    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Téléchargement terminé',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Voir',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Naviguer vers l'écran de téléchargements
          },
        ),
      ),
    );
  }

  /// Affiche un toast pour un téléchargement échoué
  void _showFailedToast(DownloadedItem item) {
    if (_context == null || !_context!.mounted) return;

    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Téléchargement échoué',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Réessayer',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Réessayer le téléchargement
          },
        ),
      ),
    );
  }

  /// Nettoie les statuts connus (à appeler quand tous les téléchargements sont terminés)
  void clearCompletedDownloads(List<String> downloadIds) {
    for (final id in downloadIds) {
      _lastKnownStatus.remove(id);
    }
  }

  /// Réinitialise le service
  void dispose() {
    _lastKnownStatus.clear();
    _context = null;
  }
}

