import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:jellyfish/models/jellyseerr_models.dart';
import 'package:jellyfish/services/logger_service.dart';

import 'package:jellyfish/services/custom_http_client.dart';

/// Service pour interagir avec l'API Jellyseerr
class JellyseerrService {
  String? _serverUrl;
  String? _cookie;
  final http.Client _httpClient;

  JellyseerrService() : _httpClient = CustomHttpClient();

  /// Initialise le service avec l'URL du serveur
  void initializeClient(String serverUrl, {String? cookie}) {
    _serverUrl = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;
    _cookie = cookie;

    LoggerService.instance.info('Initialisation du client Jellyseerr');
    LoggerService.instance.debug('Server URL: $_serverUrl');
    LoggerService.instance.debug('Has Cookie: ${_cookie != null}');
  }

  /// Authentifie un utilisateur avec les credentials Jellyfin
  /// Retourne un tuple (JellyseerrAuthResponse, cookie) en cas de succès
  Future<(JellyseerrAuthResponse, String)> authenticate(
    String username,
    String password,
  ) async {
    if (_serverUrl == null) {
      throw Exception(
          'Client non initialisé. Appelez initializeClient() d\'abord.');
    }

    try {
      await LoggerService.instance.info('Tentative d\'authentification Jellyseerr pour: $username');
      await LoggerService.instance.info('URL du serveur: $_serverUrl');

      final url = Uri.parse('$_serverUrl/api/v1/auth/jellyfin');
      final response = await _httpClient.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      await LoggerService.instance.info('Réponse reçue - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Extraire le cookie de la réponse
        final cookies = response.headers['set-cookie'];
        if (cookies == null || cookies.isEmpty) {
          throw Exception('Aucun cookie reçu dans la réponse');
        }

        // Parser le cookie (prendre seulement la partie avant le premier ;)
        final cookie = cookies.split(';').first;
        _cookie = cookie;

        await LoggerService.instance.info('Authentification Jellyseerr réussie');
        await LoggerService.instance.debug('Cookie: ${cookie.substring(0, 20)}...');

        final authResponse =
            JellyseerrAuthResponse.fromJson(jsonDecode(response.body));

        return (authResponse, cookie);
      } else if (response.statusCode == 401) {
        throw Exception('Identifiants invalides');
      } else if (response.statusCode == 500) {
        throw Exception(
            'Erreur serveur Jellyseerr. Vérifiez que Jellyseerr est correctement configuré avec Jellyfin.');
      } else {
        throw Exception(
            'Erreur d\'authentification: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      await LoggerService.instance.error('Erreur d\'authentification Jellyseerr', error: e);
      rethrow;
    }
  }

  /// Récupère la liste des requêtes
  Future<JellyseerrRequestsResponse> getRequests({
    int take = 20,
    int skip = 0,
    String? filter,
    String? sort,
  }) async {
    if (_serverUrl == null || _cookie == null) {
      throw Exception('Non authentifié. Appelez authenticate() d\'abord.');
    }

    try {
      final queryParams = {
        'take': take.toString(),
        'skip': skip.toString(),
        if (filter != null) 'filter': filter,
        if (sort != null) 'sort': sort,
      };

      final url = Uri.parse('$_serverUrl/api/v1/request')
          .replace(queryParameters: queryParams);

      await LoggerService.instance.info('Récupération des requêtes: $url');

      final response = await _httpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': _cookie!,
        },
      );

      await LoggerService.instance.info('Réponse reçue - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await LoggerService.instance.debug('Données JSON reçues: ${jsonEncode(data)}');
        try {
          return JellyseerrRequestsResponse.fromJson(data);
        } catch (e, stackTrace) {
          await LoggerService.instance.error('Erreur lors du parsing JSON', error: e, stackTrace: stackTrace);
          await LoggerService.instance.debug('Stack trace: $stackTrace');
          await LoggerService.instance.debug('Données brutes: ${response.body}');
          rethrow;
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception(
            'Erreur lors de la récupération des requêtes: ${response.statusCode}');
      }
    } catch (e) {
      await LoggerService.instance.error('Erreur lors de la récupération des requêtes', error: e);
      rethrow;
    }
  }

