import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';
import 'services_provider.dart';

/// Provider pour le service de settings
final settingsServiceProvider = Provider<SettingsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsService(prefs);
});

/// Provider pour l'état des paramètres de l'application
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AsyncValue<AppSettings>>((ref) {
  return AppSettingsNotifier(ref);
});

/// Notifier pour gérer l'état des paramètres
class AppSettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  final Ref ref;
  late final SettingsService _settingsService;

  AppSettingsNotifier(this.ref) : super(const AsyncValue.loading()) {
    _settingsService = ref.read(settingsServiceProvider);
    _loadSettings();
  }

  /// Charge les paramètres au démarrage
  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsService.loadSettings();
      state = AsyncValue.data(settings);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Recharge les paramètres
  Future<void> reload() async {
    state = const AsyncValue.loading();
    await _loadSettings();
  }

  // ========== Méthodes de mise à jour ==========

  /// Met à jour les préférences vidéo
  Future<void> updateVideoPreferences(VideoPreferences videoPreferences) async {
    final currentSettings = state.value;
    if (currentSettings == null) return;

    try {
      final newSettings = currentSettings.copyWith(video: videoPreferences);
      await _settingsService.saveSettings(newSettings);
      state = AsyncValue.data(newSettings);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Met à jour les préférences de téléchargement
  Future<void> updateDownloadPreferences(DownloadPreferences downloadPreferences) async {
    final currentSettings = state.value;
    if (currentSettings == null) return;

    try {
      final newSettings = currentSettings.copyWith(downloads: downloadPreferences);
      await _settingsService.saveSettings(newSettings);
      state = AsyncValue.data(newSettings);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Met à jour les préférences de notifications
  Future<void> updateNotificationPreferences(NotificationPreferences notificationPreferences) async {
    final currentSettings = state.value;
    if (currentSettings == null) return;

    try {
      final newSettings = currentSettings.copyWith(notifications: notificationPreferences);
      await _settingsService.saveSettings(newSettings);
      state = AsyncValue.data(newSettings);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Met à jour les préférences d'interface
  Future<void> updateInterfacePreferences(InterfacePreferences interfacePreferences) async {
    final currentSettings = state.value;
    if (currentSettings == null) return;

    try {
      final newSettings = currentSettings.copyWith(interface: interfacePreferences);
      await _settingsService.saveSettings(newSettings);
      state = AsyncValue.data(newSettings);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Met à jour les préférences serveurs
  Future<void> updateServerPreferences(ServerPreferences serverPreferences) async {
    final currentSettings = state.value;
    if (currentSettings == null) return;

    try {
      final newSettings = currentSettings.copyWith(servers: serverPreferences);
      await _settingsService.saveSettings(newSettings);
      state = AsyncValue.data(newSettings);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Met à jour les préférences de mises à jour
  Future<void> updateUpdatePreferences(UpdatePreferences updatePreferences) async {
    final currentSettings = state.value;
    if (currentSettings == null) return;

    try {
      final newSettings = currentSettings.copyWith(updates: updatePreferences);
      await _settingsService.saveSettings(newSettings);
      state = AsyncValue.data(newSettings);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Met à jour les préférences de cache
  Future<void> updateCachePreferences(CachePreferences cachePreferences) async {
    final currentSettings = state.value;
    if (currentSettings == null) return;

    try {
      final newSettings = currentSettings.copyWith(cache: cachePreferences);
      await _settingsService.saveSettings(newSettings);
      state = AsyncValue.data(newSettings);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Réinitialise tous les paramètres
  Future<void> resetToDefaults() async {
    try {
      await _settingsService.resetSettings();
      final defaultSettings = AppSettings.defaults();
      state = AsyncValue.data(defaultSettings);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Exporte les paramètres
  String? exportSettings() {
    final currentSettings = state.value;
    if (currentSettings == null) return null;
    return _settingsService.exportSettings(currentSettings);
  }

  /// Importe les paramètres
  Future<void> importSettings(String json) async {
    try {
      final settings = _settingsService.importSettings(json);
      await _settingsService.saveSettings(settings);
      state = AsyncValue.data(settings);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

