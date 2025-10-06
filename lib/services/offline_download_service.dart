import 'dart:async';
import 'package:background_downloader/background_downloader.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/downloaded_item.dart';
import '../models/download_status.dart';
import '../jellyfin/jellyfin_open_api.swagger.dart';
import 'offline_storage_service.dart';
import 'offline_notification_service.dart';
import 'jellyfin_service.dart';

// Import pour DownloadQuality
export '../models/download_status.dart' show DownloadQuality;

/// Service principal de gestion des téléchargements hors ligne
class OfflineDownloadService {
  final OfflineStorageService _storageService;
  final OfflineNotificationService _notificationService;
  final JellyfinService _jellyfinService;
  final Uuid _uuid = const Uuid();

  // Stream controller pour les mises à jour de progression
  final _progressController = StreamController<DownloadedItem>.broadcast();
  Stream<DownloadedItem> get progressStream => _progressController.stream;

  // Map pour suivre les tâches actives
  final Map<String, DownloadTask> _activeTasks = {};

  // Map pour faire correspondre taskId (background_downloader) -> downloadId (notre DB)
  final Map<String, String> _taskIdMapping = {};

  // Connectivité
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _initialized = false;

  OfflineDownloadService(
    this._storageService,
    this._notificationService,
    this._jellyfinService,
  );

  /// Initialise le service de téléchargement
  Future<void> initialize() async {
    if (_initialized) return;

    print('📥 Initialisation du service de téléchargement');

    // Démarrer le FileDownloader et reprogrammer les tâches tuées
    await FileDownloader().start(doRescheduleKilledTasks: true);

    // Activer le tracking des tâches pour la persistance
    await FileDownloader().trackTasks();

    // Configurer les callbacks pour les mises à jour
    FileDownloader().updates.listen(_handleDownloadUpdate);

    // Configurer les notifications par défaut
    await FileDownloader().configure(
      globalConfig: [
        (Config.requestTimeout, const Duration(seconds: 100)),
      ],
      androidConfig: [
        (Config.useCacheDir, Config.whenAble),
      ],
      iOSConfig: [
        (Config.localize, {'Cancel': 'Cancel'}),
      ],
    );

    // Restaurer le mapping des tâches depuis la base de données du package
    await _restoreTaskMapping();

    // Restaurer les téléchargements en cours
    await _restorePendingDownloads();

    // Surveiller la connectivité
    _setupConnectivityMonitoring();

    _initialized = true;
    print('✅ Service de téléchargement initialisé');
  }