  /// Crée une nouvelle requête de média
  Future<JellyseerrRequest> createRequest(CreateRequestBody request) async {
    if (_serverUrl == null || _cookie == null) {
      throw Exception('Non authentifié. Appelez authenticate() d\'abord.');
    }

    try {
      final url = Uri.parse('$_serverUrl/api/v1/request');

      await LoggerService.instance.info('Creation d\'une nouvelle requete');
      await LoggerService.instance.debug('Media ID: ${request.mediaId}');
      await LoggerService.instance.debug('Media Type: ${request.mediaType}');

      final response = await _httpClient.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': _cookie!,
        },
        body: jsonEncode(request.toJson()),
      );

      await LoggerService.instance.info('Reponse recue - Status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return JellyseerrRequest.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else if (response.statusCode == 409) {
        throw Exception('Ce média a déjà été demandé.');
      } else {
        throw Exception(
            'Erreur lors de la création de la requête: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      await LoggerService.instance.error('Erreur lors de la creation de la requete', error: e);
      rethrow;
    }
  }

  /// Recherche des médias
  Future<SearchResponse> searchMedia(String query, {int page = 1}) async {
    if (_serverUrl == null || _cookie == null) {
      throw Exception('Non authentifié. Appelez authenticate() d\'abord.');
    }

    try {
      final url = Uri.parse('$_serverUrl/api/v1/search')
          .replace(queryParameters: {
        'query': query,
        'page': page.toString(),
      });

      await LoggerService.instance.info('Recherche de médias: $query');

      final response = await _httpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': _cookie!,
        },
      );

