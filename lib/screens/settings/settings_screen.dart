import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/services_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/offline_download_provider.dart';
import '../../services/update_service.dart';
import '../../services/native_update_service.dart';
import '../../services/custom_cache_manager.dart';
import '../../models/download_status.dart';
import '../onboarding_screen.dart';
import 'widgets/setting_section.dart';
import 'widgets/setting_tile.dart';
import 'widgets/setting_switch.dart';
import 'widgets/setting_slider.dart';
import 'widgets/setting_button.dart';
import 'widgets/storage_bar.dart';
import 'native_update_dialog.dart';

/// Écran des paramètres de l'application
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  PackageInfo? _packageInfo;
  bool _isCheckingUpdate = false;
  bool _isClearingCache = false;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final storageService = ref.watch(storageServiceProvider);
    final settingsAsync = ref.watch(appSettingsProvider);
    final downloadStats = ref.watch(downloadStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background1,
      appBar: AppBar(
        backgroundColor: AppColors.background2,
        foregroundColor: AppColors.text6,
        elevation: 0,
        title: const Text(
          'Paramètres',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.text6,
          ),
        ),
      ),
      body: settingsAsync.when(
        data: (settings) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Section Compte
            _buildAccountSection(authState, storageService),
            
            // Section Serveurs
            _buildServersSection(storageService, settings),
            
            // Section Lecture Vidéo
            _buildVideoSection(settings),
            
            // Section Téléchargements
            _buildDownloadsSection(settings),
            
            // Section Stockage & Cache
            _buildStorageSection(downloadStats),
            
            // Section Notifications
            _buildNotificationsSection(settings),
            
            // Section Interface
            _buildInterfaceSection(settings),
            
            // Section Mises à jour
            _buildUpdatesSection(settings),
            
            // Section Avancé
            _buildAdvancedSection(storageService),
            
            const SizedBox(height: 32),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.jellyfinPurple,
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                IconsaxPlusLinear.danger,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: const TextStyle(
                  color: AppColors.text6,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(
                  color: AppColors.text4,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== SECTION COMPTE ==========
  Widget _buildAccountSection(authState, storageService) {
    return SettingSection(
      title: 'Compte',
      icon: IconsaxPlusLinear.user,
      children: [
        SettingTile(
          icon: IconsaxPlusLinear.user,
          label: 'Utilisateur',
          value: authState.user?.name ?? 'Non connecté',
        ),
        if (authState.user?.email != null)
          SettingTile(
            icon: IconsaxPlusLinear.sms,
            label: 'Email',
            value: authState.user!.email!,
          ),
        SettingTile(
          icon: authState.user?.isAdmin == true
              ? IconsaxPlusLinear.shield_tick
              : IconsaxPlusLinear.user,
          label: 'Rôle',
          value: authState.user?.isAdmin == true ? 'Administrateur' : 'Utilisateur',
        ),
        SettingButton(
          icon: IconsaxPlusLinear.logout,
          label: 'Déconnexion',
          subtitle: 'Se déconnecter et revenir à l\'écran de connexion',
          isDanger: true,
          onPressed: () => _handleLogout(),
        ),
      ],
    );
  }

  // ========== SECTION SERVEURS ==========
  Widget _buildServersSection(storageService, settings) {
    final serverUrl = storageService.getServerUrl();
    final jellyseerrUrl = storageService.getJellyseerrServerUrl();
    final deviceId = storageService.getOrCreateDeviceId();

    return SettingSection(
      title: 'Serveurs',
      icon: IconsaxPlusLinear.global,
      children: [
        SettingTile(
          icon: IconsaxPlusLinear.link,
          label: 'Serveur Jellyfin',
          value: serverUrl ?? 'Non configuré',
          onTap: () => _showEditServerDialog(context, 'Jellyfin', serverUrl),
        ),
        if (jellyseerrUrl != null)
          SettingTile(
            icon: IconsaxPlusLinear.link_2,
            label: 'Serveur Jellyseerr',
            value: jellyseerrUrl,
            onTap: () => _showEditServerDialog(context, 'Jellyseerr', jellyseerrUrl),
          ),
        SettingSlider(
          icon: IconsaxPlusLinear.timer_1,
          label: 'Timeout de connexion',
          subtitle: 'Délai d\'attente pour les requêtes réseau',
          value: settings.servers.connectionTimeout.toDouble(),
          min: 5,
          max: 60,
          divisions: 11,
          valueFormatter: (value) => '${value.toInt()}s',
          onChanged: (value) {
            final newPrefs = settings.servers.copyWith(
              connectionTimeout: value.toInt(),
            );
            ref.read(appSettingsProvider.notifier).updateServerPreferences(newPrefs);
          },
        ),
        SettingTile(
          icon: IconsaxPlusLinear.mobile,
          label: 'ID de l\'appareil',
          value: '${deviceId.substring(0, 8)}...',
          subtitle: 'Identifiant unique de cet appareil',
          onTap: () {
            Clipboard.setData(ClipboardData(text: deviceId));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ID copié dans le presse-papiers'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }

  // ========== SECTION LECTURE VIDÉO ==========
  Widget _buildVideoSection(settings) {
    return SettingSection(
      title: 'Lecture Vidéo',
      icon: IconsaxPlusLinear.video_play,
      children: [
        SettingTile(
          icon: IconsaxPlusLinear.video,
          label: 'Qualité par défaut',
          value: _getQualityLabel(settings.video.defaultQuality),
          onTap: () => _showQualityDialog(settings),
        ),
        SettingSwitch(
          icon: IconsaxPlusLinear.video_square,
          label: 'Mode HLS',
          subtitle: 'Utiliser HLS au lieu du Direct Play',
          value: settings.video.useHls,
          onChanged: (value) {
            final newPrefs = settings.video.copyWith(useHls: value);
            ref.read(appSettingsProvider.notifier).updateVideoPreferences(newPrefs);
          },
        ),
        SettingTile(
          icon: IconsaxPlusLinear.volume_high,
          label: 'Langue audio préférée',
          value: settings.video.preferredAudioLanguage ?? 'Défaut du serveur',
          onTap: () => _showAudioLanguageDialog(settings),
        ),
        SettingSwitch(
          icon: IconsaxPlusLinear.subtitle,
          label: 'Sous-titres par défaut',
          subtitle: 'Activer automatiquement les sous-titres',
          value: settings.video.enableSubtitlesByDefault,
          onChanged: (value) {
            final newPrefs = settings.video.copyWith(enableSubtitlesByDefault: value);
            ref.read(appSettingsProvider.notifier).updateVideoPreferences(newPrefs);
          },
        ),
        if (settings.video.enableSubtitlesByDefault)
          SettingTile(
            icon: IconsaxPlusLinear.subtitle,
            label: 'Langue sous-titres préférée',
            value: settings.video.preferredSubtitleLanguage ?? 'Défaut du serveur',
            onTap: () => _showSubtitleLanguageDialog(settings),
          ),
        SettingSlider(
          icon: IconsaxPlusLinear.forward,
          label: 'Saut avant',
          subtitle: 'Durée du saut en avant',
          value: settings.video.skipForwardSeconds.toDouble(),
          min: 5,
          max: 60,
          divisions: 11,
          valueFormatter: (value) => '${value.toInt()}s',
          onChanged: (value) {
            final newPrefs = settings.video.copyWith(skipForwardSeconds: value.toInt());
            ref.read(appSettingsProvider.notifier).updateVideoPreferences(newPrefs);
          },
        ),
        SettingSlider(
          icon: IconsaxPlusLinear.backward,
          label: 'Saut arrière',
          subtitle: 'Durée du saut en arrière',
          value: settings.video.skipBackwardSeconds.toDouble(),
          min: 5,
          max: 60,
          divisions: 11,
          valueFormatter: (value) => '${value.toInt()}s',
          onChanged: (value) {
            final newPrefs = settings.video.copyWith(skipBackwardSeconds: value.toInt());
            ref.read(appSettingsProvider.notifier).updateVideoPreferences(newPrefs);
          },
        ),
        SettingSlider(
          icon: IconsaxPlusLinear.clock,
          label: 'Intervalle de sauvegarde',
          subtitle: 'Fréquence de sauvegarde de la progression',
          value: settings.video.progressSaveInterval.toDouble(),
          min: 5,
          max: 60,
          divisions: 11,
          valueFormatter: (value) => '${value.toInt()}s',
          onChanged: (value) {
            final newPrefs = settings.video.copyWith(progressSaveInterval: value.toInt());
            ref.read(appSettingsProvider.notifier).updateVideoPreferences(newPrefs);
          },
        ),
      ],
    );
  }

  // ========== SECTION TÉLÉCHARGEMENTS ==========
  Widget _buildDownloadsSection(settings) {
    return SettingSection(
      title: 'Téléchargements',
      icon: IconsaxPlusLinear.document_download,
      children: [
        SettingTile(
          icon: IconsaxPlusLinear.video,
          label: 'Qualité par défaut',
          value: settings.downloads.defaultQuality.label,
          onTap: () => _showDownloadQualityDialog(settings),
        ),
        SettingSwitch(
          icon: IconsaxPlusLinear.wifi,
          label: 'WiFi uniquement',
          subtitle: 'Télécharger uniquement en WiFi',
          value: settings.downloads.wifiOnly,
          onChanged: (value) {
            final newPrefs = settings.downloads.copyWith(wifiOnly: value);
            ref.read(appSettingsProvider.notifier).updateDownloadPreferences(newPrefs);
          },
        ),
        SettingSwitch(
          icon: IconsaxPlusLinear.pause,
          label: 'Pause si perte WiFi',
          subtitle: 'Mettre en pause automatiquement',
          value: settings.downloads.pauseOnWifiLoss,
          onChanged: (value) {
            final newPrefs = settings.downloads.copyWith(pauseOnWifiLoss: value);
            ref.read(appSettingsProvider.notifier).updateDownloadPreferences(newPrefs);
          },
        ),
        SettingSwitch(
          icon: IconsaxPlusLinear.play,
          label: 'Reprendre si WiFi retrouvé',
          subtitle: 'Reprendre automatiquement',
          value: settings.downloads.resumeOnWifiReconnect,
          onChanged: (value) {
            final newPrefs = settings.downloads.copyWith(resumeOnWifiReconnect: value);
            ref.read(appSettingsProvider.notifier).updateDownloadPreferences(newPrefs);
          },
        ),
        SettingSlider(
          icon: IconsaxPlusLinear.layer,
          label: 'Téléchargements simultanés',
          subtitle: 'Nombre maximum de téléchargements en parallèle',
          value: settings.downloads.maxSimultaneousDownloads.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          onChanged: (value) {
            final newPrefs = settings.downloads.copyWith(
              maxSimultaneousDownloads: value.toInt(),
            );
            ref.read(appSettingsProvider.notifier).updateDownloadPreferences(newPrefs);
          },
        ),
        SettingSwitch(
          icon: IconsaxPlusLinear.notification,
          label: 'Notifications',
          subtitle: 'Afficher les notifications de téléchargement',
          value: settings.downloads.enableNotifications,
          onChanged: (value) {
            final newPrefs = settings.downloads.copyWith(enableNotifications: value);
            ref.read(appSettingsProvider.notifier).updateDownloadPreferences(newPrefs);
          },
        ),
        SettingSwitch(
          icon: IconsaxPlusLinear.broom,
          label: 'Nettoyage automatique',
          subtitle: 'Supprimer automatiquement les téléchargements échoués',
          value: settings.downloads.autoCleanupFailed,
          onChanged: (value) {
            final newPrefs = settings.downloads.copyWith(autoCleanupFailed: value);
            ref.read(appSettingsProvider.notifier).updateDownloadPreferences(newPrefs);
          },
        ),
      ],
    );
  }

  // ========== SECTION STOCKAGE & CACHE ==========
  Widget _buildStorageSection(AsyncValue<DownloadStats> downloadStats) {
    return SettingSection(
      title: 'Stockage & Cache',
      icon: IconsaxPlusLinear.folder,
      children: [
        downloadStats.when(
          data: (stats) => Column(
            children: [
              StorageBar(
                label: 'Téléchargements',
                usedBytes: stats.totalSpaceUsed,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatChip(
                      'Complétés',
                      stats.completedCount.toString(),
                      IconsaxPlusLinear.tick_circle,
                      AppColors.success,
                    ),
                    _buildStatChip(
                      'Actifs',
                      stats.activeCount.toString(),
                      IconsaxPlusLinear.refresh,
                      AppColors.jellyfinPurple,
                    ),
                    _buildStatChip(
                      'Échoués',
                      stats.failedCount.toString(),
                      IconsaxPlusLinear.danger,
                      AppColors.error,
                    ),
                  ],
                ),
              ),
            ],
          ),
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.jellyfinPurple,
                strokeWidth: 2,
              ),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
        SettingButton(
          icon: IconsaxPlusLinear.broom,
          label: 'Vider le cache d\'images',
          subtitle: 'Libérer de l\'espace en supprimant les images en cache',
          isLoading: _isClearingCache,
          onPressed: () => _clearImageCache(),
        ),
        SettingButton(
          icon: IconsaxPlusLinear.trash,
          label: 'Nettoyer les téléchargements échoués',
          subtitle: 'Supprimer tous les téléchargements en erreur',
          onPressed: () => _cleanupFailedDownloads(),
        ),
        SettingButton(
          icon: IconsaxPlusLinear.danger,
          label: 'Supprimer tous les téléchargements',
          subtitle: 'Supprimer tous les fichiers téléchargés',
          isDanger: true,
          onPressed: () => _deleteAllDownloads(),
        ),
      ],
    );
  }

  // ========== SECTION NOTIFICATIONS ==========
  Widget _buildNotificationsSection(settings) {
    return SettingSection(
      title: 'Notifications',
      icon: IconsaxPlusLinear.notification,
      children: [
        SettingSwitch(
          icon: IconsaxPlusLinear.notification,
          label: 'Activer les notifications',
          subtitle: 'Autoriser l\'application à envoyer des notifications',
          value: settings.notifications.enabled,
          onChanged: (value) {
            final newPrefs = settings.notifications.copyWith(enabled: value);
            ref.read(appSettingsProvider.notifier).updateNotificationPreferences(newPrefs);
          },
        ),
        if (settings.notifications.enabled) ...[
          SettingSwitch(
            icon: IconsaxPlusLinear.refresh,
            label: 'Progression des téléchargements',
            value: settings.notifications.downloadProgress,
            onChanged: (value) {
              final newPrefs = settings.notifications.copyWith(downloadProgress: value);
              ref.read(appSettingsProvider.notifier).updateNotificationPreferences(newPrefs);
            },
          ),
          SettingSwitch(
            icon: IconsaxPlusLinear.tick_circle,
            label: 'Téléchargement terminé',
            value: settings.notifications.downloadComplete,
            onChanged: (value) {
              final newPrefs = settings.notifications.copyWith(downloadComplete: value);
              ref.read(appSettingsProvider.notifier).updateNotificationPreferences(newPrefs);
            },
          ),
          SettingSwitch(
            icon: IconsaxPlusLinear.danger,
            label: 'Erreurs de téléchargement',
            value: settings.notifications.downloadError,
            onChanged: (value) {
              final newPrefs = settings.notifications.copyWith(downloadError: value);
              ref.read(appSettingsProvider.notifier).updateNotificationPreferences(newPrefs);
            },
          ),
          SettingSwitch(
            icon: IconsaxPlusLinear.volume_high,
            label: 'Son',
            value: settings.notifications.playSound,
            onChanged: (value) {
              final newPrefs = settings.notifications.copyWith(playSound: value);
              ref.read(appSettingsProvider.notifier).updateNotificationPreferences(newPrefs);
            },
          ),
          SettingSwitch(
            icon: IconsaxPlusLinear.mobile,
            label: 'Vibration',
            value: settings.notifications.vibrate,
            onChanged: (value) {
              final newPrefs = settings.notifications.copyWith(vibrate: value);
              ref.read(appSettingsProvider.notifier).updateNotificationPreferences(newPrefs);
            },
          ),
        ],
      ],
    );
  }

  // ========== SECTION INTERFACE ==========
  Widget _buildInterfaceSection(settings) {
    return SettingSection(
      title: 'Interface',
      icon: IconsaxPlusLinear.brush,
      children: [
        SettingSwitch(
          icon: IconsaxPlusLinear.document_download,
          label: 'Badge "Téléchargé"',
          subtitle: 'Afficher un badge sur les contenus téléchargés',
          value: settings.interface.showDownloadedBadge,
          onChanged: (value) {
            final newPrefs = settings.interface.copyWith(showDownloadedBadge: value);
            ref.read(appSettingsProvider.notifier).updateInterfacePreferences(newPrefs);
          },
        ),
        SettingSwitch(
          icon: IconsaxPlusLinear.chart,
          label: 'Badge de progression',
          subtitle: 'Afficher la progression de visionnage',
          value: settings.interface.showProgressBadge,
          onChanged: (value) {
            final newPrefs = settings.interface.copyWith(showProgressBadge: value);
            ref.read(appSettingsProvider.notifier).updateInterfacePreferences(newPrefs);
          },
        ),
        SettingSwitch(
          icon: IconsaxPlusLinear.magic_star,
          label: 'Animations',
          subtitle: 'Activer les animations de l\'interface',
          value: settings.interface.enableAnimations,
          onChanged: (value) {
            final newPrefs = settings.interface.copyWith(enableAnimations: value);
            ref.read(appSettingsProvider.notifier).updateInterfacePreferences(newPrefs);
          },
        ),
      ],
    );
  }

  // ========== SECTION MISES À JOUR ==========
  Widget _buildUpdatesSection(settings) {
    return SettingSection(
      title: 'Mises à jour',
      icon: IconsaxPlusLinear.refresh,
      children: [
        SettingTile(
          icon: IconsaxPlusLinear.code,
          label: 'Version',
          value: _packageInfo != null
              ? '${_packageInfo!.version} (${_packageInfo!.buildNumber})'
              : 'Chargement...',
        ),
        SettingSwitch(
          icon: IconsaxPlusLinear.refresh,
          label: 'Vérification automatique',
          subtitle: 'Vérifier les mises à jour au démarrage',
          value: settings.updates.autoCheckOnStartup,
          onChanged: (value) {
            final newPrefs = settings.updates.copyWith(autoCheckOnStartup: value);
            ref.read(appSettingsProvider.notifier).updateUpdatePreferences(newPrefs);
          },
        ),
        SettingSwitch(
          icon: IconsaxPlusLinear.notification,
          label: 'Notifier si disponible',
          subtitle: 'Afficher une notification si une mise à jour est disponible',
          value: settings.updates.notifyAvailable,
          onChanged: (value) {
            final newPrefs = settings.updates.copyWith(notifyAvailable: value);
            ref.read(appSettingsProvider.notifier).updateUpdatePreferences(newPrefs);
          },
        ),
        SettingButton(
          icon: IconsaxPlusLinear.refresh,
          label: 'Vérifier maintenant',
          subtitle: 'Rechercher les mises à jour disponibles',
          isLoading: _isCheckingUpdate,
          onPressed: () => _checkForUpdates(),
        ),
      ],
    );
  }

  // ========== SECTION AVANCÉ ==========
  Widget _buildAdvancedSection(storageService) {
    final deviceId = storageService.getOrCreateDeviceId();

    return SettingSection(
      title: 'Avancé',
      icon: IconsaxPlusLinear.setting_2,
      children: [
        SettingTile(
          icon: IconsaxPlusLinear.mobile,
          label: 'ID de l\'appareil',
          value: '${deviceId.substring(0, 12)}...',
          subtitle: 'Appuyez pour copier l\'ID complet',
          onTap: () {
            Clipboard.setData(ClipboardData(text: deviceId));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ID complet copié dans le presse-papiers'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        SettingButton(
          icon: IconsaxPlusLinear.refresh_2,
          label: 'Réinitialiser les paramètres',
          subtitle: 'Restaurer tous les paramètres par défaut',
          isDanger: true,
          onPressed: () => _resetSettings(),
        ),
        SettingTile(
          icon: IconsaxPlusLinear.info_circle,
          label: 'À propos',
          value: 'Jellyfish',
          subtitle: 'Client Jellyfin pour Flutter',
        ),
      ],
    );
  }

  // ========== WIDGETS HELPER ==========

  Widget _buildStatChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.text4,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ========== MÉTHODES HELPER ==========

  String _getQualityLabel(String quality) {
    switch (quality) {
      case 'auto':
        return 'Auto';
      case '4k_40':
        return '4K (40 Mbps)';
      case '1080p_20':
        return '1080p (20 Mbps)';
      case '1080p_10':
        return '1080p (10 Mbps)';
      case '720p_8':
        return '720p (8 Mbps)';
      case '720p_4':
        return '720p (4 Mbps)';
      case '480p_3':
        return '480p (3 Mbps)';
      case '480p_1.5':
        return '480p (1.5 Mbps)';
      default:
        return 'Auto';
    }
  }

  // ========== ACTIONS ==========

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background3,
        title: const Text(
          'Déconnexion',
          style: TextStyle(color: AppColors.text6),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: TextStyle(color: AppColors.text4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authStateProvider.notifier).logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _clearImageCache() async {
    setState(() {
      _isClearingCache = true;
    });

    try {
      await CustomCacheManager().emptyCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache d\'images vidé avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isClearingCache = false;
        });
      }
    }
  }

  Future<void> _cleanupFailedDownloads() async {
    final storageService = ref.read(offlineStorageServiceProvider);
    try {
      await storageService.cleanupFailedDownloads();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Téléchargements échoués nettoyés'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(downloadStatsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteAllDownloads() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background3,
        title: const Text(
          'Supprimer tous les téléchargements',
          style: TextStyle(color: AppColors.error),
        ),
        content: const Text(
          'Cette action est irréversible. Tous les fichiers téléchargés seront supprimés.',
          style: TextStyle(color: AppColors.text4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer tout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final storageService = ref.read(offlineStorageServiceProvider);
      try {
        await storageService.deleteAllDownloads();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tous les téléchargements ont été supprimés'),
              backgroundColor: AppColors.success,
            ),
          );
          ref.invalidate(downloadStatsProvider);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingUpdate = true;
    });

    try {
      // 1. Vérifier les mises à jour Shorebird (code push)
      final updateService = UpdateService.instance;
      bool shorebirdUpdateFound = false;

      await for (final status in updateService.checkAndDownloadUpdates()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Shorebird: ${status.message}'),
              duration: const Duration(seconds: 2),
            ),
          );
          if (status.message.contains('prête')) {
            shorebirdUpdateFound = true;
          }
        }
      }

      // 2. Vérifier les mises à jour natives (GitHub Releases)
      final nativeUpdateService = NativeUpdateService.instance;
      final release = await nativeUpdateService.checkForUpdate();

      if (mounted) {
        if (release != null) {
          // Afficher le dialog de mise à jour native
          showDialog(
            context: context,
            builder: (context) => NativeUpdateDialog(release: release),
          );
        } else if (!shorebirdUpdateFound) {
          // Aucune mise à jour disponible
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Application à jour'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
        });
      }
    }
  }

  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background3,
        title: const Text(
          'Réinitialiser les paramètres',
          style: TextStyle(color: AppColors.error),
        ),
        content: const Text(
          'Tous les paramètres seront restaurés à leurs valeurs par défaut.',
          style: TextStyle(color: AppColors.text4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(appSettingsProvider.notifier).resetToDefaults();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres réinitialisés'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  // ========== DIALOGUES ==========

  Future<void> _showEditServerDialog(BuildContext context, String serverType, String? currentUrl) async {
    final controller = TextEditingController(text: currentUrl);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background3,
        title: Text(
          'Serveur $serverType',
          style: const TextStyle(color: AppColors.text6),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'URL du serveur',
            hintText: 'https://...',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: AppColors.surface1,
          ),
          style: const TextStyle(color: AppColors.text6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final storageService = ref.read(storageServiceProvider);
      if (serverType == 'Jellyfin') {
        await storageService.saveServerUrl(result);
      } else if (serverType == 'Jellyseerr') {
        await storageService.saveJellyseerrServerUrl(result);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('URL du serveur $serverType mise à jour'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _showQualityDialog(settings) async {
    final qualities = [
      {'value': 'auto', 'label': 'Auto'},
      {'value': '4k_40', 'label': '4K (40 Mbps)'},
      {'value': '1080p_20', 'label': '1080p (20 Mbps)'},
      {'value': '1080p_10', 'label': '1080p (10 Mbps)'},
      {'value': '720p_8', 'label': '720p (8 Mbps)'},
      {'value': '720p_4', 'label': '720p (4 Mbps)'},
      {'value': '480p_3', 'label': '480p (3 Mbps)'},
      {'value': '480p_1.5', 'label': '480p (1.5 Mbps)'},
    ];

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background3,
        title: const Text(
          'Qualité de streaming',
          style: TextStyle(color: AppColors.text6),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: qualities.map((quality) {
            final isSelected = quality['value'] == settings.video.defaultQuality;
            return ListTile(
              title: Text(
                quality['label']!,
                style: TextStyle(
                  color: isSelected ? AppColors.jellyfinPurple : AppColors.text6,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? const Icon(IconsaxPlusLinear.tick_circle, color: AppColors.jellyfinPurple)
                  : null,
              onTap: () => Navigator.of(context).pop(quality['value']),
            );
          }).toList(),
        ),
      ),
    );

    if (result != null) {
      final newPrefs = settings.video.copyWith(defaultQuality: result);
      ref.read(appSettingsProvider.notifier).updateVideoPreferences(newPrefs);
    }
  }

  Future<void> _showDownloadQualityDialog(settings) async {
    final qualities = DownloadQuality.values;

    final result = await showDialog<DownloadQuality>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background3,
        title: const Text(
          'Qualité de téléchargement',
          style: TextStyle(color: AppColors.text6),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: qualities.map((quality) {
            final isSelected = quality == settings.downloads.defaultQuality;
            return ListTile(
              title: Text(
                quality.label,
                style: TextStyle(
                  color: isSelected ? AppColors.jellyfinPurple : AppColors.text6,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                quality.description,
                style: const TextStyle(color: AppColors.text4, fontSize: 12),
              ),
              trailing: isSelected
                  ? const Icon(IconsaxPlusLinear.tick_circle, color: AppColors.jellyfinPurple)
                  : null,
              onTap: () => Navigator.of(context).pop(quality),
            );
          }).toList(),
        ),
      ),
    );

    if (result != null) {
      final newPrefs = settings.downloads.copyWith(defaultQuality: result);
      ref.read(appSettingsProvider.notifier).updateDownloadPreferences(newPrefs);
    }
  }

  Future<void> _showAudioLanguageDialog(settings) async {
    // Langues courantes pour l'audio
    final languages = [
      {'code': null, 'label': 'Défaut du serveur'},
      {'code': 'fra', 'label': 'Français'},
      {'code': 'eng', 'label': 'Anglais'},
      {'code': 'spa', 'label': 'Espagnol'},
      {'code': 'deu', 'label': 'Allemand'},
      {'code': 'ita', 'label': 'Italien'},
      {'code': 'por', 'label': 'Portugais'},
      {'code': 'jpn', 'label': 'Japonais'},
      {'code': 'kor', 'label': 'Coréen'},
      {'code': 'zho', 'label': 'Chinois'},
    ];

    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background3,
        title: const Text(
          'Langue audio préférée',
          style: TextStyle(color: AppColors.text6),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: languages.map((lang) {
              final isSelected = lang['code'] == settings.video.preferredAudioLanguage;
              return ListTile(
                title: Text(
                  lang['label'] as String,
                  style: TextStyle(
                    color: isSelected ? AppColors.jellyfinPurple : AppColors.text6,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(IconsaxPlusLinear.tick_circle, color: AppColors.jellyfinPurple)
                    : null,
                onTap: () => Navigator.of(context).pop(lang['code'] as String?),
              );
            }).toList(),
          ),
        ),
      ),
    );

    if (result != null || result == null) { // Accepter null pour "Défaut du serveur"
      final newPrefs = settings.video.copyWith(preferredAudioLanguage: result);
      ref.read(appSettingsProvider.notifier).updateVideoPreferences(newPrefs);
    }
  }

  Future<void> _showSubtitleLanguageDialog(settings) async {
    // Langues courantes pour les sous-titres
    final languages = [
      {'code': null, 'label': 'Défaut du serveur'},
      {'code': 'fra', 'label': 'Français'},
      {'code': 'eng', 'label': 'Anglais'},
      {'code': 'spa', 'label': 'Espagnol'},
      {'code': 'deu', 'label': 'Allemand'},
      {'code': 'ita', 'label': 'Italien'},
      {'code': 'por', 'label': 'Portugais'},
      {'code': 'jpn', 'label': 'Japonais'},
      {'code': 'kor', 'label': 'Coréen'},
      {'code': 'zho', 'label': 'Chinois'},
    ];

    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background3,
        title: const Text(
          'Langue sous-titres préférée',
          style: TextStyle(color: AppColors.text6),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: languages.map((lang) {
              final isSelected = lang['code'] == settings.video.preferredSubtitleLanguage;
              return ListTile(
                title: Text(
                  lang['label'] as String,
                  style: TextStyle(
                    color: isSelected ? AppColors.jellyfinPurple : AppColors.text6,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(IconsaxPlusLinear.tick_circle, color: AppColors.jellyfinPurple)
                    : null,
                onTap: () => Navigator.of(context).pop(lang['code'] as String?),
              );
            }).toList(),
          ),
        ),
      ),
    );

    if (result != null || result == null) { // Accepter null pour "Défaut du serveur"
      final newPrefs = settings.video.copyWith(preferredSubtitleLanguage: result);
      ref.read(appSettingsProvider.notifier).updateVideoPreferences(newPrefs);
    }
  }
}

