import 'dart:convert';
import 'download_status.dart';

/// Représente un élément téléchargé (film, épisode, etc.)
class DownloadedItem {
  final String id;
  final String itemId; // ID Jellyfin
  final String itemType; // Movie, Episode, etc.
  final String title;
  final String? description;
  final String? imageUrl;
  final String downloadPath;
  final DownloadStatus status;
  final double progress; // 0.0 - 1.0
  final int totalBytes;
  final int downloadedBytes;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final DownloadQuality quality;
  final Map<String, dynamic>? metadata;

  const DownloadedItem({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.title,
    this.description,
    this.imageUrl,
    required this.downloadPath,
    required this.status,
    this.progress = 0.0,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
    this.quality = DownloadQuality.high,
    this.metadata,
  });

  /// Crée une copie avec des modifications
  DownloadedItem copyWith({
    String? id,
    String? itemId,
    String? itemType,
    String? title,
    String? description,
    String? imageUrl,
    String? downloadPath,
    DownloadStatus? status,
    double? progress,
    int? totalBytes,
    int? downloadedBytes,
    DateTime? createdAt,
    DateTime? completedAt,
    String? errorMessage,
    DownloadQuality? quality,
    Map<String, dynamic>? metadata,
  }) {
    return DownloadedItem(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      downloadPath: downloadPath ?? this.downloadPath,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      quality: quality ?? this.quality,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convertit en Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'item_type': itemType,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'download_path': downloadPath,
      'status': status.toDbString(),
      'progress': progress,
      'total_bytes': totalBytes,
      'downloaded_bytes': downloadedBytes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'completed_at': completedAt?.millisecondsSinceEpoch,
      'error_message': errorMessage,
      'quality': quality.toDbString(),
      'metadata': metadata != null ? jsonEncode(metadata) : null,
    };
  }

  /// Crée depuis une Map de la base de données
  factory DownloadedItem.fromMap(Map<String, dynamic> map) {
    return DownloadedItem(
      id: map['id'] as String,
      itemId: map['item_id'] as String,
      itemType: map['item_type'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      downloadPath: map['download_path'] as String,
      status: DownloadStatus.fromDbString(map['status'] as String),
      progress: (map['progress'] as num).toDouble(),
      totalBytes: map['total_bytes'] as int,
      downloadedBytes: map['downloaded_bytes'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int)
          : null,
      errorMessage: map['error_message'] as String?,
      quality: DownloadQuality.fromDbString(map['quality'] as String),
      metadata: map['metadata'] != null
          ? jsonDecode(map['metadata'] as String) as Map<String, dynamic>
          : null,
    );
  }

  // Helpers pour l'affichage

  /// Taille formatée (ex: "1.5 GB")
  String get formattedSize {
    final bytes = totalBytes > 0 ? totalBytes : downloadedBytes;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Progression en pourcentage (ex: "75%")
  String get progressPercentage => '${(progress * 100).toStringAsFixed(0)}%';

  /// Vitesse de téléchargement estimée (si disponible dans metadata)
  String? get downloadSpeed {
    if (metadata == null || !metadata!.containsKey('speed')) return null;
    final speed = metadata!['speed'] as num;
    if (speed < 1024) return '${speed.toStringAsFixed(0)} B/s';
    if (speed < 1024 * 1024) {
      return '${(speed / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(speed / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  /// Temps restant estimé (si disponible dans metadata)
  String? get estimatedTimeRemaining {
    if (metadata == null || !metadata!.containsKey('eta')) return null;
    final seconds = metadata!['eta'] as int;
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${(seconds / 60).toStringAsFixed(0)}m';
    return '${(seconds / 3600).toStringAsFixed(1)}h';
  }

  // Helpers pour les états

  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isCompleted => status == DownloadStatus.completed;
  bool get isFailed => status == DownloadStatus.failed;
  bool get isPaused => status == DownloadStatus.paused;
  bool get isPending => status == DownloadStatus.pending;
  bool get isCancelled => status == DownloadStatus.cancelled;

  /// Peut être repris
  bool get canResume => isPaused || isFailed;

  /// Peut être mis en pause
  bool get canPause => isDownloading;

  /// Peut être annulé
  bool get canCancel => isDownloading || isPaused || isPending;

  @override
  String toString() {
    return 'DownloadedItem(id: $id, title: $title, status: $status, progress: $progressPercentage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DownloadedItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

