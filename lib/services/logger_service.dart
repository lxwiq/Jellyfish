import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// Service de logging vers fichier pour la production
class LoggerService {
  LoggerService._();

  static final LoggerService instance = LoggerService._();

  File? _logFile;
  bool _initialized = false;
  final int _maxLogSizeBytes = 5 * 1024 * 1024; // 5 MB
  final int _maxLogFiles = 3; // Garder 3 fichiers de log max

  /// Initialise le service de logging
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${directory.path}/logs');
      
      // Créer le dossier logs s'il n'existe pas
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      // Créer le fichier de log avec la date du jour
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _logFile = File('${logsDir.path}/jellyfish_$dateStr.log');

      // Nettoyer les vieux logs
      await _cleanOldLogs(logsDir);

      _initialized = true;
      
      // Log de démarrage
      await log('INFO', '========== Application démarrée ==========');
      await log('INFO', 'Version: ${DateTime.now()}');
      await log('INFO', 'Plateforme: ${Platform.operatingSystem}');
      
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation du logger: $e');
    }
  }

  /// Écrit un log dans le fichier
  Future<void> log(String level, String message, {Object? error, StackTrace? stackTrace}) async {
    try {
      // En mode debug, afficher aussi dans la console
      if (kDebugMode) {
        debugPrint('[$level] $message');
        if (error != null) debugPrint('Error: $error');
        if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
      }

      // Si pas initialisé, initialiser maintenant
      if (!_initialized) {
        await initialize();
      }

      if (_logFile == null) return;

      // Vérifier la taille du fichier
      if (await _logFile!.exists()) {
        final fileSize = await _logFile!.length();
        if (fileSize > _maxLogSizeBytes) {
          await _rotateLogFile();
        }
      }

      // Formater le message
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
      final logLine = StringBuffer();
      logLine.writeln('[$timestamp] [$level] $message');
      
      if (error != null) {
        logLine.writeln('  Error: $error');
      }
      
      if (stackTrace != null) {
        logLine.writeln('  StackTrace:');
        logLine.writeln('    ${stackTrace.toString().replaceAll('\n', '\n    ')}');
      }

      // Écrire dans le fichier
      await _logFile!.writeAsString(
        logLine.toString(),
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'écriture du log: $e');
    }
  }

  /// Logs de différents niveaux
  Future<void> info(String message) => log('INFO', message);
  Future<void> warning(String message) => log('WARNING', message);
  Future<void> error(String message, {Object? error, StackTrace? stackTrace}) => 
      log('ERROR', message, error: error, stackTrace: stackTrace);
  Future<void> debug(String message) => log('DEBUG', message);

  /// Rotation du fichier de log quand il devient trop gros
  Future<void> _rotateLogFile() async {
    try {
      if (_logFile == null || !await _logFile!.exists()) return;

      final directory = _logFile!.parent;
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final rotatedFile = File('${directory.path}/jellyfish_$timestamp.log');

      // Renommer le fichier actuel
      await _logFile!.rename(rotatedFile.path);

      // Créer un nouveau fichier
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _logFile = File('${directory.path}/jellyfish_$dateStr.log');

      await log('INFO', 'Log file rotated');
    } catch (e) {
      debugPrint('❌ Erreur lors de la rotation du log: $e');
    }
  }

  /// Nettoie les vieux fichiers de log
  Future<void> _cleanOldLogs(Directory logsDir) async {
    try {
      final files = await logsDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .cast<File>()
          .toList();

      // Trier par date de modification (plus récent en premier)
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // Supprimer les fichiers au-delà de la limite
      if (files.length > _maxLogFiles) {
        for (var i = _maxLogFiles; i < files.length; i++) {
          await files[i].delete();
          debugPrint('🗑️  Ancien log supprimé: ${files[i].path}');
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du nettoyage des logs: $e');
    }
  }

  /// Récupère le chemin du fichier de log actuel
  String? get logFilePath => _logFile?.path;

  /// Récupère tous les fichiers de log
  Future<List<File>> getLogFiles() async {
    try {
      if (_logFile == null) return [];

      final directory = _logFile!.parent;
      final files = await directory
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .cast<File>()
          .toList();

      // Trier par date de modification (plus récent en premier)
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      return files;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des logs: $e');
      return [];
    }
  }

  /// Lit le contenu d'un fichier de log
  Future<String> readLogFile(File file) async {
    try {
      return await file.readAsString();
    } catch (e) {
      return 'Erreur lors de la lecture du fichier: $e';
    }
  }

  /// Supprime tous les fichiers de log
  Future<void> clearAllLogs() async {
    try {
      final files = await getLogFiles();
      for (final file in files) {
        await file.delete();
      }
      await log('INFO', 'Tous les logs ont été supprimés');
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression des logs: $e');
    }
  }

  /// Exporte les logs vers un fichier unique
  Future<File?> exportLogs() async {
    try {
      final files = await getLogFiles();
      if (files.isEmpty) return null;

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final exportFile = File('${directory.path}/jellyfish_logs_export_$timestamp.txt');

      final buffer = StringBuffer();
      buffer.writeln('========== Jellyfish Logs Export ==========');
      buffer.writeln('Date: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
      buffer.writeln('Platform: ${Platform.operatingSystem}');
      buffer.writeln('===========================================\n');

      for (final file in files) {
        buffer.writeln('\n========== ${file.path.split('/').last} ==========');
        buffer.writeln(await readLogFile(file));
      }

      await exportFile.writeAsString(buffer.toString());
      await log('INFO', 'Logs exportés vers: ${exportFile.path}');

      return exportFile;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'export des logs: $e');
      return null;
    }
  }
}

