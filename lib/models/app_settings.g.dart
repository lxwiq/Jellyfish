// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => AppSettings(
      video: VideoPreferences.fromJson(json['video'] as Map<String, dynamic>),
      downloads: DownloadPreferences.fromJson(
          json['downloads'] as Map<String, dynamic>),
      notifications: NotificationPreferences.fromJson(
          json['notifications'] as Map<String, dynamic>),
      interface: InterfacePreferences.fromJson(
          json['interface'] as Map<String, dynamic>),
      servers:
          ServerPreferences.fromJson(json['servers'] as Map<String, dynamic>),
      updates:
          UpdatePreferences.fromJson(json['updates'] as Map<String, dynamic>),
      cache: CachePreferences.fromJson(json['cache'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AppSettingsToJson(AppSettings instance) =>
    <String, dynamic>{
      'video': instance.video,
      'downloads': instance.downloads,
      'notifications': instance.notifications,
      'interface': instance.interface,
      'servers': instance.servers,
      'updates': instance.updates,
      'cache': instance.cache,
    };

VideoPreferences _$VideoPreferencesFromJson(Map<String, dynamic> json) =>
    VideoPreferences(
      defaultQuality: json['defaultQuality'] as String,
      useHls: json['useHls'] as bool,
      preferredAudioLanguage: json['preferredAudioLanguage'] as String?,
      preferredSubtitleLanguage: json['preferredSubtitleLanguage'] as String?,
      enableSubtitlesByDefault: json['enableSubtitlesByDefault'] as bool,
      defaultFitMode: json['defaultFitMode'] as String,
      skipForwardSeconds: (json['skipForwardSeconds'] as num).toInt(),
      skipBackwardSeconds: (json['skipBackwardSeconds'] as num).toInt(),
      defaultPlaybackSpeed: (json['defaultPlaybackSpeed'] as num).toDouble(),
      progressSaveInterval: (json['progressSaveInterval'] as num).toInt(),
    );

Map<String, dynamic> _$VideoPreferencesToJson(VideoPreferences instance) =>
    <String, dynamic>{
      'defaultQuality': instance.defaultQuality,
      'useHls': instance.useHls,
      'preferredAudioLanguage': instance.preferredAudioLanguage,
      'preferredSubtitleLanguage': instance.preferredSubtitleLanguage,
      'enableSubtitlesByDefault': instance.enableSubtitlesByDefault,
      'defaultFitMode': instance.defaultFitMode,
      'skipForwardSeconds': instance.skipForwardSeconds,
      'skipBackwardSeconds': instance.skipBackwardSeconds,
      'defaultPlaybackSpeed': instance.defaultPlaybackSpeed,
      'progressSaveInterval': instance.progressSaveInterval,
    };

DownloadPreferences _$DownloadPreferencesFromJson(Map<String, dynamic> json) =>
    DownloadPreferences(
      defaultQuality:
          $enumDecode(_$DownloadQualityEnumMap, json['defaultQuality']),
      wifiOnly: json['wifiOnly'] as bool,
      pauseOnWifiLoss: json['pauseOnWifiLoss'] as bool,
      resumeOnWifiReconnect: json['resumeOnWifiReconnect'] as bool,
      maxSimultaneousDownloads:
          (json['maxSimultaneousDownloads'] as num).toInt(),
      enableNotifications: json['enableNotifications'] as bool,
      autoCleanupFailed: json['autoCleanupFailed'] as bool,
      deleteAfterWatching: json['deleteAfterWatching'] as bool,
    );

Map<String, dynamic> _$DownloadPreferencesToJson(
        DownloadPreferences instance) =>
    <String, dynamic>{
      'defaultQuality': _$DownloadQualityEnumMap[instance.defaultQuality]!,
      'wifiOnly': instance.wifiOnly,
      'pauseOnWifiLoss': instance.pauseOnWifiLoss,
      'resumeOnWifiReconnect': instance.resumeOnWifiReconnect,
      'maxSimultaneousDownloads': instance.maxSimultaneousDownloads,
      'enableNotifications': instance.enableNotifications,
      'autoCleanupFailed': instance.autoCleanupFailed,
      'deleteAfterWatching': instance.deleteAfterWatching,
    };

const _$DownloadQualityEnumMap = {
  DownloadQuality.original: 'original',
  DownloadQuality.high: 'high',
  DownloadQuality.medium: 'medium',
  DownloadQuality.low: 'low',
};

NotificationPreferences _$NotificationPreferencesFromJson(
        Map<String, dynamic> json) =>
    NotificationPreferences(
      enabled: json['enabled'] as bool,
      downloadProgress: json['downloadProgress'] as bool,
      downloadComplete: json['downloadComplete'] as bool,
      downloadError: json['downloadError'] as bool,
      playSound: json['playSound'] as bool,
      vibrate: json['vibrate'] as bool,
      updateAvailable: json['updateAvailable'] as bool,
    );

Map<String, dynamic> _$NotificationPreferencesToJson(
        NotificationPreferences instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'downloadProgress': instance.downloadProgress,
      'downloadComplete': instance.downloadComplete,
      'downloadError': instance.downloadError,
      'playSound': instance.playSound,
      'vibrate': instance.vibrate,
      'updateAvailable': instance.updateAvailable,
    };

InterfacePreferences _$InterfacePreferencesFromJson(
        Map<String, dynamic> json) =>
    InterfacePreferences(
      showDownloadedBadge: json['showDownloadedBadge'] as bool,
      showProgressBadge: json['showProgressBadge'] as bool,
      enableAnimations: json['enableAnimations'] as bool,
    );

Map<String, dynamic> _$InterfacePreferencesToJson(
        InterfacePreferences instance) =>
    <String, dynamic>{
      'showDownloadedBadge': instance.showDownloadedBadge,
      'showProgressBadge': instance.showProgressBadge,
      'enableAnimations': instance.enableAnimations,
    };

ServerPreferences _$ServerPreferencesFromJson(Map<String, dynamic> json) =>
    ServerPreferences(
      connectionTimeout: (json['connectionTimeout'] as num).toInt(),
    );

Map<String, dynamic> _$ServerPreferencesToJson(ServerPreferences instance) =>
    <String, dynamic>{
      'connectionTimeout': instance.connectionTimeout,
    };

UpdatePreferences _$UpdatePreferencesFromJson(Map<String, dynamic> json) =>
    UpdatePreferences(
      autoCheckOnStartup: json['autoCheckOnStartup'] as bool,
      autoDownload: json['autoDownload'] as bool,
      checkFrequency: json['checkFrequency'] as String,
      notifyAvailable: json['notifyAvailable'] as bool,
    );

Map<String, dynamic> _$UpdatePreferencesToJson(UpdatePreferences instance) =>
    <String, dynamic>{
      'autoCheckOnStartup': instance.autoCheckOnStartup,
      'autoDownload': instance.autoDownload,
      'checkFrequency': instance.checkFrequency,
      'notifyAvailable': instance.notifyAvailable,
    };

CachePreferences _$CachePreferencesFromJson(Map<String, dynamic> json) =>
    CachePreferences(
      maxCacheSizeMB: (json['maxCacheSizeMB'] as num).toInt(),
      cacheRetentionDays: (json['cacheRetentionDays'] as num).toInt(),
    );

Map<String, dynamic> _$CachePreferencesToJson(CachePreferences instance) =>
    <String, dynamic>{
      'maxCacheSizeMB': instance.maxCacheSizeMB,
      'cacheRetentionDays': instance.cacheRetentionDays,
    };
