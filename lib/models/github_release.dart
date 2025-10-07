import 'package:json_annotation/json_annotation.dart';

part 'github_release.g.dart';

/// Modèle pour une release GitHub
@JsonSerializable()
class GitHubRelease {
  @JsonKey(name: 'tag_name')
  final String tagName;
  
  final String name;
  
  final String body;
  
  @JsonKey(name: 'published_at')
  final String publishedAt;
  
  @JsonKey(name: 'html_url')
  final String htmlUrl;
  
  final bool prerelease;
  
  final bool draft;
  
  final List<GitHubAsset> assets;

  const GitHubRelease({
    required this.tagName,
    required this.name,
    required this.body,
    required this.publishedAt,
    required this.htmlUrl,
    required this.prerelease,
    required this.draft,
    required this.assets,
  });

  factory GitHubRelease.fromJson(Map<String, dynamic> json) =>
      _$GitHubReleaseFromJson(json);

  Map<String, dynamic> toJson() => _$GitHubReleaseToJson(this);

  /// Récupère la version depuis le tag (ex: "v1.0.0" -> "1.0.0")
  String get version {
    return tagName.startsWith('v') ? tagName.substring(1) : tagName;
  }

  /// Récupère l'asset pour Android (.apk)
  GitHubAsset? get androidAsset {
    try {
      return assets.firstWhere(
        (asset) => asset.name.toLowerCase().endsWith('.apk'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Récupère l'asset pour Windows (.exe installer)
  GitHubAsset? get windowsAsset {
    try {
      return assets.firstWhere(
        (asset) => asset.name.toLowerCase().endsWith('.exe'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Récupère l'asset pour macOS (.dmg)
  GitHubAsset? get macOSAsset {
    try {
      return assets.firstWhere(
        (asset) => asset.name.toLowerCase().endsWith('.dmg'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Récupère l'asset pour Linux (.AppImage)
  GitHubAsset? get linuxAsset {
    try {
      return assets.firstWhere(
        (asset) => asset.name.toLowerCase().endsWith('.appimage'),
      );
    } catch (e) {
      return null;
    }
  }
}

/// Modèle pour un asset GitHub
@JsonSerializable()
class GitHubAsset {
  final String name;
  
  @JsonKey(name: 'browser_download_url')
  final String browserDownloadUrl;
  
  final int size;
  
  @JsonKey(name: 'content_type')
  final String contentType;

  const GitHubAsset({
    required this.name,
    required this.browserDownloadUrl,
    required this.size,
    required this.contentType,
  });

  factory GitHubAsset.fromJson(Map<String, dynamic> json) =>
      _$GitHubAssetFromJson(json);

  Map<String, dynamic> toJson() => _$GitHubAssetToJson(this);

  /// Retourne la taille formatée (ex: "25.3 MB")
  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}

