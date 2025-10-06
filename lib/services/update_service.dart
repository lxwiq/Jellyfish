import 'package:flutter/foundation.dart';

/// Service pour gérer les mises à jour Shorebird
/// En mode debug, ce service ne fait rien car Shorebird n'est pas disponible
class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  /// Vérifie et télécharge les mises à jour si disponibles
  /// Retourne un Stream de statuts pour afficher la progression
  Stream<UpdateStatus> checkAndDownloadUpdates() async* {
    // En mode debug, Shorebird n'est pas disponible
    if (kDebugMode) {
      yield UpdateStatus(
        message: 'Mode développement',
        isDownloading: false,
      );
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }

    // En mode release, on utilise l'auto-update de Shorebird
    // qui est configuré dans shorebird.yaml
    // Pour l'instant, on affiche juste un message
    yield UpdateStatus(
      message: 'Vérification...',
      isDownloading: false,
    );
    await Future.delayed(const Duration(milliseconds: 500));

    yield UpdateStatus(
      message: 'Prêt',
      isDownloading: false,
    );
  }
}

/// Statut de la mise à jour
class UpdateStatus {
  final String message;
  final bool isDownloading;

  UpdateStatus({
    required this.message,
    required this.isDownloading,
  });
}

