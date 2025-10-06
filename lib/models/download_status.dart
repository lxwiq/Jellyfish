/// Statut d'un téléchargement
enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
  cancelled;

  /// Convertit le statut en chaîne pour la base de données
  String toDbString() => name;

  /// Crée un statut depuis une chaîne de la base de données
  static DownloadStatus fromDbString(String value) {
    return DownloadStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DownloadStatus.pending,
    );
  }
}

/// Qualité de téléchargement
enum DownloadQuality {
  original('Original', 'Best quality, largest file'),
  high('1080p', 'High quality, ~2-4 GB'),
  medium('720p', 'Medium quality, ~1-2 GB'),
  low('480p', 'Low quality, ~500 MB');

  final String label;
  final String description;

  const DownloadQuality(this.label, this.description);

  /// Convertit la qualité en chaîne pour la base de données
  String toDbString() => name;

  /// Crée une qualité depuis une chaîne de la base de données
  static DownloadQuality fromDbString(String value) {
    return DownloadQuality.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DownloadQuality.high,
    );
  }
}

