import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:jellyfish/services/logger_service.dart';

import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;

/// Service pour gérer les mises à jour Shorebird
/// En mode debug, ce service ne fait rien car Shorebird n'est pas disponible
class UpdateService {
  UpdateService._();

  static final UpdateService instance = UpdateService._();

  final _shorebirdUpdater = shorebird.ShorebirdUpdater();

  static const String _keyLastUpdateCheck = 'last_update_check';
  static const String _keyLastUpdateApplied = 'last_update_applied';
  static const String _keyPatchNumber = 'patch_number';
  static const String _keyUpdateHistory = 'update_history';

  /// Vérifie et télécharge les mises à jour si disponibles
  /// Retourne un Stream de statuts pour afficher la progression
  Stream<UpdateCheckStatus> checkAndDownloadUpdates() async* {
    // En mode debug, Shorebird n'est pas disponible
    if (kDebugMode) {
      yield UpdateCheckStatus(
        message: 'Mode développement',
        isDownloading: false,
      );
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }

    // Vérifier si Shorebird est disponible
    final status = await _shorebirdUpdater.checkForUpdate();

    // Enregistrer la date de vérification
    await _saveLastUpdateCheck();

    if (status != shorebird.UpdateStatus.outdated) {
      yield UpdateCheckStatus(
        message: 'À jour',
        isDownloading: false,
      );
      return;
    }

    // Une mise à jour est disponible
    yield UpdateCheckStatus(
      message: 'Téléchargement...',
      isDownloading: true,
    );

    try {
      // Télécharger le patch
      await _shorebirdUpdater.update();

      // Récupérer le numéro du patch
      final currentPatch = await _shorebirdUpdater.readCurrentPatch();

      // Enregistrer la mise à jour
      await recordUpdateApplied(patchNumber: currentPatch?.number.toString());

      yield UpdateCheckStatus(
        message: 'Mise à jour prête (redémarrage requis)',
        isDownloading: false,
      );
    } catch (e) {
      await LoggerService.instance.error('Erreur lors du téléchargement de la mise à jour', error: e);
      yield UpdateCheckStatus(
        message: 'Erreur de mise à jour',
        isDownloading: false,
      );
    }
  }

  /// Vérifie si une mise à jour est disponible (sans télécharger)
  Future<bool> isUpdateAvailable() async {
    if (kDebugMode) return false;

    try {
      final status = await _shorebirdUpdater.checkForUpdate();
      return status == shorebird.UpdateStatus.outdated;
    } catch (e) {
      await LoggerService.instance.error('Erreur lors de la vérification de mise à jour', error: e);
      return false;
    }
  }

  /// Récupère le numéro du patch actuel depuis Shorebird
  Future<int?> getCurrentPatchNumberFromShorebird() async {
    if (kDebugMode) return null;

    try {
      final currentPatch = await _shorebirdUpdater.readCurrentPatch();
      return currentPatch?.number;
    } catch (e) {
      await LoggerService.instance.error('Erreur lors de la récupération du numéro de patch', error: e);
      return null;
    }
  }

  /// Enregistre qu'une mise à jour a été appliquée
  Future<void> recordUpdateApplied({String? patchNumber}) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();

    await prefs.setString(_keyLastUpdateApplied, now);

    if (patchNumber != null) {
      await prefs.setString(_keyPatchNumber, patchNumber);
    }

    // Ajouter à l'historique
    final history = await getUpdateHistory();
    history.insert(0, UpdateHistoryEntry(
      date: DateTime.now(),
      patchNumber: patchNumber,
    ));

    // Garder seulement les 10 dernières entrées
    final limitedHistory = history.take(10).toList();
    final historyJson = limitedHistory.map((e) => e.toJson()).toList();
    await prefs.setStringList(
      _keyUpdateHistory,
      historyJson.map((e) => e.toString()).toList(),
    );
  }

  /// Récupère la date de la dernière vérification
  Future<DateTime?> getLastUpdateCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_keyLastUpdateCheck);
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  /// Récupère la date de la dernière mise à jour appliquée
  Future<DateTime?> getLastUpdateApplied() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_keyLastUpdateApplied);
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  /// Récupère le numéro du patch actuel
  Future<String?> getCurrentPatchNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPatchNumber);
  }

  /// Récupère l'historique des mises à jour
  Future<List<UpdateHistoryEntry>> getUpdateHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyList = prefs.getStringList(_keyUpdateHistory) ?? [];

    return historyList.map((jsonStr) {
      try {
        // Parse simple format: "date|patchNumber"
        final parts = jsonStr.split('|');
        return UpdateHistoryEntry(
          date: DateTime.parse(parts[0]),
          patchNumber: parts.length > 1 ? parts[1] : null,
        );
      } catch (e) {
        return null;
      }
    }).whereType<UpdateHistoryEntry>().toList();
  }

  /// Sauvegarde la date de dernière vérification
  Future<void> _saveLastUpdateCheck() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastUpdateCheck, DateTime.now().toIso8601String());
  }
}

/// Statut de la vérification de mise à jour
class UpdateCheckStatus {
  final String message;
  final bool isDownloading;

  UpdateCheckStatus({
    required this.message,
    required this.isDownloading,
  });
}

/// Entrée dans l'historique des mises à jour
class UpdateHistoryEntry {
  final DateTime date;
  final String? patchNumber;

  UpdateHistoryEntry({
    required this.date,
    this.patchNumber,
  });

  String toJson() {
    return '${date.toIso8601String()}|${patchNumber ?? ''}';
  }
}

