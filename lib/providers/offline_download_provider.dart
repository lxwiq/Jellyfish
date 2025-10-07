import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/offline_download_service.dart';
import '../services/offline_storage_service.dart';
import '../services/offline_notification_service.dart';
import '../models/downloaded_item.dart';
import '../models/download_status.dart';
import 'services_provider.dart';

/// Provider pour OfflineStorageService
final offlineStorageServiceProvider = Provider<OfflineStorageService>((ref) {
  return OfflineStorageService();
});

/// Provider pour OfflineNotificationService
final offlineNotificationServiceProvider = Provider<OfflineNotificationService>((ref) {
  final service = OfflineNotificationService();
  // Initialiser le service
  service.initialize();
  return service;
});

/// Provider pour OfflineDownloadService
final offlineDownloadServiceProvider = Provider<OfflineDownloadService>((ref) {
  final storageService = ref.watch(offlineStorageServiceProvider);
  final notificationService = ref.watch(offlineNotificationServiceProvider);
  final jellyfinService = ref.watch(jellyfinServiceProvider);

  final service = OfflineDownloadService(
    storageService,
    notificationService,
    jellyfinService,
  );

  // Initialiser le service
  service.initialize();

  // Nettoyer lors de la destruction
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider pour la liste de tous les téléchargements
final allDownloadsProvider = FutureProvider<List<DownloadedItem>>((ref) async {
  final service = ref.watch(offlineDownloadServiceProvider);
  return await service.getAllDownloads();
});

/// Provider pour les téléchargements actifs (downloading, pending, paused)
final activeDownloadsProvider = FutureProvider<List<DownloadedItem>>((ref) async {
  final service = ref.watch(offlineDownloadServiceProvider);
  return await service.getActiveDownloads();
});

/// Provider pour le nombre de téléchargements actifs (pour le badge)
final activeDownloadsCountProvider = FutureProvider<int>((ref) async {
  final downloads = await ref.watch(activeDownloadsProvider.future);
  return downloads.length;
});

/// Provider pour les téléchargements en cours
final downloadingItemsProvider = FutureProvider<List<DownloadedItem>>((ref) async {
  final service = ref.watch(offlineDownloadServiceProvider);
  return await service.getDownloadsByStatus(DownloadStatus.downloading);
});

/// Provider pour les téléchargements terminés
final completedDownloadsProvider = FutureProvider<List<DownloadedItem>>((ref) async {
  final service = ref.watch(offlineDownloadServiceProvider);
  return await service.getDownloadsByStatus(DownloadStatus.completed);
});

/// Provider pour les téléchargements échoués
final failedDownloadsProvider = FutureProvider<List<DownloadedItem>>((ref) async {
  final service = ref.watch(offlineDownloadServiceProvider);
  return await service.getDownloadsByStatus(DownloadStatus.failed);
});

/// Provider pour les téléchargements en pause
final pausedDownloadsProvider = FutureProvider<List<DownloadedItem>>((ref) async {
  final service = ref.watch(offlineDownloadServiceProvider);
  return await service.getDownloadsByStatus(DownloadStatus.paused);
});

/// Provider pour vérifier si un item est téléchargé
final isItemDownloadedProvider = FutureProvider.family<bool, String>((ref, itemId) async {
  final storageService = ref.watch(offlineStorageServiceProvider);
  final item = await storageService.getDownloadedItemByJellyfinId(itemId);
  return item != null && item.isCompleted;
});

/// Provider pour obtenir un item téléchargé par son ID Jellyfin
final downloadedItemByJellyfinIdProvider = FutureProvider.family<DownloadedItem?, String>(
  (ref, itemId) async {
    final storageService = ref.watch(offlineStorageServiceProvider);
    return await storageService.getDownloadedItemByJellyfinId(itemId);
  },
);

/// Provider pour obtenir un item téléchargé par son ID de téléchargement
final downloadedItemByIdProvider = FutureProvider.family<DownloadedItem?, String>(
  (ref, downloadId) async {
    final storageService = ref.watch(offlineStorageServiceProvider);
    return await storageService.getDownloadedItem(downloadId);
  },
);

/// Provider pour obtenir un item téléchargé en temps réel (avec stream)
final downloadedItemStreamProvider = StreamProvider.family<DownloadedItem?, String>(
  (ref, downloadId) {
    final storageService = ref.watch(offlineStorageServiceProvider);
    final service = ref.watch(offlineDownloadServiceProvider);

    // Créer un stream qui combine l'état initial et les mises à jour
    return Stream.multi((controller) async {
      // Émettre l'état initial
      final initialItem = await storageService.getDownloadedItem(downloadId);
      if (!controller.isClosed) {
        controller.add(initialItem);
      }

      // Écouter les mises à jour du stream de progression
      final subscription = service.progressStream.listen(
        (updatedItem) {
          if (updatedItem.id == downloadId && !controller.isClosed) {
            controller.add(updatedItem);
          }
        },
        onError: (error) {
          if (!controller.isClosed) {
            controller.addError(error);
          }
        },
      );

      // Nettoyer lors de la fermeture
      controller.onCancel = () {
        subscription.cancel();
      };
    });
  },
);

/// Provider pour le stream de progression des téléchargements
final downloadProgressStreamProvider = StreamProvider<DownloadedItem>((ref) {
  final service = ref.watch(offlineDownloadServiceProvider);
  return service.progressStream;
});

/// Provider qui écoute le stream de progression et invalide les autres providers
final downloadProgressListenerProvider = Provider<void>((ref) {
  // Écouter le stream de progression
  ref.listen<AsyncValue<DownloadedItem>>(
    downloadProgressStreamProvider,
    (previous, next) {
      next.whenData((item) {
        // Invalider les providers de listes pour forcer le rafraîchissement
        ref.invalidate(activeDownloadsProvider);
        ref.invalidate(completedDownloadsProvider);
        ref.invalidate(failedDownloadsProvider);
        ref.invalidate(allDownloadsProvider);
        ref.invalidate(downloadStatsProvider);

        // Invalider le provider spécifique à cet item
        ref.invalidate(downloadedItemByJellyfinIdProvider(item.itemId));
        ref.invalidate(isItemDownloadedProvider(item.itemId));
      });
    },
  );
});

/// Provider pour les statistiques de téléchargement
final downloadStatsProvider = FutureProvider<DownloadStats>((ref) async {
  final storageService = ref.watch(offlineStorageServiceProvider);

  final totalSpace = await storageService.getTotalSpaceUsed();
  final completedCount = await storageService.countByStatus(DownloadStatus.completed);
  final activeCount = await storageService.countByStatus(DownloadStatus.downloading);
  final failedCount = await storageService.countByStatus(DownloadStatus.failed);

  return DownloadStats(
    totalSpaceUsed: totalSpace,
    completedCount: completedCount,
    activeCount: activeCount,
    failedCount: failedCount,
  );
});

/// Classe pour les statistiques de téléchargement
class DownloadStats {
  final int totalSpaceUsed;
  final int completedCount;
  final int activeCount;
  final int failedCount;

  const DownloadStats({
    required this.totalSpaceUsed,
    required this.completedCount,
    required this.activeCount,
    required this.failedCount,
  });

  /// Taille formatée (ex: "1.5 GB")
  String get formattedSize {
    final bytes = totalSpaceUsed;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  int get totalCount => completedCount + activeCount + failedCount;
}