      await LoggerService.instance.info('Réponse reçue - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SearchResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception(
            'Erreur lors de la recherche: ${response.statusCode}');
      }
    } catch (e) {
      await LoggerService.instance.error('Erreur lors de la recherche', error: e);
      rethrow;
    }
  }

  /// Récupère les détails d'un média
  Future<MediaSearchResult> getMediaDetails(
      int mediaId, String mediaType) async {
    if (_serverUrl == null || _cookie == null) {
      throw Exception('Non authentifié. Appelez authenticate() d\'abord.');
    }

    try {
      final url = Uri.parse('$_serverUrl/api/v1/$mediaType/$mediaId');

      await LoggerService.instance.info('Recuperation des details du media: $mediaId ($mediaType)');

      final response = await _httpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': _cookie!,
        },
      );

      await LoggerService.instance.info('Reponse recue - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MediaSearchResult.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception(
            'Erreur lors de la récupération des détails: ${response.statusCode}');
      }
    } catch (e) {
      await LoggerService.instance.error('Erreur lors de la recuperation des details', error: e);
      rethrow;
    }
  }

  /// Supprime une requête
  Future<void> deleteRequest(int requestId) async {
    if (_serverUrl == null || _cookie == null) {
      throw Exception('Non authentifié. Appelez authenticate() d\'abord.');
    }

    try {
      final url = Uri.parse('$_serverUrl/api/v1/request/$requestId');

      await LoggerService.instance.info('Suppression de la requete: $requestId');

      final response = await _httpClient.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': _cookie!,
        },
      );

      await LoggerService.instance.info('Reponse recue - Status: ${response.statusCode}');

      if (response.statusCode == 204 || response.statusCode == 200) {
        await LoggerService.instance.info('Requete supprimee avec succes');
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception(
            'Erreur lors de la suppression: ${response.statusCode}');
      }
    } catch (e) {
      await LoggerService.instance.error('Erreur lors de la suppression', error: e);
      rethrow;
    }
  }

  /// Récupère les médias trending
  Future<SearchResponse> getTrending({
    int page = 1,
    List<int>? genres,
    String? sortBy,
  }) async {
    if (_serverUrl == null || _cookie == null) {
      throw Exception('Non authentifié. Appelez authenticate() d\'abord.');
    }

    try {
      final queryParams = <String, String>{'page': page.toString()};

      if (genres != null && genres.isNotEmpty) {
        queryParams['with_genres'] = genres.join(',');
      }

      if (sortBy != null) {
        queryParams['sort_by'] = sortBy;
      }

      final url = Uri.parse('$_serverUrl/api/v1/discover/trending')
          .replace(queryParameters: queryParams);

      await LoggerService.instance.info('Recuperation des medias trending (page $page, genres: $genres)');

      final response = await _httpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': _cookie!,
        },
      );

      await LoggerService.instance.info('Reponse recue - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SearchResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception(
            'Erreur lors de la récupération des trending: ${response.statusCode}');
      }
    } catch (e) {
      await LoggerService.instance.error('Erreur lors de la recuperation des trending', error: e);
      rethrow;
    }
  }

  /// Récupère les films populaires
  Future<SearchResponse> getPopularMovies({
    int page = 1,
    List<int>? genres,
    String? sortBy,
  }) async {
    if (_serverUrl == null || _cookie == null) {
      throw Exception('Non authentifié. Appelez authenticate() d\'abord.');
    }

    try {
      final queryParams = <String, String>{'page': page.toString()};

      if (genres != null && genres.isNotEmpty) {
        queryParams['with_genres'] = genres.join(',');
      }

      if (sortBy != null) {
        queryParams['sort_by'] = sortBy;
      }

      final url = Uri.parse('$_serverUrl/api/v1/discover/movies')
          .replace(queryParameters: queryParams);

      await LoggerService.instance.info('Recuperation des films populaires (page $page, genres: $genres)');

      final response = await _httpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': _cookie!,
        },
      );

      await LoggerService.instance.info('Reponse recue - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SearchResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception(
            'Erreur lors de la récupération des films: ${response.statusCode}');
      }
    } catch (e) {
      await LoggerService.instance.error('Erreur lors de la recuperation des films', error: e);
      rethrow;
    }
  }

  /// Récupère les séries TV populaires
  Future<SearchResponse> getPopularTv({
    int page = 1,
    List<int>? genres,
    String? sortBy,
  }) async {
    if (_serverUrl == null || _cookie == null) {
      throw Exception('Non authentifié. Appelez authenticate() d\'abord.');
    }

    try {
      final queryParams = <String, String>{'page': page.toString()};

      if (genres != null && genres.isNotEmpty) {
        queryParams['with_genres'] = genres.join(',');
      }

      if (sortBy != null) {
        queryParams['sort_by'] = sortBy;
      }

      final url = Uri.parse('$_serverUrl/api/v1/discover/tv')
          .replace(queryParameters: queryParams);

      await LoggerService.instance.info('Recuperation des series TV populaires (page $page, genres: $genres)');

      final response = await _httpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': _cookie!,
        },
      );

      await LoggerService.instance.info('Reponse recue - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SearchResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception(
            'Erreur lors de la récupération des séries: ${response.statusCode}');
      }
    } catch (e) {
      await LoggerService.instance.error('Erreur lors de la recuperation des series', error: e);
      rethrow;
    }
  }

  /// Récupère la liste des genres disponibles pour les films
  Future<List<Genre>> getMovieGenres() async {
    if (_serverUrl == null || _cookie == null) {
      throw Exception('Non authentifié. Appelez authenticate() d\'abord.');
    }

    try {
      final url = Uri.parse('$_serverUrl/api/v1/genres/movie');

      await LoggerService.instance.info('Recuperation des genres de films');

      final response = await _httpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': _cookie!,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((json) => Genre.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception(
            'Erreur lors de la récupération des genres: ${response.statusCode}');
      }
    } catch (e) {
      await LoggerService.instance.error('Erreur lors de la recuperation des genres', error: e);
      rethrow;
    }
  }

  /// Récupère la liste des genres disponibles pour les séries TV
  Future<List<Genre>> getTvGenres() async {
    if (_serverUrl == null || _cookie == null) {
      throw Exception('Non authentifié. Appelez authenticate() d\'abord.');
    }

    try {
      final url = Uri.parse('$_serverUrl/api/v1/genres/tv');

      await LoggerService.instance.info('Recuperation des genres de series TV');

      final response = await _httpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': _cookie!,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((json) => Genre.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception(
            'Erreur lors de la récupération des genres: ${response.statusCode}');
      }
    } catch (e) {
      await LoggerService.instance.error('Erreur lors de la recuperation des genres', error: e);
      rethrow;
    }
  }

  /// Récupère les détails complets d'un film
  Future<MovieDetails> getMovieDetails(int movieId) async {
    if (_serverUrl == null || _cookie == null) {
      throw Exception('Non authentifié. Appelez authenticate() d\'abord.');
    }

    try {
      final url = Uri.parse('$_serverUrl/api/v1/movie/$movieId');

      await LoggerService.instance.info('Recuperation des details du film $movieId');

      final response = await _httpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': _cookie!,
        },
      );

      await LoggerService.instance.info('Reponse recue - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MovieDetails.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception(
            'Erreur lors de la récupération du film: ${response.statusCode}');
      }
    } catch (e) {
      await LoggerService.instance.error('Erreur lors de la recuperation du film', error: e);
      rethrow;
    }
  }

  /// Récupère les détails complets d'une série TV
  Future<TvDetails> getTvDetails(int tvId) async {
    if (_serverUrl == null || _cookie == null) {
      throw Exception('Non authentifié. Appelez authenticate() d\'abord.');
    }

    try {
      final url = Uri.parse('$_serverUrl/api/v1/tv/$tvId');

      await LoggerService.instance.info('Recuperation des details de la serie $tvId');

      final response = await _httpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': _cookie!,
        },
      );

      await LoggerService.instance.info('Reponse recue - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TvDetails.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception(
            'Erreur lors de la récupération de la série: ${response.statusCode}');
      }
    } catch (e) {
      await LoggerService.instance.error('Erreur lors de la recuperation de la serie', error: e);
      rethrow;
    }
  }

  /// Récupère les recommandations pour un film
  Future<SearchResponse> getMovieRecommendations(int movieId,
      {int page = 1}) async {
    if (_serverUrl == null || _cookie == null) {
      throw Exception('Non authentifié. Appelez authenticate() d\'abord.');
    }

    try {
      final url = Uri.parse('$_serverUrl/api/v1/movie/$movieId/recommendations')
          .replace(queryParameters: {'page': page.toString()});

      await LoggerService.instance.info('Recuperation des recommandations pour le film $movieId');

      final response = await _httpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': _cookie!,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SearchResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception(
            'Erreur lors de la récupération des recommandations: ${response.statusCode}');
      }
    } catch (e) {
      await LoggerService.instance.error('Erreur lors de la recuperation des recommandations', error: e);
      rethrow;
    }
  }

  /// Récupère les recommandations pour une série TV
  Future<SearchResponse> getTvRecommendations(int tvId,
      {int page = 1}) async {
    if (_serverUrl == null || _cookie == null) {
      throw Exception('Non authentifié. Appelez authenticate() d\'abord.');
    }

    try {
      final url = Uri.parse('$_serverUrl/api/v1/tv/$tvId/recommendations')
          .replace(queryParameters: {'page': page.toString()});

      await LoggerService.instance.info('Recuperation des recommandations pour la serie $tvId');

      final response = await _httpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': _cookie!,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SearchResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception(
            'Erreur lors de la récupération des recommandations: ${response.statusCode}');
      }
    } catch (e) {
      await LoggerService.instance.error('Erreur lors de la recuperation des recommandations', error: e);
      rethrow;
    }
  }

  /// Nettoie les ressources
  void dispose() {
    _httpClient.close();
  }
}

