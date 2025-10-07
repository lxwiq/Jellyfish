// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_release.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GitHubRelease _$GitHubReleaseFromJson(Map<String, dynamic> json) =>
    GitHubRelease(
      tagName: json['tag_name'] as String,
      name: json['name'] as String,
      body: json['body'] as String,
      publishedAt: json['published_at'] as String,
      htmlUrl: json['html_url'] as String,
      prerelease: json['prerelease'] as bool,
      draft: json['draft'] as bool,
      assets: (json['assets'] as List<dynamic>)
          .map((e) => GitHubAsset.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GitHubReleaseToJson(GitHubRelease instance) =>
    <String, dynamic>{
      'tag_name': instance.tagName,
      'name': instance.name,
      'body': instance.body,
      'published_at': instance.publishedAt,
      'html_url': instance.htmlUrl,
      'prerelease': instance.prerelease,
      'draft': instance.draft,
      'assets': instance.assets,
    };

GitHubAsset _$GitHubAssetFromJson(Map<String, dynamic> json) => GitHubAsset(
      name: json['name'] as String,
      browserDownloadUrl: json['browser_download_url'] as String,
      size: (json['size'] as num).toInt(),
      contentType: json['content_type'] as String,
    );

Map<String, dynamic> _$GitHubAssetToJson(GitHubAsset instance) =>
    <String, dynamic>{
      'name': instance.name,
      'browser_download_url': instance.browserDownloadUrl,
      'size': instance.size,
      'content_type': instance.contentType,
    };
