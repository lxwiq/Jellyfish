import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/github_release.dart';
import 'logger_service.dart';
import 'permission_service.dart';

/// Service pour gérer les mises à jour natives via GitHub Releases
class NativeUpdateService {
  NativeUpdateService._();

  static final NativeUpdateService instance = NativeUpdateService._();

  static const String _githubApiUrl =
      'https://api.github.com/repos/lxwiq/Jellyfish/releases/latest';
  
  static const String _keyLastNativeUpdateCheck = 'last_native_update_check';
  static const String _keySkippedVersion = 'skipped_update_version';

  final Dio _dio = Dio();

  /// Vérifie si une mise à jour native est disponible
  Future<GitHubRelease?> checkForUpdate() async {
    try {
      // Récupérer la version actuelle
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      LoggerService.instance.info('🔍 Vérification des mises à jour natives...');
      LoggerService.instance.info('   Version actuelle: $currentVersion');
      LoggerService.instance.info('   API URL: $_githubApiUrl');

      // Récupérer la dernière release depuis GitHub
      final response = await _dio.get(_githubApiUrl);

      LoggerService.instance.info('   Réponse API: ${response.statusCode}');

      if (response.statusCode == 200) {
        final release = GitHubRelease.fromJson(response.data);

        LoggerService.instance.info('   Dernière version: ${release.version}');
        LoggerService.instance.info('   Tag name: ${release.tagName}');
        LoggerService.instance.info('   Assets: ${release.assets.length}');

        // Enregistrer la date de vérification
        await _saveLastUpdateCheck();

        // Comparer les versions
        if (_isNewerVersion(release.version, currentVersion)) {
          // Vérifier si cette version n'a pas été ignorée
          final skippedVersion = await getSkippedVersion();
          if (skippedVersion == release.version) {
            LoggerService.instance.info('   ⏭️  Version ignorée par l\'utilisateur');
            return null;
          }

          LoggerService.instance.info('   ✅ Mise à jour disponible !');
          return release;
        } else {
          LoggerService.instance.info('   ✅ Application à jour (current: $currentVersion >= latest: ${release.version})');
          return null;
        }
      }

      LoggerService.instance.warning('   ⚠️  Réponse API invalide: ${response.statusCode}');
      return null;
    } catch (e, stackTrace) {
      LoggerService.instance.error(
        'Erreur lors de la vérification de mise à jour native',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Télécharge et installe une mise à jour
  Future<bool> downloadAndInstall(
    GitHubRelease release, {
    Function(double)? onProgress,
  }) async {
    try {
      LoggerService.instance.info('Début du téléchargement de la mise à jour ${release.version}');

      // Déterminer l'asset à télécharger selon la plateforme
      GitHubAsset? asset;

      if (Platform.isAndroid) {
        asset = release.androidAsset;
      } else if (Platform.isWindows) {
        asset = release.windowsAsset;
      } else if (Platform.isMacOS) {
        asset = release.macOSAsset;
      } else if (Platform.isLinux) {
        asset = release.linuxAsset;
      }

      if (asset == null) {
        LoggerService.instance.error('Aucun asset disponible pour la plateforme ${Platform.operatingSystem}');
        return false;
      }

      LoggerService.instance.info('📥 Téléchargement de ${asset.name} (${asset.formattedSize})...');

      // Créer le dossier de téléchargement
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/${asset.name}';

      LoggerService.instance.info('Chemin de téléchargement: $filePath');

      // Télécharger le fichier
      await _dio.download(
        asset.browserDownloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            final progress = received / total;
            onProgress(progress);
          }
        },
      );

      LoggerService.instance.info('✅ Téléchargement terminé: $filePath');

      // Installer selon la plateforme
      if (Platform.isAndroid) {
        return await _installAndroid(filePath);
      } else if (Platform.isWindows) {
        return await _installWindows(filePath);
      } else if (Platform.isMacOS) {
        return await _installMacOS(filePath);
      } else if (Platform.isLinux) {
        return await _installLinux(filePath);
      }

      return false;
    } catch (e, stackTrace) {
      LoggerService.instance.error(
        'Erreur lors du téléchargement/installation',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Installe l'APK sur Android
  Future<bool> _installAndroid(String filePath) async {
    try {
      LoggerService.instance.info('📱 Vérification des permissions d\'installation...');

      // Vérifier et demander la permission d'installer des packages
      final hasPermission = await PermissionService.instance.hasInstallPackagesPermission();

      if (!hasPermission) {
        LoggerService.instance.info('🔐 Demande de permission d\'installation...');
        final granted = await PermissionService.instance.requestInstallPackagesPermission();

        if (!granted) {
          LoggerService.instance.error('❌ Permission d\'installation refusée');
          return false;
        }
      }

      LoggerService.instance.info('📱 Ouverture de l\'installateur Android...');
      LoggerService.instance.info('📂 Chemin du fichier: $filePath');

      // Vérifier que le fichier existe
      final file = File(filePath);
      if (!await file.exists()) {
        LoggerService.instance.error('❌ Le fichier APK n\'existe pas: $filePath');
        return false;
      }

      final result = await OpenFile.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type == ResultType.done) {
        LoggerService.instance.info('✅ Installateur ouvert avec succès');
        return true;
      } else {
        LoggerService.instance.error('❌ Erreur lors de l\'ouverture: ${result.message}');
        LoggerService.instance.error('   Type de résultat: ${result.type}');
        return false;
      }
    } catch (e, stackTrace) {
      LoggerService.instance.error(
        '❌ Erreur lors de l\'installation Android: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Lance l'installateur sur Windows
  Future<bool> _installWindows(String filePath) async {
    try {
      LoggerService.instance.info('🪟 Lancement de l\'installateur Windows...');

      // Sur Windows, on ne peut pas installer automatiquement sans privilèges admin
      // On ouvre simplement l'installateur pour que l'utilisateur l'exécute
      final result = await OpenFile.open(filePath);

      if (result.type == ResultType.done) {
        LoggerService.instance.info('✅ Installateur lancé avec succès');
        return true;
      } else {
        LoggerService.instance.error('❌ Erreur lors du lancement: ${result.message}');
        return false;
      }
    } catch (e) {
      LoggerService.instance.error('❌ Erreur lors de l\'installation Windows: $e');
      return false;
    }
  }

  /// Ouvre le DMG sur macOS
  Future<bool> _installMacOS(String filePath) async {
    try {
      LoggerService.instance.info('🍎 Ouverture du DMG macOS...');
      final result = await OpenFile.open(filePath);

      if (result.type == ResultType.done) {
        LoggerService.instance.info('✅ DMG ouvert avec succès');
        return true;
      } else {
        LoggerService.instance.error('❌ Erreur lors de l\'ouverture: ${result.message}');
        return false;
      }
    } catch (e) {
      LoggerService.instance.error('❌ Erreur lors de l\'installation macOS: $e');
      return false;
    }
  }

  /// Ouvre l'AppImage sur Linux
  Future<bool> _installLinux(String filePath) async {
    try {
      LoggerService.instance.info('🐧 Ouverture de l\'AppImage Linux...');

      // Rendre le fichier exécutable
      await Process.run('chmod', ['+x', filePath]);

      final result = await OpenFile.open(filePath);

      if (result.type == ResultType.done) {
        LoggerService.instance.info('✅ AppImage ouvert avec succès');
        return true;
      } else {
        LoggerService.instance.error('❌ Erreur lors de l\'ouverture: ${result.message}');
        return false;
      }
    } catch (e) {
      LoggerService.instance.error('❌ Erreur lors de l\'installation Linux: $e');
      return false;
    }
  }

  /// Compare deux versions (retourne true si newVersion > currentVersion)
  bool _isNewerVersion(String newVersion, String currentVersion) {
    try {
      final newParts = newVersion.split('.').map(int.parse).toList();
      final currentParts = currentVersion.split('.').map(int.parse).toList();

      for (int i = 0; i < newParts.length && i < currentParts.length; i++) {
        if (newParts[i] > currentParts[i]) return true;
        if (newParts[i] < currentParts[i]) return false;
      }

      return newParts.length > currentParts.length;
    } catch (e) {
      print('❌ Erreur lors de la comparaison de versions: $e');
      return false;
    }
  }

  /// Marque une version comme ignorée
  Future<void> skipVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySkippedVersion, version);
    print('⏭️  Version $version ignorée');
  }

  /// Récupère la version ignorée
  Future<String?> getSkippedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySkippedVersion);
  }

  /// Efface la version ignorée
  Future<void> clearSkippedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySkippedVersion);
  }

  /// Récupère la date de la dernière vérification
  Future<DateTime?> getLastUpdateCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_keyLastNativeUpdateCheck);
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  /// Sauvegarde la date de dernière vérification
  Future<void> _saveLastUpdateCheck() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyLastNativeUpdateCheck,
      DateTime.now().toIso8601String(),
    );
  }
}

