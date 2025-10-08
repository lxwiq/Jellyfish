import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

/// Service centralisé pour la gestion des permissions
/// Note: Pas besoin de permission de stockage car on utilise le stockage scopé (Android 10+)
class PermissionService {
  static final PermissionService instance = PermissionService._();
  PermissionService._();

  bool _notificationPermissionRequested = false;

  /// Demande toutes les permissions nécessaires au démarrage
  Future<void> requestInitialPermissions() async {
    // Sur web et desktop (Windows, macOS, Linux), pas besoin de demander de permissions
    // Les notifications fonctionnent automatiquement
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await requestNotificationPermission();
    }
  }

  /// Demande la permission de notification
  Future<bool> requestNotificationPermission() async {
    // Sur web et desktop (Windows, macOS, Linux), pas besoin de permission
    if (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return true;
    }

    if (_notificationPermissionRequested) {
      return await Permission.notification.isGranted;
    }

    _notificationPermissionRequested = true;

    if (Platform.isAndroid) {
      // Android 13+ nécessite une permission runtime pour les notifications
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 33) {
        final status = await Permission.notification.request();
        return status.isGranted;
      }
      // Android < 13 n'a pas besoin de permission runtime
      return true;
    } else if (Platform.isIOS) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }

    return true;
  }

  /// Vérifie si la permission de notification est accordée
  Future<bool> hasNotificationPermission() async {
    // Sur web et desktop, toujours true
    if (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return true;
    }

    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 33) {
        return await Permission.notification.isGranted;
      }
      return true;
    } else if (Platform.isIOS) {
      return await Permission.notification.isGranted;
    }
    return true;
  }



  /// Affiche un dialogue pour expliquer pourquoi la permission est nécessaire
  Future<bool> showPermissionRationale(
    BuildContext context,
    String title,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Ouvre les paramètres de l'application
  Future<void> openAppSettings() async {
    await Permission.notification.request();
  }

  /// Obtient la version d'Android
  Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;
    
    // Utiliser package_info_plus ou device_info_plus pour obtenir la version
    // Pour l'instant, on suppose Android 13+ pour être sûr
    return 33;
  }

  /// Vérifie toutes les permissions nécessaires pour les téléchargements
  Future<Map<String, bool>> checkDownloadPermissions() async {
    return {
      'notification': await hasNotificationPermission(),
    };
  }

  /// Demande toutes les permissions nécessaires pour les téléchargements
  /// Retourne true si toutes les permissions sont accordées
  Future<bool> requestDownloadPermissions() async {
    return await requestNotificationPermission();
  }

  /// Demande la permission d'installer des packages (pour les mises à jour)
  Future<bool> requestInstallPackagesPermission() async {
    // Sur web et desktop, pas besoin de permission
    if (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return true;
    }

    if (Platform.isAndroid) {
      // Android 8.0+ (API 26+) nécessite une permission runtime pour installer des APK
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 26) {
        final status = await Permission.requestInstallPackages.request();
        return status.isGranted;
      }
      // Android < 8.0 n'a pas besoin de permission runtime
      return true;
    }

    return true;
  }

  /// Vérifie si la permission d'installer des packages est accordée
  Future<bool> hasInstallPackagesPermission() async {
    // Sur web et desktop, toujours true
    if (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return true;
    }

    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 26) {
        return await Permission.requestInstallPackages.isGranted;
      }
      return true;
    }

    return true;
  }

  /// Réinitialise les flags de demande de permission (pour les tests)
  void reset() {
    _notificationPermissionRequested = false;
  }
}

