import 'package:json_annotation/json_annotation.dart';
import 'download_status.dart';

part 'app_settings.g.dart';

/// Modèle pour les paramètres de l'application
@JsonSerializable()
class AppSettings {
  // Lecture Vidéo
  final VideoPreferences video;
  
  // Téléchargements
  final DownloadPreferences downloads;
  
  // Notifications
  final NotificationPreferences notifications;
  
  // Interface
  final InterfacePreferences interface;
  
  // Serveurs
  final ServerPreferences servers;
  
  // Mises à jour
  final UpdatePreferences updates;
  
  // Cache
  final CachePreferences cache;

  const AppSettings({
    required this.video,
    required this.downloads,
    required this.notifications,
    required this.interface,
    required this.servers,
    required this.updates,
    required this.cache,
  });

  factory AppSettings.defaults() {
    return AppSettings(
      video: VideoPreferences.defaults(),
      downloads: DownloadPreferences.defaults(),
      notifications: NotificationPreferences.defaults(),
      interface: InterfacePreferences.defaults(),
      servers: ServerPreferences.defaults(),
      updates: UpdatePreferences.defaults(),
      cache: CachePreferences.defaults(),
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$AppSettingsToJson(this);

  AppSettings copyWith({
    VideoPreferences? video,
    DownloadPreferences? downloads,
    NotificationPreferences? notifications,
    InterfacePreferences? interface,
    ServerPreferences? servers,
    UpdatePreferences? updates,
    CachePreferences? cache,
  }) {
    return AppSettings(
      video: video ?? this.video,
      downloads: downloads ?? this.downloads,
      notifications: notifications ?? this.notifications,
      interface: interface ?? this.interface,
      servers: servers ?? this.servers,
      updates: updates ?? this.updates,
      cache: cache ?? this.cache,
    );
  }
}

/// Préférences de lecture vidéo
@JsonSerializable()
class VideoPreferences {
  final String defaultQuality; // 'auto', '4k_40', '1080p_20', '1080p_10', '720p_8', '720p_4', '480p_3', '480p_1.5'
  final bool useHls; // true = HLS, false = Direct Play
  final String? preferredAudioLanguage; // Code langue ISO (ex: 'fra', 'eng')
  final String? preferredSubtitleLanguage;
  final bool enableSubtitlesByDefault;
  final String defaultFitMode; // 'contain', 'cover', 'fill', 'fit'
  final int skipForwardSeconds; // 5-60
  final int skipBackwardSeconds; // 5-60
  final double defaultPlaybackSpeed; // 0.5-2.0
  final int progressSaveInterval; // Intervalle de sauvegarde de la progression en secondes (5-60)

  const VideoPreferences({
    required this.defaultQuality,
    required this.useHls,
    this.preferredAudioLanguage,
    this.preferredSubtitleLanguage,
    required this.enableSubtitlesByDefault,
    required this.defaultFitMode,
    required this.skipForwardSeconds,
    required this.skipBackwardSeconds,
    required this.defaultPlaybackSpeed,
    required this.progressSaveInterval,
  });

  factory VideoPreferences.defaults() {
    return const VideoPreferences(
      defaultQuality: 'auto',
      useHls: false,
      preferredAudioLanguage: null,
      preferredSubtitleLanguage: null,
      enableSubtitlesByDefault: false,
      defaultFitMode: 'contain',
      skipForwardSeconds: 10,
      skipBackwardSeconds: 10,
      defaultPlaybackSpeed: 1.0,
      progressSaveInterval: 5, // Sauvegarder toutes les 5 secondes par défaut
    );
  }

  factory VideoPreferences.fromJson(Map<String, dynamic> json) {
    // Migration: ajouter progressSaveInterval si absent
    if (!json.containsKey('progressSaveInterval')) {
      json['progressSaveInterval'] = 5; // Valeur par défaut
    }
    return _$VideoPreferencesFromJson(json);
  }

  Map<String, dynamic> toJson() => _$VideoPreferencesToJson(this);

  VideoPreferences copyWith({
    String? defaultQuality,
    bool? useHls,
    String? preferredAudioLanguage,
    String? preferredSubtitleLanguage,
    bool? enableSubtitlesByDefault,
    String? defaultFitMode,
    int? skipForwardSeconds,
    int? skipBackwardSeconds,
    double? defaultPlaybackSpeed,
    int? progressSaveInterval,
  }) {
    return VideoPreferences(
      defaultQuality: defaultQuality ?? this.defaultQuality,
      useHls: useHls ?? this.useHls,
      preferredAudioLanguage: preferredAudioLanguage ?? this.preferredAudioLanguage,
      preferredSubtitleLanguage: preferredSubtitleLanguage ?? this.preferredSubtitleLanguage,
      enableSubtitlesByDefault: enableSubtitlesByDefault ?? this.enableSubtitlesByDefault,
      defaultFitMode: defaultFitMode ?? this.defaultFitMode,
      skipForwardSeconds: skipForwardSeconds ?? this.skipForwardSeconds,
      skipBackwardSeconds: skipBackwardSeconds ?? this.skipBackwardSeconds,
      defaultPlaybackSpeed: defaultPlaybackSpeed ?? this.defaultPlaybackSpeed,
      progressSaveInterval: progressSaveInterval ?? this.progressSaveInterval,
    );
  }
}

/// Préférences de téléchargement
@JsonSerializable()
class DownloadPreferences {
  final DownloadQuality defaultQuality;
  final bool wifiOnly;
  final bool pauseOnWifiLoss;
  final bool resumeOnWifiReconnect;
  final int maxSimultaneousDownloads; // 1-5
  final bool enableNotifications;
  final bool autoCleanupFailed;
  final bool deleteAfterWatching;

  const DownloadPreferences({
    required this.defaultQuality,
    required this.wifiOnly,
    required this.pauseOnWifiLoss,
    required this.resumeOnWifiReconnect,
    required this.maxSimultaneousDownloads,
    required this.enableNotifications,
    required this.autoCleanupFailed,
    required this.deleteAfterWatching,
  });

  factory DownloadPreferences.defaults() {
    return const DownloadPreferences(
      defaultQuality: DownloadQuality.high,
      wifiOnly: true,
      pauseOnWifiLoss: true,
      resumeOnWifiReconnect: true,
      maxSimultaneousDownloads: 2,
      enableNotifications: true,
      autoCleanupFailed: false,
      deleteAfterWatching: false,
    );
  }

  factory DownloadPreferences.fromJson(Map<String, dynamic> json) =>
      _$DownloadPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$DownloadPreferencesToJson(this);

  DownloadPreferences copyWith({
    DownloadQuality? defaultQuality,
    bool? wifiOnly,
    bool? pauseOnWifiLoss,
    bool? resumeOnWifiReconnect,
    int? maxSimultaneousDownloads,
    bool? enableNotifications,
    bool? autoCleanupFailed,
    bool? deleteAfterWatching,
  }) {
    return DownloadPreferences(
      defaultQuality: defaultQuality ?? this.defaultQuality,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      pauseOnWifiLoss: pauseOnWifiLoss ?? this.pauseOnWifiLoss,
      resumeOnWifiReconnect: resumeOnWifiReconnect ?? this.resumeOnWifiReconnect,
      maxSimultaneousDownloads: maxSimultaneousDownloads ?? this.maxSimultaneousDownloads,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      autoCleanupFailed: autoCleanupFailed ?? this.autoCleanupFailed,
      deleteAfterWatching: deleteAfterWatching ?? this.deleteAfterWatching,
    );
  }
}

/// Préférences de notifications
@JsonSerializable()
class NotificationPreferences {
  final bool enabled;
  final bool downloadProgress;
  final bool downloadComplete;
  final bool downloadError;
  final bool playSound;
  final bool vibrate;
  final bool updateAvailable;

  const NotificationPreferences({
    required this.enabled,
    required this.downloadProgress,
    required this.downloadComplete,
    required this.downloadError,
    required this.playSound,
    required this.vibrate,
    required this.updateAvailable,
  });

  factory NotificationPreferences.defaults() {
    return const NotificationPreferences(
      enabled: true,
      downloadProgress: true,
      downloadComplete: true,
      downloadError: true,
      playSound: true,
      vibrate: true,
      updateAvailable: true,
    );
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationPreferencesToJson(this);

  NotificationPreferences copyWith({
    bool? enabled,
    bool? downloadProgress,
    bool? downloadComplete,
    bool? downloadError,
    bool? playSound,
    bool? vibrate,
    bool? updateAvailable,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadComplete: downloadComplete ?? this.downloadComplete,
      downloadError: downloadError ?? this.downloadError,
      playSound: playSound ?? this.playSound,
      vibrate: vibrate ?? this.vibrate,
      updateAvailable: updateAvailable ?? this.updateAvailable,
    );
  }
}

/// Préférences d'interface
@JsonSerializable()
class InterfacePreferences {
  final bool showDownloadedBadge;
  final bool showProgressBadge;
  final bool enableAnimations;

  const InterfacePreferences({
    required this.showDownloadedBadge,
    required this.showProgressBadge,
    required this.enableAnimations,
  });

  factory InterfacePreferences.defaults() {
    return const InterfacePreferences(
      showDownloadedBadge: true,
      showProgressBadge: true,
      enableAnimations: true,
    );
  }

  factory InterfacePreferences.fromJson(Map<String, dynamic> json) =>
      _$InterfacePreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$InterfacePreferencesToJson(this);

  InterfacePreferences copyWith({
    bool? showDownloadedBadge,
    bool? showProgressBadge,
    bool? enableAnimations,
  }) {
    return InterfacePreferences(
      showDownloadedBadge: showDownloadedBadge ?? this.showDownloadedBadge,
      showProgressBadge: showProgressBadge ?? this.showProgressBadge,
      enableAnimations: enableAnimations ?? this.enableAnimations,
    );
  }
}

/// Préférences serveurs
@JsonSerializable()
class ServerPreferences {
  final int connectionTimeout; // 5-60 secondes

  const ServerPreferences({
    required this.connectionTimeout,
  });

  factory ServerPreferences.defaults() {
    return const ServerPreferences(
      connectionTimeout: 30,
    );
  }

  factory ServerPreferences.fromJson(Map<String, dynamic> json) =>
      _$ServerPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$ServerPreferencesToJson(this);

  ServerPreferences copyWith({
    int? connectionTimeout,
  }) {
    return ServerPreferences(
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
    );
  }
}

/// Préférences de mises à jour
@JsonSerializable()
class UpdatePreferences {
  final bool autoCheckOnStartup;
  final bool autoDownload;
  final String checkFrequency; // 'never', 'daily', 'weekly'
  final bool notifyAvailable;

  const UpdatePreferences({
    required this.autoCheckOnStartup,
    required this.autoDownload,
    required this.checkFrequency,
    required this.notifyAvailable,
  });

  factory UpdatePreferences.defaults() {
    return const UpdatePreferences(
      autoCheckOnStartup: true,
      autoDownload: false,
      checkFrequency: 'daily',
      notifyAvailable: true,
    );
  }

  factory UpdatePreferences.fromJson(Map<String, dynamic> json) =>
      _$UpdatePreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$UpdatePreferencesToJson(this);

  UpdatePreferences copyWith({
    bool? autoCheckOnStartup,
    bool? autoDownload,
    String? checkFrequency,
    bool? notifyAvailable,
  }) {
    return UpdatePreferences(
      autoCheckOnStartup: autoCheckOnStartup ?? this.autoCheckOnStartup,
      autoDownload: autoDownload ?? this.autoDownload,
      checkFrequency: checkFrequency ?? this.checkFrequency,
      notifyAvailable: notifyAvailable ?? this.notifyAvailable,
    );
  }
}

/// Préférences de cache
@JsonSerializable()
class CachePreferences {
  final int maxCacheSizeMB; // 100-2000 MB
  final int cacheRetentionDays; // 7, 14, 30

  const CachePreferences({
    required this.maxCacheSizeMB,
    required this.cacheRetentionDays,
  });

  factory CachePreferences.defaults() {
    return const CachePreferences(
      maxCacheSizeMB: 500,
      cacheRetentionDays: 7,
    );
  }

  factory CachePreferences.fromJson(Map<String, dynamic> json) =>
      _$CachePreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$CachePreferencesToJson(this);

  CachePreferences copyWith({
    int? maxCacheSizeMB,
    int? cacheRetentionDays,
  }) {
    return CachePreferences(
      maxCacheSizeMB: maxCacheSizeMB ?? this.maxCacheSizeMB,
      cacheRetentionDays: cacheRetentionDays ?? this.cacheRetentionDays,
    );
  }
}

