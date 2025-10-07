import 'package:json_annotation/json_annotation.dart';

part 'jellyseerr_models.g.dart';

// Fonctions de conversion pour gérer les types dynamiques de l'API Jellyseerr
String _requestStatusFromJson(dynamic value) {
  if (value is int) {
    // Convertir les codes numériques en chaînes
    switch (value) {
      case 1:
        return 'pending';
      case 2:
        return 'approved';
      case 3:
        return 'declined';
      case 4:
        return 'available';
      default:
        return value.toString();
    }
  }
  return value.toString();
}

String _mediaStatusFromJson(dynamic value) {
  if (value is int) {
    // Convertir les codes numériques en chaînes
    switch (value) {
      case 1:
        return 'unknown';
      case 2:
        return 'pending';
      case 3:
        return 'processing';
      case 4:
        return 'partially_available';
      case 5:
        return 'available';
      default:
        return value.toString();
    }
  }
  return value.toString();
}

String _mediaTypeFromJson(dynamic value) {
  if (value is int) {
    // Convertir les codes numériques en chaînes
    return value == 1 ? 'movie' : 'tv';
  }
  return value.toString();
}

/// Modèle pour une requête Jellyseerr
@JsonSerializable()
class JellyseerrRequest {
  final int id;
  @JsonKey(fromJson: _requestStatusFromJson)
  final String status;
  final MediaInfo media;
  final DateTime createdAt;
  final DateTime updatedAt;
  final RequestedBy? requestedBy;
  final int? seasonCount;
  final List<Season>? seasons;

  JellyseerrRequest({
    required this.id,
    required this.status,
    required this.media,
    required this.createdAt,
    required this.updatedAt,
    this.requestedBy,
    this.seasonCount,
    this.seasons,
  });

  factory JellyseerrRequest.fromJson(Map<String, dynamic> json) =>
      _$JellyseerrRequestFromJson(json);

  Map<String, dynamic> toJson() => _$JellyseerrRequestToJson(this);
}

/// Informations sur le média demandé
@JsonSerializable()
class MediaInfo {
  final int id;
  final int? tmdbId;
  final int? tvdbId;
  @JsonKey(fromJson: _mediaStatusFromJson)
  final String status;
  @JsonKey(fromJson: _mediaTypeFromJson)
  final String mediaType;
  final String? title;
  final String? originalTitle;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double? voteAverage;
  final int? voteCount;

  MediaInfo({
    required this.id,
    this.tmdbId,
    this.tvdbId,
    required this.status,
    required this.mediaType,
    this.title,
    this.originalTitle,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.voteAverage,
    this.voteCount,
  });

  factory MediaInfo.fromJson(Map<String, dynamic> json) =>
      _$MediaInfoFromJson(json);

  Map<String, dynamic> toJson() => _$MediaInfoToJson(this);
}

/// Informations sur l'utilisateur qui a fait la requête
@JsonSerializable()
class RequestedBy {
  final int id;
  final String? email;
  final String? displayName;
  final String? avatar;

  RequestedBy({
    required this.id,
    this.email,
    this.displayName,
    this.avatar,
  });

  factory RequestedBy.fromJson(Map<String, dynamic> json) =>
      _$RequestedByFromJson(json);

  Map<String, dynamic> toJson() => _$RequestedByToJson(this);
}

/// Informations sur une saison (pour les séries TV)
@JsonSerializable()
class Season {
  final int id;
  final int seasonNumber;
  @JsonKey(fromJson: _mediaStatusFromJson)
  final String status;

  Season({
    required this.id,
    required this.seasonNumber,
    required this.status,
  });

  factory Season.fromJson(Map<String, dynamic> json) =>
      _$SeasonFromJson(json);

  Map<String, dynamic> toJson() => _$SeasonToJson(this);
}

/// Réponse de la liste des requêtes
@JsonSerializable()
class JellyseerrRequestsResponse {
  final List<JellyseerrRequest> results;
  final PageInfo pageInfo;

  JellyseerrRequestsResponse({
    required this.results,
    required this.pageInfo,
  });

  factory JellyseerrRequestsResponse.fromJson(Map<String, dynamic> json) =>
      _$JellyseerrRequestsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$JellyseerrRequestsResponseToJson(this);
}

/// Informations de pagination
@JsonSerializable()
class PageInfo {
  final int pages;
  final int pageSize;
  final int results;
  final int page;

  PageInfo({
    required this.pages,
    required this.pageSize,
    required this.results,
    required this.page,
  });

  factory PageInfo.fromJson(Map<String, dynamic> json) =>
      _$PageInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PageInfoToJson(this);
}

/// Réponse d'authentification Jellyseerr
@JsonSerializable()
class JellyseerrAuthResponse {
  final String? email;
  final String? displayName;
  final int? id;
  final String? avatar;

  JellyseerrAuthResponse({
    this.email,
    this.displayName,
    this.id,
    this.avatar,
  });

  factory JellyseerrAuthResponse.fromJson(Map<String, dynamic> json) =>
      _$JellyseerrAuthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$JellyseerrAuthResponseToJson(this);
}

/// Requête de création de demande
@JsonSerializable()
class CreateRequestBody {
  final int mediaId;
  final String mediaType;
  final List<int>? seasons;
  final bool? is4k;

  CreateRequestBody({
    required this.mediaId,
    required this.mediaType,
    this.seasons,
    this.is4k,
  });

  factory CreateRequestBody.fromJson(Map<String, dynamic> json) =>
      _$CreateRequestBodyFromJson(json);

  Map<String, dynamic> toJson() => _$CreateRequestBodyToJson(this);
}

