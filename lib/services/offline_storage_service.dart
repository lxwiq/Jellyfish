import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/downloaded_item.dart';
import '../models/download_status.dart';

/// Service de gestion du stockage local pour les téléchargements hors ligne
class OfflineStorageService {
  static const String _dbName = 'offline_downloads.db';
  static const int _dbVersion = 1;
  static const String _tableName = 'downloaded_items';

  Database? _database;

  /// Obtient l'instance de la base de données
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialise la base de données
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = path.join(documentsDirectory.path, _dbName);

    print('📦 Initialisation de la base de données: $dbPath');

    return await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Crée les tables lors de la première initialisation
  Future<void> _onCreate(Database db, int version) async {
    print('📦 Création de la table $_tableName');

    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        item_type TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        image_url TEXT,
        download_path TEXT NOT NULL,
        status TEXT NOT NULL,
        progress REAL DEFAULT 0.0,
        total_bytes INTEGER DEFAULT 0,
        downloaded_bytes INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        completed_at INTEGER,
        error_message TEXT,
        quality TEXT NOT NULL,
        metadata TEXT,
        UNIQUE(item_id)
      )
    ''');

    // Créer des index pour améliorer les performances
    await db.execute('CREATE INDEX idx_status ON $_tableName(status)');
    await db.execute('CREATE INDEX idx_item_id ON $_tableName(item_id)');
    await db.execute('CREATE INDEX idx_created_at ON $_tableName(created_at)');

    print('✅ Table $_tableName créée avec succès');
  }

  /// Gère les migrations de base de données
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('📦 Migration de la base de données: v$oldVersion -> v$newVersion');
    // Gérer les migrations futures ici
  }

  // CRUD Operations

  /// Insère un nouvel item téléchargé
  Future<void> insertDownloadedItem(DownloadedItem item) async {
    final db = await database;
    await db.insert(
      _tableName,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('✅ Item inséré: ${item.title}');
  }

  /// Met à jour un item téléchargé
  Future<void> updateDownloadedItem(DownloadedItem item) async {
    final db = await database;
    await db.update(
      _tableName,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Récupère un item par son ID
  Future<DownloadedItem?> getDownloadedItem(String id) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return DownloadedItem.fromMap(maps.first);
  }

  /// Récupère un item par l'ID Jellyfin
  Future<DownloadedItem?> getDownloadedItemByJellyfinId(String itemId) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'item_id = ?',
      whereArgs: [itemId],
    );

    if (maps.isEmpty) return null;
    return DownloadedItem.fromMap(maps.first);
  }

  /// Récupère tous les items téléchargés
  Future<List<DownloadedItem>> getAllDownloadedItems() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => DownloadedItem.fromMap(map)).toList();
  }

  /// Récupère les items par statut
  Future<List<DownloadedItem>> getDownloadedItemsByStatus(
    DownloadStatus status,
  ) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'status = ?',
      whereArgs: [status.toDbString()],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => DownloadedItem.fromMap(map)).toList();
  }

  /// Récupère les items actifs (downloading, pending, paused)
  Future<List<DownloadedItem>> getActiveDownloads() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'status IN (?, ?, ?)',
      whereArgs: [
        DownloadStatus.downloading.toDbString(),
        DownloadStatus.pending.toDbString(),
        DownloadStatus.paused.toDbString(),
      ],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => DownloadedItem.fromMap(map)).toList();
  }

  /// Supprime un item téléchargé
  Future<void> deleteDownloadedItem(String id) async {
    final db = await database;

    // Récupérer l'item pour supprimer le fichier
    final item = await getDownloadedItem(id);
    if (item != null) {
      await _deleteFile(item.downloadPath);
    }

    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    print('🗑️ Item supprimé: $id');
  }

  /// Supprime tous les items avec un statut donné
  Future<void> deleteItemsByStatus(DownloadStatus status) async {
    final items = await getDownloadedItemsByStatus(status);
    for (final item in items) {
      await deleteDownloadedItem(item.id);
    }
  }

  /// Calcule l'espace total utilisé par les téléchargements complétés
  Future<int> getTotalSpaceUsed() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(total_bytes) as total FROM $_tableName WHERE status = ?',
      [DownloadStatus.completed.toDbString()],
    );

    return (result.first['total'] as int?) ?? 0;
  }

  /// Compte le nombre de téléchargements par statut
  Future<int> countByStatus(DownloadStatus status) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE status = ?',
      [status.toDbString()],
    );

    return (result.first['count'] as int?) ?? 0;
  }

  // File Management

  /// Obtient le répertoire de téléchargement
  Future<Directory> getDownloadsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory(path.join(appDir.path, 'downloads'));

    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
      print('📁 Répertoire de téléchargement créé: ${downloadsDir.path}');
    }

    return downloadsDir;
  }

  /// Crée le chemin de téléchargement pour un item
  Future<String> createDownloadPath(
    String itemId,
    String itemType,
    String filename,
  ) async {
    final downloadsDir = await getDownloadsDirectory();
    final itemDir = Directory(
      path.join(downloadsDir.path, itemType.toLowerCase(), itemId),
    );

    if (!await itemDir.exists()) {
      await itemDir.create(recursive: true);
    }

    return path.join(itemDir.path, filename);
  }

  /// Vérifie si un fichier existe
  Future<bool> fileExists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }

  /// Obtient la taille d'un fichier
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération de la taille du fichier: $e');
    }
    return 0;
  }

  /// Supprime un fichier
  Future<void> _deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('🗑️ Fichier supprimé: $filePath');
      }

      // Supprimer le répertoire parent s'il est vide
      final dir = file.parent;
      if (await dir.exists()) {
        final contents = await dir.list().toList();
        if (contents.isEmpty) {
          await dir.delete();
          print('🗑️ Répertoire vide supprimé: ${dir.path}');
        }
      }
    } catch (e) {
      print('❌ Erreur lors de la suppression du fichier: $e');
    }
  }

  /// Nettoie les téléchargements échoués ou annulés
  Future<void> cleanupFailedDownloads() async {
    await deleteItemsByStatus(DownloadStatus.failed);
    await deleteItemsByStatus(DownloadStatus.cancelled);
    print('🧹 Téléchargements échoués/annulés nettoyés');
  }

  /// Supprime tous les téléchargements
  Future<void> deleteAllDownloads() async {
    final items = await getAllDownloadedItems();
    for (final item in items) {
      await deleteDownloadedItem(item.id);
    }
    print('🗑️ Tous les téléchargements supprimés');
  }

  /// Obtient l'espace disque disponible
  Future<int> getAvailableSpace() async {
    try {
      final dir = await getDownloadsDirectory();
      final stat = await dir.stat();
      // Note: Cette méthode ne donne pas l'espace disponible réel
      // Pour une implémentation complète, utiliser un plugin natif
      return 0; // Placeholder
    } catch (e) {
      print('❌ Erreur lors de la récupération de l\'espace disponible: $e');
      return 0;
    }
  }

  /// Ferme la base de données
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      print('📦 Base de données fermée');
    }
  }

  /// Réinitialise complètement la base de données (pour les tests)
  Future<void> reset() async {
    final db = await database;
    await db.delete(_tableName);
    print('🔄 Base de données réinitialisée');
  }
}

