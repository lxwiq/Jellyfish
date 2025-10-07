// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jellyseerr_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JellyseerrRequest _$JellyseerrRequestFromJson(Map<String, dynamic> json) =>
    JellyseerrRequest(
      id: (json['id'] as num).toInt(),
      status: _requestStatusFromJson(json['status']),
      media: MediaInfo.fromJson(json['media'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      requestedBy: json['requestedBy'] == null
          ? null
          : RequestedBy.fromJson(json['requestedBy'] as Map<String, dynamic>),
      seasonCount: (json['seasonCount'] as num?)?.toInt(),
      seasons: (json['seasons'] as List<dynamic>?)
          ?.map((e) => Season.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$JellyseerrRequestToJson(JellyseerrRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'media': instance.media,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'requestedBy': instance.requestedBy,
      'seasonCount': instance.seasonCount,
      'seasons': instance.seasons,
    };

MediaInfo _$MediaInfoFromJson(Map<String, dynamic> json) => MediaInfo(
      id: (json['id'] as num).toInt(),
      tmdbId: (json['tmdbId'] as num?)?.toInt(),
      tvdbId: (json['tvdbId'] as num?)?.toInt(),
      status: _mediaStatusFromJson(json['status']),
      mediaType: _mediaTypeFromJson(json['mediaType']),
      title: json['title'] as String?,
      originalTitle: json['originalTitle'] as String?,
      overview: json['overview'] as String?,
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      releaseDate: json['releaseDate'] as String?,
      voteAverage: (json['voteAverage'] as num?)?.toDouble(),
      voteCount: (json['voteCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MediaInfoToJson(MediaInfo instance) => <String, dynamic>{
      'id': instance.id,
      'tmdbId': instance.tmdbId,
      'tvdbId': instance.tvdbId,
      'status': instance.status,
      'mediaType': instance.mediaType,
      'title': instance.title,
      'originalTitle': instance.originalTitle,
      'overview': instance.overview,
      'posterPath': instance.posterPath,
      'backdropPath': instance.backdropPath,
      'releaseDate': instance.releaseDate,
      'voteAverage': instance.voteAverage,
      'voteCount': instance.voteCount,
    };

RequestedBy _$RequestedByFromJson(Map<String, dynamic> json) => RequestedBy(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      avatar: json['avatar'] as String?,
    );

Map<String, dynamic> _$RequestedByToJson(RequestedBy instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'displayName': instance.displayName,
      'avatar': instance.avatar,
    };

Season _$SeasonFromJson(Map<String, dynamic> json) => Season(
      id: (json['id'] as num).toInt(),
      seasonNumber: (json['seasonNumber'] as num).toInt(),
      status: _mediaStatusFromJson(json['status']),
    );

Map<String, dynamic> _$SeasonToJson(Season instance) => <String, dynamic>{
      'id': instance.id,
      'seasonNumber': instance.seasonNumber,
      'status': instance.status,
    };

JellyseerrRequestsResponse _$JellyseerrRequestsResponseFromJson(
        Map<String, dynamic> json) =>
    JellyseerrRequestsResponse(
      results: (json['results'] as List<dynamic>)
          .map((e) => JellyseerrRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
      pageInfo: PageInfo.fromJson(json['pageInfo'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$JellyseerrRequestsResponseToJson(
        JellyseerrRequestsResponse instance) =>
    <String, dynamic>{
      'results': instance.results,
      'pageInfo': instance.pageInfo,
    };

PageInfo _$PageInfoFromJson(Map<String, dynamic> json) => PageInfo(
      pages: (json['pages'] as num).toInt(),
      pageSize: (json['pageSize'] as num).toInt(),
      results: (json['results'] as num).toInt(),
      page: (json['page'] as num).toInt(),
    );

Map<String, dynamic> _$PageInfoToJson(PageInfo instance) => <String, dynamic>{
      'pages': instance.pages,
      'pageSize': instance.pageSize,
      'results': instance.results,
      'page': instance.page,
    };

JellyseerrAuthResponse _$JellyseerrAuthResponseFromJson(
        Map<String, dynamic> json) =>
    JellyseerrAuthResponse(
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      id: (json['id'] as num?)?.toInt(),
      avatar: json['avatar'] as String?,
    );

Map<String, dynamic> _$JellyseerrAuthResponseToJson(
        JellyseerrAuthResponse instance) =>
    <String, dynamic>{
      'email': instance.email,
      'displayName': instance.displayName,
      'id': instance.id,
      'avatar': instance.avatar,
    };

CreateRequestBody _$CreateRequestBodyFromJson(Map<String, dynamic> json) =>
    CreateRequestBody(
      mediaId: (json['mediaId'] as num).toInt(),
      mediaType: json['mediaType'] as String,
      seasons: (json['seasons'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      is4k: json['is4k'] as bool?,
    );

Map<String, dynamic> _$CreateRequestBodyToJson(CreateRequestBody instance) =>
    <String, dynamic>{
      'mediaId': instance.mediaId,
      'mediaType': instance.mediaType,
      'seasons': instance.seasons,
      'is4k': instance.is4k,
    };

MediaSearchResult _$MediaSearchResultFromJson(Map<String, dynamic> json) =>
    MediaSearchResult(
      id: (json['id'] as num).toInt(),
      mediaType: json['mediaType'] as String,
      title: json['title'] as String?,
      name: json['name'] as String?,
      originalTitle: json['originalTitle'] as String?,
      originalName: json['originalName'] as String?,
      overview: json['overview'] as String?,
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      releaseDate: json['releaseDate'] as String?,
      firstAirDate: json['firstAirDate'] as String?,
      voteAverage: (json['voteAverage'] as num?)?.toDouble(),
      voteCount: (json['voteCount'] as num?)?.toInt(),
      mediaInfo: json['mediaInfo'] == null
          ? null
          : MediaInfo.fromJson(json['mediaInfo'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MediaSearchResultToJson(MediaSearchResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mediaType': instance.mediaType,
      'title': instance.title,
      'name': instance.name,
      'originalTitle': instance.originalTitle,
      'originalName': instance.originalName,
      'overview': instance.overview,
      'posterPath': instance.posterPath,
      'backdropPath': instance.backdropPath,
      'releaseDate': instance.releaseDate,
      'firstAirDate': instance.firstAirDate,
      'voteAverage': instance.voteAverage,
      'voteCount': instance.voteCount,
      'mediaInfo': instance.mediaInfo,
    };

SearchResponse _$SearchResponseFromJson(Map<String, dynamic> json) =>
    SearchResponse(
      page: (json['page'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
      totalResults: (json['totalResults'] as num).toInt(),
      results: (json['results'] as List<dynamic>)
          .map((e) => MediaSearchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SearchResponseToJson(SearchResponse instance) =>
    <String, dynamic>{
      'page': instance.page,
      'totalPages': instance.totalPages,
      'totalResults': instance.totalResults,
      'results': instance.results,
    };

CastMember _$CastMemberFromJson(Map<String, dynamic> json) => CastMember(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String?,
      character: json['character'] as String?,
      profilePath: json['profilePath'] as String?,
      order: (json['order'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CastMemberToJson(CastMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'character': instance.character,
      'profilePath': instance.profilePath,
      'order': instance.order,
    };

CrewMember _$CrewMemberFromJson(Map<String, dynamic> json) => CrewMember(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String?,
      job: json['job'] as String?,
      department: json['department'] as String?,
      profilePath: json['profilePath'] as String?,
    );

Map<String, dynamic> _$CrewMemberToJson(CrewMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'job': instance.job,
      'department': instance.department,
      'profilePath': instance.profilePath,
    };

Genre _$GenreFromJson(Map<String, dynamic> json) => Genre(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$GenreToJson(Genre instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

ProductionCompany _$ProductionCompanyFromJson(Map<String, dynamic> json) =>
    ProductionCompany(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String?,
      logoPath: json['logoPath'] as String?,
      originCountry: json['originCountry'] as String?,
    );

Map<String, dynamic> _$ProductionCompanyToJson(ProductionCompany instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'logoPath': instance.logoPath,
      'originCountry': instance.originCountry,
    };

MovieDetails _$MovieDetailsFromJson(Map<String, dynamic> json) => MovieDetails(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String?,
      originalTitle: json['originalTitle'] as String?,
      overview: json['overview'] as String?,
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      releaseDate: json['releaseDate'] as String?,
      voteAverage: (json['voteAverage'] as num?)?.toDouble(),
      voteCount: (json['voteCount'] as num?)?.toInt(),
      runtime: (json['runtime'] as num?)?.toInt(),
      status: json['status'] as String?,
      tagline: json['tagline'] as String?,
      genres: (json['genres'] as List<dynamic>?)
          ?.map((e) => Genre.fromJson(e as Map<String, dynamic>))
          .toList(),
      productionCompanies: (json['productionCompanies'] as List<dynamic>?)
          ?.map((e) => ProductionCompany.fromJson(e as Map<String, dynamic>))
          .toList(),
      mediaInfo: json['mediaInfo'] == null
          ? null
          : MediaInfo.fromJson(json['mediaInfo'] as Map<String, dynamic>),
      credits: json['credits'] == null
          ? null
          : Credits.fromJson(json['credits'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MovieDetailsToJson(MovieDetails instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'originalTitle': instance.originalTitle,
      'overview': instance.overview,
      'posterPath': instance.posterPath,
      'backdropPath': instance.backdropPath,
      'releaseDate': instance.releaseDate,
      'voteAverage': instance.voteAverage,
      'voteCount': instance.voteCount,
      'runtime': instance.runtime,
      'status': instance.status,
      'tagline': instance.tagline,
      'genres': instance.genres,
      'productionCompanies': instance.productionCompanies,
      'mediaInfo': instance.mediaInfo,
      'credits': instance.credits,
    };

TvDetails _$TvDetailsFromJson(Map<String, dynamic> json) => TvDetails(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String?,
      originalName: json['originalName'] as String?,
      overview: json['overview'] as String?,
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      firstAirDate: json['firstAirDate'] as String?,
      lastAirDate: json['lastAirDate'] as String?,
      voteAverage: (json['voteAverage'] as num?)?.toDouble(),
      voteCount: (json['voteCount'] as num?)?.toInt(),
      numberOfSeasons: (json['numberOfSeasons'] as num?)?.toInt(),
      numberOfEpisodes: (json['numberOfEpisodes'] as num?)?.toInt(),
      status: json['status'] as String?,
      tagline: json['tagline'] as String?,
      episodeRunTime: (json['episodeRunTime'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      genres: (json['genres'] as List<dynamic>?)
          ?.map((e) => Genre.fromJson(e as Map<String, dynamic>))
          .toList(),
      networks: (json['networks'] as List<dynamic>?)
          ?.map((e) => ProductionCompany.fromJson(e as Map<String, dynamic>))
          .toList(),
      productionCompanies: (json['productionCompanies'] as List<dynamic>?)
          ?.map((e) => ProductionCompany.fromJson(e as Map<String, dynamic>))
          .toList(),
      mediaInfo: json['mediaInfo'] == null
          ? null
          : MediaInfo.fromJson(json['mediaInfo'] as Map<String, dynamic>),
      credits: json['credits'] == null
          ? null
          : Credits.fromJson(json['credits'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TvDetailsToJson(TvDetails instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'originalName': instance.originalName,
      'overview': instance.overview,
      'posterPath': instance.posterPath,
      'backdropPath': instance.backdropPath,
      'firstAirDate': instance.firstAirDate,
      'lastAirDate': instance.lastAirDate,
      'voteAverage': instance.voteAverage,
      'voteCount': instance.voteCount,
      'numberOfSeasons': instance.numberOfSeasons,
      'numberOfEpisodes': instance.numberOfEpisodes,
      'status': instance.status,
      'tagline': instance.tagline,
      'episodeRunTime': instance.episodeRunTime,
      'genres': instance.genres,
      'networks': instance.networks,
      'productionCompanies': instance.productionCompanies,
      'mediaInfo': instance.mediaInfo,
      'credits': instance.credits,
    };

Credits _$CreditsFromJson(Map<String, dynamic> json) => Credits(
      cast: (json['cast'] as List<dynamic>?)
          ?.map((e) => CastMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      crew: (json['crew'] as List<dynamic>?)
          ?.map((e) => CrewMember.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CreditsToJson(Credits instance) => <String, dynamic>{
      'cast': instance.cast,
      'crew': instance.crew,
    };
