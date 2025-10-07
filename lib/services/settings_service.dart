import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

/// Service de gestion des paramètres de l'application
class SettingsService {
  static const String _keySettings = 'app_settings';
  
  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  /// Charge les paramètres depuis le stockage
  Future<AppSettings> loadSettings() async {
    final settingsJson = _prefs.getString(_keySettings);
    
    if (settingsJson == null) {
      print('📝 Aucun paramètre sauvegardé, utilisation des valeurs par défaut');
      return AppSettings.defaults();
    }
    
    try {
      final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
      final settings = AppSettings.fromJson(settingsMap);
      print('✅ Paramètres chargés avec succès');
      return settings;
    } catch (e) {
      print('❌ Erreur lors du chargement des paramètres: $e');
      print('   Utilisation des valeurs par défaut');
      return AppSettings.defaults();
    }
  }

  /// Sauvegarde les paramètres dans le stockage
  Future<void> saveSettings(AppSettings settings) async {
    try {
      final settingsJson = jsonEncode(settings.toJson());
      await _prefs.setString(_keySettings, settingsJson);
      print('✅ Paramètres sauvegardés avec succès');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde des paramètres: $e');
      rethrow;
    }
  }

  /// Réinitialise tous les paramètres aux valeurs par défaut
  Future<void> resetSettings() async {
    await _prefs.remove(_keySettings);
    print('🔄 Paramètres réinitialisés aux valeurs par défaut');
  }

  /// Exporte les paramètres en JSON
  String exportSettings(AppSettings settings) {
    return jsonEncode(settings.toJson());
  }

  /// Importe les paramètres depuis JSON
  AppSettings importSettings(String json) {
    try {
      final settingsMap = jsonDecode(json) as Map<String, dynamic>;
      return AppSettings.fromJson(settingsMap);
    } catch (e) {
      print('❌ Erreur lors de l\'importation des paramètres: $e');
      rethrow;
    }
  }

  // ========== Méthodes de mise à jour rapide ==========

  /// Met à jour les préférences vidéo
  Future<void> updateVideoPreferences(
    AppSettings currentSettings,
    VideoPreferences videoPreferences,
  ) async {
    final newSettings = currentSettings.copyWith(video: videoPreferences);
    await saveSettings(newSettings);
  }

  /// Met à jour les préférences de téléchargement
  Future<void> updateDownloadPreferences(
    AppSettings currentSettings,
    DownloadPreferences downloadPreferences,
  ) async {
    final newSettings = currentSettings.copyWith(downloads: downloadPreferences);
    await saveSettings(newSettings);
  }

  /// Met à jour les préférences de notifications
  Future<void> updateNotificationPreferences(
    AppSettings currentSettings,
    NotificationPreferences notificationPreferences,
  ) async {
    final newSettings = currentSettings.copyWith(notifications: notificationPreferences);
    await saveSettings(newSettings);
  }

  /// Met à jour les préférences d'interface
  Future<void> updateInterfacePreferences(
    AppSettings currentSettings,
    InterfacePreferences interfacePreferences,
  ) async {
    final newSettings = currentSettings.copyWith(interface: interfacePreferences);
    await saveSettings(newSettings);
  }

  /// Met à jour les préférences serveurs
  Future<void> updateServerPreferences(
    AppSettings currentSettings,
    ServerPreferences serverPreferences,
  ) async {
    final newSettings = currentSettings.copyWith(servers: serverPreferences);
    await saveSettings(newSettings);
  }

  /// Met à jour les préférences de mises à jour
  Future<void> updateUpdatePreferences(
    AppSettings currentSettings,
    UpdatePreferences updatePreferences,
  ) async {
    final newSettings = currentSettings.copyWith(updates: updatePreferences);
    await saveSettings(newSettings);
  }

  /// Met à jour les préférences de cache
  Future<void> updateCachePreferences(
    AppSettings currentSettings,
    CachePreferences cachePreferences,
  ) async {
    final newSettings = currentSettings.copyWith(cache: cachePreferences);
    await saveSettings(newSettings);
  }
}

