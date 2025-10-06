import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/downloaded_item.dart';
import '../models/download_status.dart';

/// Service de gestion des notifications pour les téléchargements
class OfflineNotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'downloads';
  static const String _channelName = 'Downloads';
  static const String _channelDescription = 'Notifications for download progress';

  bool _initialized = false;

  /// Initialise le service de notifications
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    final initialized = await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (initialized == true) {
      _initialized = true;
      print('🔔 Service de notifications initialisé');

      // Créer le canal de notification Android
      await _createNotificationChannel();
    } else {
      print('❌ Échec de l\'initialisation des notifications');
    }
  }

  /// Crée le canal de notification pour Android
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Gère le tap sur une notification
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    // TODO: Naviguer vers l'écran des téléchargements
  }

  /// Affiche une notification de téléchargement en cours
  Future<void> showDownloadNotification(DownloadedItem item) async {
    if (!_initialized) {
      print('⚠️ Service de notifications non initialisé');
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: (item.progress * 100).toInt(),
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      icon: '@mipmap/ic_launcher',
      // Actions
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'pause',
          'Pause',
          showsUserInterface: false,
        ),
        const AndroidNotificationAction(
          'cancel',
          'Cancel',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      item.id.hashCode,
      'Downloading ${item.title}',
      _buildProgressText(item),
      details,
      payload: item.id,
    );
  }

  /// Met à jour une notification de téléchargement
  Future<void> updateDownloadNotification(DownloadedItem item) async {
    if (!_initialized) return;

    switch (item.status) {
      case DownloadStatus.downloading:
        await showDownloadNotification(item);
        break;
      case DownloadStatus.completed:
        await _showCompletionNotification(item);
        break;
      case DownloadStatus.failed:
        await _showErrorNotification(item);
        break;
      case DownloadStatus.paused:
        await _showPausedNotification(item);
        break;
      case DownloadStatus.cancelled:
        await cancelNotification(item.id.hashCode);
        break;
      default:
        break;
    }
  }

  /// Affiche une notification de téléchargement en pause
  Future<void> _showPausedNotification(DownloadedItem item) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: (item.progress * 100).toInt(),
      ongoing: false,
      autoCancel: false,
      playSound: false,
      icon: '@mipmap/ic_launcher',
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'resume',
          'Resume',
          showsUserInterface: false,
        ),
        const AndroidNotificationAction(
          'cancel',
          'Cancel',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      item.id.hashCode,
      'Download Paused',
      '${item.title} - ${item.progressPercentage}',
      details,
      payload: item.id,
    );
  }

  /// Affiche une notification de téléchargement terminé
  Future<void> _showCompletionNotification(DownloadedItem item) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'open',
          'Open',
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      item.id.hashCode,
      '✅ Download Complete',
      item.title,
      details,
      payload: item.id,
    );
  }

  /// Affiche une notification d'erreur
  Future<void> _showErrorNotification(DownloadedItem item) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        item.errorMessage ?? 'Unknown error',
      ),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'retry',
          'Retry',
          showsUserInterface: false,
        ),
        const AndroidNotificationAction(
          'dismiss',
          'Dismiss',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      item.id.hashCode,
      '❌ Download Failed',
      '${item.title}: ${item.errorMessage ?? "Unknown error"}',
      details,
      payload: item.id,
    );
  }

  /// Construit le texte de progression
  String _buildProgressText(DownloadedItem item) {
    final parts = <String>[
      item.progressPercentage,
      item.formattedSize,
    ];

    if (item.downloadSpeed != null) {
      parts.add(item.downloadSpeed!);
    }

    if (item.estimatedTimeRemaining != null) {
      parts.add('ETA: ${item.estimatedTimeRemaining}');
    }

    return parts.join(' • ');
  }

  /// Annule une notification
  Future<void> cancelNotification(int id) async {
    if (!_initialized) return;
    await _notifications.cancel(id);
  }

  /// Annule toutes les notifications
  Future<void> cancelAllNotifications() async {
    if (!_initialized) return;
    await _notifications.cancelAll();
  }

  /// Vérifie si les permissions de notification sont accordées
  Future<bool> checkPermissions() async {
    if (!_initialized) return false;

    final androidImpl = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl != null) {
      final granted = await androidImpl.areNotificationsEnabled();
      return granted ?? false;
    }

    final iosImpl = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true; // Desktop platforms
  }

  /// Demande les permissions de notification
  Future<bool> requestPermissions() async {
    if (!_initialized) {
      await initialize();
    }

    return await checkPermissions();
  }
}

