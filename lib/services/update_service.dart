import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer les mises à jour Shorebird
/// En mode debug, ce service ne fait rien car Shorebird n'est pas disponible
class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  static const String _keyLastUpdateCheck = 'last_update_check';
  static const String _keyLastUpdateApplied = 'last_update_applied';
  static const String _keyPatchNumber = 'patch_number';
  static const String _keyUpdateHistory = 'update_history';

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

    // Enregistrer la date de vérification
    await _saveLastUpdateCheck();

    // En mode release, on utilise l'auto-update de Shorebird
    // qui est configuré dans shorebird.yaml
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

/// Statut de la mise à jour
class UpdateStatus {
  final String message;
  final bool isDownloading;

  UpdateStatus({
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