/// Résultat de recherche de média
@JsonSerializable()
class MediaSearchResult {
  final int id;
  final String mediaType;
  final String? title;
  final String? name;
  final String? originalTitle;
  final String? originalName;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final String? firstAirDate;
  final double? voteAverage;
  final int? voteCount;
  final MediaInfo? mediaInfo;

  MediaSearchResult({
    required this.id,
    required this.mediaType,
    this.title,
    this.name,
    this.originalTitle,
    this.originalName,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.firstAirDate,
    this.voteAverage,
    this.voteCount,
    this.mediaInfo,
  });

  factory MediaSearchResult.fromJson(Map<String, dynamic> json) =>
      _$MediaSearchResultFromJson(json);

  Map<String, dynamic> toJson() => _$MediaSearchResultToJson(this);

  String get displayTitle => title ?? name ?? originalTitle ?? originalName ?? 'Unknown';
  String get displayDate => releaseDate ?? firstAirDate ?? '';
}

/// Réponse de recherche
@JsonSerializable()
class SearchResponse {
  final int page;
  final int totalPages;
  final int totalResults;
  final List<MediaSearchResult> results;

  SearchResponse({
    required this.page,
    required this.totalPages,
    required this.totalResults,
    required this.results,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) =>
      _$SearchResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SearchResponseToJson(this);
}

/// Statuts possibles pour une requête
enum RequestStatus {
  pending,
  approved,
  declined,
  available,
}

/// Types de média
enum MediaType {
  movie,
  tv,
}

/// Cast member (acteur)
@JsonSerializable()
class CastMember {
  final int id;
  final String? name;
  final String? character;
  final String? profilePath;
  final int? order;

  CastMember({
    required this.id,
    this.name,
    this.character,
    this.profilePath,
    this.order,
  });

  factory CastMember.fromJson(Map<String, dynamic> json) =>
      _$CastMemberFromJson(json);

  Map<String, dynamic> toJson() => _$CastMemberToJson(this);
}

/// Crew member (équipe technique)
@JsonSerializable()
class CrewMember {
  final int id;
  final String? name;
  final String? job;
  final String? department;
  final String? profilePath;

  CrewMember({
    required this.id,
    this.name,
    this.job,
    this.department,
    this.profilePath,
  });

  factory CrewMember.fromJson(Map<String, dynamic> json) =>
      _$CrewMemberFromJson(json);

  Map<String, dynamic> toJson() => _$CrewMemberToJson(this);
}

/// Genre
@JsonSerializable()
class Genre {
  final int id;
  final String name;

  Genre({
    required this.id,
    required this.name,
  });

  factory Genre.fromJson(Map<String, dynamic> json) =>
      _$GenreFromJson(json);

  Map<String, dynamic> toJson() => _$GenreToJson(this);
}

/// Production company
@JsonSerializable()
class ProductionCompany {
  final int id;
  final String? name;
  final String? logoPath;
  final String? originCountry;

  ProductionCompany({
    required this.id,
    this.name,
    this.logoPath,
    this.originCountry,
  });

  factory ProductionCompany.fromJson(Map<String, dynamic> json) =>
      _$ProductionCompanyFromJson(json);

  Map<String, dynamic> toJson() => _$ProductionCompanyToJson(this);
}

/// Détails complets d'un film
@JsonSerializable()
class MovieDetails {
  final int id;
  final String? title;
  final String? originalTitle;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double? voteAverage;
  final int? voteCount;
  final int? runtime;
  final String? status;
  final String? tagline;
  final List<Genre>? genres;
  final List<ProductionCompany>? productionCompanies;
  final MediaInfo? mediaInfo;
  final Credits? credits;

  MovieDetails({
    required this.id,
    this.title,
    this.originalTitle,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.voteAverage,
    this.voteCount,
    this.runtime,
    this.status,
    this.tagline,
    this.genres,
    this.productionCompanies,
    this.mediaInfo,
    this.credits,
  });

  factory MovieDetails.fromJson(Map<String, dynamic> json) =>
      _$MovieDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$MovieDetailsToJson(this);
}

/// Détails complets d'une série TV
@JsonSerializable()
class TvDetails {
  final int id;
  final String? name;
  final String? originalName;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? firstAirDate;
  final String? lastAirDate;
  final double? voteAverage;
  final int? voteCount;
  final int? numberOfSeasons;
  final int? numberOfEpisodes;
  final String? status;
  final String? tagline;
  final List<int>? episodeRunTime;
  final List<Genre>? genres;
  final List<ProductionCompany>? networks;
  final List<ProductionCompany>? productionCompanies;
  final MediaInfo? mediaInfo;
  final Credits? credits;

  TvDetails({
    required this.id,
    this.name,
    this.originalName,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.firstAirDate,
    this.lastAirDate,
    this.voteAverage,
    this.voteCount,
    this.numberOfSeasons,
    this.numberOfEpisodes,
    this.status,
    this.tagline,
    this.episodeRunTime,
    this.genres,
    this.networks,
    this.productionCompanies,
    this.mediaInfo,
    this.credits,
  });

  factory TvDetails.fromJson(Map<String, dynamic> json) =>
      _$TvDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$TvDetailsToJson(this);
}

/// Credits (cast + crew)
@JsonSerializable()
class Credits {
  final List<CastMember>? cast;
  final List<CrewMember>? crew;

  Credits({
    this.cast,
    this.crew,
  });

  factory Credits.fromJson(Map<String, dynamic> json) =>
      _$CreditsFromJson(json);

  Map<String, dynamic> toJson() => _$CreditsToJson(this);
}