  /// Configure la surveillance de la connectivité
  void _setupConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (results) {
        final isConnected = results.any((result) => 
          result != ConnectivityResult.none
        );
        
        if (isConnected) {
          print('🌐 Connexion rétablie - reprise des téléchargements');
          _resumeAllPausedDownloads();
        } else {
          print('📡 Connexion perdue - pause des téléchargements');
          _pauseAllActiveDownloads();
        }
      },
    );
  }

  /// Démarre un téléchargement
  Future<String> downloadItem(
    BaseItemDto item,
    DownloadQuality quality,
  ) async {
    if (!_initialized) {
      await initialize();
    }

    if (item.id == null) {
      throw Exception('Item ID is null');
    }

    print('📥 Démarrage du téléchargement: ${item.name}');

    // Vérifier si déjà téléchargé
    final existing = await _storageService.getDownloadedItemByJellyfinId(item.id!);
    if (existing != null && existing.isCompleted) {
      throw Exception('Item already downloaded');
    }

    // Créer l'ID unique pour ce téléchargement
    final downloadId = _uuid.v4();

    // Obtenir l'URL de téléchargement
    final downloadUrl = _jellyfinService.getDirectDownloadUrl(
      item.id!,
      quality: quality.toDbString(),
    );

    // Créer le chemin de téléchargement
    final filename = '${item.id}.mp4';
    final downloadPath = await _storageService.createDownloadPath(
      item.id!,
      item.type?.value ?? 'unknown',
      filename,
    );

    // Créer l'entrée dans la base de données
    final downloadedItem = DownloadedItem(
      id: downloadId,
      itemId: item.id!,
      itemType: item.type?.value ?? 'unknown',
      title: item.name ?? 'Unknown',
      description: item.overview,
      imageUrl: _getImageUrl(item),
      downloadPath: downloadPath,
      status: DownloadStatus.pending,
      createdAt: DateTime.now(),
      quality: quality,
    );

    await _storageService.insertDownloadedItem(downloadedItem);

    // Obtenir le token d'authentification
    final token = await _jellyfinService.getAccessToken();

    // Créer la tâche de téléchargement
    final task = DownloadTask(
      taskId: downloadId,
      url: downloadUrl,
      filename: filename,
      directory: downloadPath.substring(0, downloadPath.lastIndexOf('/')),
      headers: {
        if (token != null) 'Authorization': 'MediaBrowser Token="$token"',
      },
      updates: Updates.statusAndProgress,
      metaData: downloadId, // Stocker le downloadId dans les métadonnées pour la restauration
    );

    // Enqueue la tâche
    final success = await FileDownloader().enqueue(task);

    if (success) {
      _activeTasks[downloadId] = task;

      // Enregistrer le mapping taskId -> downloadId
      // Note: Le taskId peut être différent après l'enqueue
      _taskIdMapping[task.taskId] = downloadId;

      print('✅ Téléchargement en file d\'attente: ${item.name}');
      print('🔗 Mapping créé: ${task.taskId} -> $downloadId');

      // Afficher la notification
      await _notificationService.showDownloadNotification(downloadedItem);
    } else {
      print('❌ Échec de la mise en file d\'attente');
      throw Exception('Failed to enqueue download');
    }

    return downloadId;
  }

  /// Gère les mises à jour de téléchargement
  Future<void> _handleDownloadUpdate(TaskUpdate update) async {
    final taskId = update.task.taskId;

    // Récupérer le downloadId depuis le mapping
    final downloadId = _taskIdMapping[taskId];

    if (downloadId == null) {
      print('⚠️ Mapping non trouvé pour taskId: $taskId');
      return;
    }

    final item = await _storageService.getDownloadedItem(downloadId);

    if (item == null) {
      print('⚠️ Item non trouvé pour la mise à jour: $downloadId');
      return;
    }

    DownloadedItem updatedItem;

    if (update is TaskStatusUpdate) {
      updatedItem = await _handleStatusUpdate(item, update);
    } else if (update is TaskProgressUpdate) {
      updatedItem = await _handleProgressUpdate(item, update);
    } else {
      return;
    }

    // Mettre à jour la base de données
    await _storageService.updateDownloadedItem(updatedItem);

    // Émettre l'événement de progression
    _progressController.add(updatedItem);

    // Mettre à jour la notification
    await _notificationService.updateDownloadNotification(updatedItem);
  }

  /// Gère les mises à jour de statut
  Future<DownloadedItem> _handleStatusUpdate(
    DownloadedItem item,
    TaskStatusUpdate update,
  ) async {
    print('📊 Mise à jour du statut: ${item.title} -> ${update.status}');

    switch (update.status) {
      case TaskStatus.running:
        return item.copyWith(status: DownloadStatus.downloading);

      case TaskStatus.complete:
        _activeTasks.remove(item.id);
        _taskIdMapping.removeWhere((key, value) => value == item.id);
        return item.copyWith(
          status: DownloadStatus.completed,
          progress: 1.0,
          completedAt: DateTime.now(),
        );

      case TaskStatus.failed:
        _activeTasks.remove(item.id);
        _taskIdMapping.removeWhere((key, value) => value == item.id);
        return item.copyWith(
          status: DownloadStatus.failed,
          errorMessage: update.exception?.toString() ?? 'Unknown error',
        );

      case TaskStatus.paused:
        return item.copyWith(status: DownloadStatus.paused);

      case TaskStatus.canceled:
        _activeTasks.remove(item.id);
        _taskIdMapping.removeWhere((key, value) => value == item.id);
        return item.copyWith(status: DownloadStatus.cancelled);

      default:
        return item;
    }
  }

  /// Gère les mises à jour de progression
  Future<DownloadedItem> _handleProgressUpdate(
    DownloadedItem item,
    TaskProgressUpdate update,
  ) async {
    return item.copyWith(
      progress: update.progress,
      downloadedBytes: (update.progress * item.totalBytes).toInt(),
    );
  }

  /// Pause un téléchargement
  Future<void> pauseDownload(String downloadId) async {
    final task = _activeTasks[downloadId];
    if (task != null) {
      await FileDownloader().pause(task);
      print('⏸️ Téléchargement en pause: $downloadId');
    }
  }

  /// Reprend un téléchargement
  Future<void> resumeDownload(String downloadId) async {
    final task = _activeTasks[downloadId];
    if (task != null) {
      await FileDownloader().resume(task);
      print('▶️ Téléchargement repris: $downloadId');
    } else {
      // Si la tâche n'est pas active, la recréer
      final item = await _storageService.getDownloadedItem(downloadId);
      if (item != null && (item.isPaused || item.isFailed)) {
        // TODO: Recréer la tâche de téléchargement
        print('🔄 Recréation de la tâche de téléchargement');
      }
    }
  }

  /// Annule un téléchargement
  Future<void> cancelDownload(String downloadId) async {
    final task = _activeTasks[downloadId];
    if (task != null) {
      await FileDownloader().cancel(task);
      _activeTasks.remove(downloadId);
      print('❌ Téléchargement annulé: $downloadId');
    }
  }

  /// Supprime un téléchargement
  Future<void> deleteDownload(String downloadId) async {
    await cancelDownload(downloadId);
    await _storageService.deleteDownloadedItem(downloadId);
    await _notificationService.cancelNotification(downloadId.hashCode);
    print('🗑️ Téléchargement supprimé: $downloadId');
  }

  /// Pause tous les téléchargements actifs
  Future<void> _pauseAllActiveDownloads() async {
    for (final downloadId in _activeTasks.keys.toList()) {
      await pauseDownload(downloadId);
    }
  }

  /// Reprend tous les téléchargements en pause
  Future<void> _resumeAllPausedDownloads() async {
    final pausedItems = await _storageService.getDownloadedItemsByStatus(
      DownloadStatus.paused,
    );

    for (final item in pausedItems) {
      await resumeDownload(item.id);
    }
  }

  /// Récupère tous les téléchargements
  Future<List<DownloadedItem>> getAllDownloads() async {
    return await _storageService.getAllDownloadedItems();
  }

  /// Récupère les téléchargements par statut
  Future<List<DownloadedItem>> getDownloadsByStatus(DownloadStatus status) async {
    return await _storageService.getDownloadedItemsByStatus(status);
  }

  /// Récupère les téléchargements actifs
  Future<List<DownloadedItem>> getActiveDownloads() async {
    return await _storageService.getActiveDownloads();
  }

  /// Restaure le mapping des tâches depuis la base de données du package
  Future<void> _restoreTaskMapping() async {
    try {
      // Récupérer tous les enregistrements de tâches depuis la base de données du package
      final records = await FileDownloader().database.allRecords();

      print('🔄 Restauration du mapping pour ${records.length} tâches');

      int restoredCount = 0;
      int orphanedCount = 0;

      for (final record in records) {
        final taskId = record.taskId;
        final task = record.task;

        // Extraire le downloadId depuis les métadonnées
        final downloadId = task.metaData;

        if (downloadId == null || downloadId.isEmpty) {
          print('⚠️ Tâche sans métadonnées: $taskId');
          orphanedCount++;
          // Annuler la tâche orpheline
          await FileDownloader().cancelTaskWithId(taskId);
          continue;
        }

        // Vérifier que l'item existe dans notre base de données
        final item = await _storageService.getDownloadedItem(downloadId);

        if (item == null) {
          print('⚠️ Item non trouvé pour downloadId: $downloadId (taskId: $taskId)');
          orphanedCount++;
          // Annuler la tâche orpheline
          await FileDownloader().cancelTaskWithId(taskId);
          continue;
        }

        // Restaurer le mapping
        _taskIdMapping[taskId] = downloadId;

        // Restaurer la tâche active si elle est en cours
        if (record.status == TaskStatus.running ||
            record.status == TaskStatus.enqueued ||
            record.status == TaskStatus.paused) {
          _activeTasks[downloadId] = task as DownloadTask;
        }

        restoredCount++;
      }

      print('✅ Mapping restauré: $restoredCount tâches, $orphanedCount orphelines nettoyées');
    } catch (e) {
      print('❌ Erreur lors de la restauration du mapping: $e');
    }
  }

  /// Restaure les téléchargements en attente au démarrage
  Future<void> _restorePendingDownloads() async {
    final downloadingItems = await _storageService.getDownloadedItemsByStatus(
      DownloadStatus.downloading,
    );

    print('🔄 Restauration de ${downloadingItems.length} téléchargements');

    for (final item in downloadingItems) {
      // Marquer comme en attente pour reprise
      await _storageService.updateDownloadedItem(
        item.copyWith(status: DownloadStatus.pending),
      );
    }
  }

  /// Obtient l'URL de l'image
  String? _getImageUrl(BaseItemDto item) {
    if (item.id == null) return null;
    final primaryTag = item.imageTags?['Primary'];
    if (primaryTag != null) {
      return _jellyfinService.getImageUrl(item.id!, tag: primaryTag);
    }
    return null;
  }

  /// Nettoie les ressources
  void dispose() {
    _progressController.close();
    _connectivitySubscription?.cancel();
    print('🧹 Service de téléchargement nettoyé');
  }
}

