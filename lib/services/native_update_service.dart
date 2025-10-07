import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/github_release.dart';

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

      print('🔍 Vérification des mises à jour natives...');
      print('   Version actuelle: $currentVersion');

      // Récupérer la dernière release depuis GitHub
      final response = await _dio.get(_githubApiUrl);

      if (response.statusCode == 200) {
        final release = GitHubRelease.fromJson(response.data);

        print('   Dernière version: ${release.version}');

        // Enregistrer la date de vérification
        await _saveLastUpdateCheck();

        // Comparer les versions
        if (_isNewerVersion(release.version, currentVersion)) {
          // Vérifier si cette version n'a pas été ignorée
          final skippedVersion = await getSkippedVersion();
          if (skippedVersion == release.version) {
            print('   ⏭️  Version ignorée par l\'utilisateur');
            return null;
          }

          print('   ✅ Mise à jour disponible !');
          return release;
        } else {
          print('   ✅ Application à jour');
          return null;
        }
      }

      return null;
    } catch (e) {
      print('❌ Erreur lors de la vérification de mise à jour native: $e');
      return null;
    }
  }

  /// Télécharge et installe une mise à jour
  Future<bool> downloadAndInstall(
    GitHubRelease release, {
    Function(double)? onProgress,
  }) async {
    try {
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
        print('❌ Aucun asset disponible pour cette plateforme');
        return false;
      }

      print('📥 Téléchargement de ${asset.name} (${asset.formattedSize})...');

      // Créer le dossier de téléchargement
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/${asset.name}';

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

      print('✅ Téléchargement terminé: $filePath');

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
    } catch (e) {
      print('❌ Erreur lors du téléchargement/installation: $e');
      return false;
    }
  }

  /// Installe l'APK sur Android
  Future<bool> _installAndroid(String filePath) async {
    try {
      print('📱 Ouverture de l\'installateur Android...');
      final result = await OpenFile.open(filePath);
      
      if (result.type == ResultType.done) {
        print('✅ Installateur ouvert avec succès');
        return true;
      } else {
        print('❌ Erreur lors de l\'ouverture: ${result.message}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur lors de l\'installation Android: $e');
      return false;
    }
  }

  /// Lance l'installateur sur Windows
  Future<bool> _installWindows(String filePath) async {
    try {
      print('🪟 Lancement de l\'installateur Windows...');
      
      // Lancer l'installateur en mode silencieux
      final result = await Process.run(
        filePath,
        ['/SILENT', '/CLOSEAPPLICATIONS', '/RESTARTAPPLICATIONS'],
      );

      if (result.exitCode == 0) {
        print('✅ Installateur lancé avec succès');
        // L'application va se fermer et se mettre à jour
        exit(0);
      } else {
        print('❌ Erreur lors du lancement: ${result.stderr}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur lors de l\'installation Windows: $e');
      return false;
    }
  }

  /// Ouvre le DMG sur macOS
  Future<bool> _installMacOS(String filePath) async {
    try {
      print('🍎 Ouverture du DMG macOS...');
      final result = await OpenFile.open(filePath);
      
      if (result.type == ResultType.done) {
        print('✅ DMG ouvert avec succès');
        return true;
      } else {
        print('❌ Erreur lors de l\'ouverture: ${result.message}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur lors de l\'installation macOS: $e');
      return false;
    }
  }

  /// Ouvre l'AppImage sur Linux
  Future<bool> _installLinux(String filePath) async {
    try {
      print('🐧 Ouverture de l\'AppImage Linux...');
      
      // Rendre le fichier exécutable
      await Process.run('chmod', ['+x', filePath]);
      
      final result = await OpenFile.open(filePath);
      
      if (result.type == ResultType.done) {
        print('✅ AppImage ouvert avec succès');
        return true;
      } else {
        print('❌ Erreur lors de l\'ouverture: ${result.message}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur lors de l\'installation Linux: $e');
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

