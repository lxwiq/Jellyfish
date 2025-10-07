import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jellyfish/models/jellyseerr_models.dart';
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

    print('🔧 Initialisation du client Jellyseerr');
    print('   Server URL: $_serverUrl');
    print('   Has Cookie: ${_cookie != null}');
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
      print('🔐 Tentative d\'authentification Jellyseerr pour: $username');
      print('🌐 URL du serveur: $_serverUrl');

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

      print('📥 Réponse reçue - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Extraire le cookie de la réponse
        final cookies = response.headers['set-cookie'];
        if (cookies == null || cookies.isEmpty) {
          throw Exception('Aucun cookie reçu dans la réponse');
        }

        // Parser le cookie (prendre seulement la partie avant le premier ;)
        final cookie = cookies.split(';').first;
        _cookie = cookie;

        print('✅ Authentification Jellyseerr réussie');
        print('   Cookie: ${cookie.substring(0, 20)}...');

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
      print('❌ Erreur d\'authentification Jellyseerr: $e');
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

      print('📡 Récupération des requêtes: $url');

      final response = await _httpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': _cookie!,
        },
      );

      print('📥 Réponse reçue - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📦 Données JSON reçues: ${jsonEncode(data)}');
        try {
          return JellyseerrRequestsResponse.fromJson(data);
        } catch (e, stackTrace) {
          print('❌ Erreur lors du parsing JSON: $e');
          print('📋 Stack trace: $stackTrace');
          print('📦 Données brutes: ${response.body}');
          rethrow;
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception(
            'Erreur lors de la récupération des requêtes: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération des requêtes: $e');
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

      print('📡 Création d\'une nouvelle requête');
      print('   Media ID: ${request.mediaId}');
      print('   Media Type: ${request.mediaType}');

      final response = await _httpClient.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': _cookie!,
        },
        body: jsonEncode(request.toJson()),
      );

      print('📥 Réponse reçue - Status: ${response.statusCode}');

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
      print('❌ Erreur lors de la création de la requête: $e');
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

      print('🔍 Recherche de médias: $query');

      final response = await _httpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': _cookie!,
        },
      );

      print('📥 Réponse reçue - Status: ${response.statusCode}');

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
      print('❌ Erreur lors de la recherche: $e');
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

      print('📡 Récupération des détails du média: $mediaId ($mediaType)');

      final response = await _httpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': _cookie!,
        },
      );

      print('📥 Réponse reçue - Status: ${response.statusCode}');

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
      print('❌ Erreur lors de la récupération des détails: $e');
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

      print('🗑️ Suppression de la requête: $requestId');

      final response = await _httpClient.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': _cookie!,
        },
      );

      print('📥 Réponse reçue - Status: ${response.statusCode}');

      if (response.statusCode == 204 || response.statusCode == 200) {
        print('✅ Requête supprimée avec succès');
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception(
            'Erreur lors de la suppression: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur lors de la suppression: $e');
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

      print('🔥 Récupération des médias trending (page $page, genres: $genres)');

      final response = await _httpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': _cookie!,
        },
      );

      print('📥 Réponse reçue - Status: ${response.statusCode}');

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
      print('❌ Erreur lors de la récupération des trending: $e');
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

      print('🎬 Récupération des films populaires (page $page, genres: $genres)');

      final response = await _httpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': _cookie!,
        },
      );

      print('📥 Réponse reçue - Status: ${response.statusCode}');

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
      print('❌ Erreur lors de la récupération des films: $e');
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

      print('📺 Récupération des séries TV populaires (page $page, genres: $genres)');

      final response = await _httpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': _cookie!,
        },
      );

      print('📥 Réponse reçue - Status: ${response.statusCode}');

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
      print('❌ Erreur lors de la récupération des séries: $e');
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

      print('🎭 Récupération des genres de films');

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
      print('❌ Erreur lors de la récupération des genres: $e');
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

      print('🎭 Récupération des genres de séries TV');

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
      print('❌ Erreur lors de la récupération des genres: $e');
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

      print('🎬 Récupération des détails du film $movieId');

      final response = await _httpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': _cookie!,
        },
      );

      print('📥 Réponse reçue - Status: ${response.statusCode}');

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
      print('❌ Erreur lors de la récupération du film: $e');
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

      print('📺 Récupération des détails de la série $tvId');

      final response = await _httpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': _cookie!,
        },
      );

      print('📥 Réponse reçue - Status: ${response.statusCode}');

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
      print('❌ Erreur lors de la récupération de la série: $e');
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

      print('🎬 Récupération des recommandations pour le film $movieId');

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
      print('❌ Erreur lors de la récupération des recommandations: $e');
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

      print('📺 Récupération des recommandations pour la série $tvId');

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
      print('❌ Erreur lors de la récupération des recommandations: $e');
      rethrow;
    }
  }

  /// Nettoie les ressources
  void dispose() {
    _httpClient.close();
  }
}

