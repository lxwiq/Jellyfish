import 'package:chopper/chopper.dart' as chopper;
import 'package:jellyfish/jellyfin/jellyfin_open_api.swagger.dart';
import 'package:jellyfish/services/jellyfin_interceptor.dart';
import '../models/user.dart' as app_models;

/// Service pour interagir avec l'API Jellyfin
class JellyfinService {
  JellyfinOpenApi? _api;
  String? _currentServerUrl;
  String? _accessToken;
  String? _deviceId;

  /// Initialise le client API avec l'URL du serveur
  void initializeClient(String serverUrl, {String? accessToken, String? deviceId}) {
    // Nettoyer l'URL (enlever le trailing slash si présent)
    _currentServerUrl = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;

    _accessToken = accessToken;
    _deviceId = deviceId;

    print('🔧 Initialisation du client Jellyfin');
    print('   Server URL: $_currentServerUrl');
    print('   Device ID: $_deviceId');
    print('   Has Token: ${_accessToken != null}');

    // Créer l'API avec l'URL de base et l'intercepteur
    // Utiliser le converter par défaut de l'API (pas besoin de le spécifier)
    _api = JellyfinOpenApi.create(
      baseUrl: Uri.parse(_currentServerUrl!),
      interceptors: [
        JellyfinInterceptor(
          accessToken: _accessToken,
          deviceId: _deviceId ?? 'jellyfish-flutter-unknown',
        ),
      ],
    );
  }

  /// Authentifie un utilisateur avec le serveur Jellyfin
  /// Retourne un tuple (User, token) en cas de succès
  Future<(app_models.User, String)> authenticate(
    String username,
    String password,
  ) async {
    if (_api == null) {
      throw Exception('Client API non initialisé. Appelez initializeClient() d\'abord.');
    }

    try {
      print('🔐 Tentative d\'authentification pour: $username');
      print('🌐 URL du serveur: $_currentServerUrl');

      final authRequest = AuthenticateUserByName(
        username: username,
        pw: password,
      );

      print('📤 Envoi de la requête d\'authentification...');
      final response = await _api!.usersAuthenticateByNamePost(body: authRequest);

      print('📥 Réponse reçue - Status: ${response.statusCode}');
      print('📥 isSuccessful: ${response.isSuccessful}');

      if (response.isSuccessful && response.body != null) {
        final result = response.body!;

        if (result.accessToken == null || result.accessToken!.isEmpty) {
          throw Exception('Token d\'accès manquant dans la réponse');
        }

        if (result.user == null) {
          throw Exception('Données utilisateur manquantes dans la réponse');
        }

        print('✅ Authentification réussie pour: ${result.user!.name}');

        // Convertir UserDto en notre modèle User
        final user = _convertUserDtoToUser(result.user!);

        // Réinitialiser le client avec le token (garder le même deviceId)
        _accessToken = result.accessToken!;
        initializeClient(_currentServerUrl!, accessToken: _accessToken, deviceId: _deviceId);

        return (user, result.accessToken!);
      } else {
        final errorMsg = 'Status ${response.statusCode}: ${response.error}';
        print('❌ Échec de l\'authentification: $errorMsg');
        throw Exception('Échec de l\'authentification: $errorMsg');
      }
    } catch (e) {
      print('❌ Erreur d\'authentification: $e');
      if (e is Exception) rethrow;
      throw Exception('Erreur lors de l\'authentification: $e');
    }
  }

  /// Convertit un UserDto de l'API en notre modèle User
  app_models.User _convertUserDtoToUser(UserDto userDto) {
    return app_models.User(
      id: userDto.id ?? '',
      name: userDto.name ?? 'Unknown',
      email: null, // Jellyfin n'expose pas l'email dans UserDto
      avatarUrl: _buildAvatarUrl(userDto),
      isAdmin: userDto.policy?.isAdministrator ?? false,
      isDisabled: userDto.policy?.isDisabled ?? false,
      lastLoginDate: userDto.lastLoginDate,
      lastActivityDate: userDto.lastActivityDate,
    );
  }

  /// Construit l'URL de l'avatar de l'utilisateur
  String? _buildAvatarUrl(UserDto userDto) {
    if (_currentServerUrl == null || userDto.id == null || userDto.primaryImageTag == null) {
      return null;
    }
    return '$_currentServerUrl/Users/${userDto.id}/Images/Primary?tag=${userDto.primaryImageTag}';
  }

  /// Récupère l'URL du serveur actuel
  String? get currentServerUrl => _currentServerUrl;

  /// Vérifie si le client est initialisé
  bool get isInitialized => _api != null;

  /// Récupère les éléments en cours de lecture (resume)
  Future<List<BaseItemDto>> getResumeItems(String userId, {int limit = 10}) async {
    if (_api == null) {
      throw Exception('Client API non initialisé');
    }

    try {
      final response = await _api!.userItemsResumeGet(
        userId: userId,
        limit: limit,
        enableUserData: true,
        enableImages: true,
        imageTypeLimit: 1,
      );

      if (response.isSuccessful && response.body != null) {
        return response.body!.items ?? [];
      }
      return [];
    } catch (e) {
      print('❌ Erreur lors de la récupération des éléments en cours: $e');
      return [];
    }
  }

  /// Récupère les prochains épisodes à regarder
  Future<List<BaseItemDto>> getNextUpEpisodes(String userId, {int limit = 10}) async {
    if (_api == null) {
      throw Exception('Client API non initialisé');
    }

    try {
      final response = await _api!.showsNextUpGet(
        userId: userId,
        limit: limit,
        enableUserData: true,
        enableImages: true,
        imageTypeLimit: 1,
      );

      if (response.isSuccessful && response.body != null) {
        return response.body!.items ?? [];
      }
      return [];
    } catch (e) {
      print('❌ Erreur lors de la récupération des prochains épisodes: $e');
      return [];
    }
  }

  /// Récupère les derniers éléments ajoutés
  Future<List<BaseItemDto>> getLatestItems(String userId, {String? parentId, int limit = 16}) async {
    if (_api == null) {
      throw Exception('Client API non initialisé');
    }

    try {
      final response = await _api!.itemsLatestGet(
        userId: userId,
        parentId: parentId,
        limit: limit,
        enableUserData: true,
        enableImages: true,
        imageTypeLimit: 1,
      );

      if (response.isSuccessful && response.body != null) {
        return response.body ?? [];
      }
      return [];
    } catch (e) {
      print('❌ Erreur lors de la récupération des derniers éléments: $e');
      return [];
    }
  }

  /// Récupère les bibliothèques/vues de l'utilisateur
  Future<List<BaseItemDto>> getUserViews(String userId) async {
    if (_api == null) {
      throw Exception('Client API non initialisé');
    }

    try {
      final response = await _api!.userViewsGet(
        userId: userId,
        includeExternalContent: false,
        includeHidden: false,
      );

      if (response.isSuccessful && response.body != null) {
        return response.body!.items ?? [];
      }
      return [];
    } catch (e) {
      print('❌ Erreur lors de la récupération des bibliothèques: $e');
      return [];
    }
  }

  /// Construit l'URL d'une image pour un item
  String? getImageUrl(String itemId, {String? tag, int? maxWidth, int? maxHeight}) {
    if (_currentServerUrl == null) return null;

    final params = <String, String>{};
    if (tag != null) params['tag'] = tag;
    if (maxWidth != null) params['maxWidth'] = maxWidth.toString();
    if (maxHeight != null) params['maxHeight'] = maxHeight.toString();

    final queryString = params.isEmpty ? '' : '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    return '$_currentServerUrl/Items/$itemId/Images/Primary$queryString';
  }

  /// Récupère l'URL d'une image backdrop
  String? getBackdropUrl(String itemId, {String? tag, int? maxWidth}) {
    if (_currentServerUrl == null) return null;

    final params = <String, String>{};
    if (tag != null) params['tag'] = tag;
    if (maxWidth != null) params['maxWidth'] = maxWidth.toString();

    final queryString = params.isEmpty ? '' : '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    return '$_currentServerUrl/Items/$itemId/Images/Backdrop$queryString';
  }

  /// Récupère l'URL d'un logo
  String? getLogoUrl(String itemId, {String? tag, int? maxWidth, int? maxHeight}) {
    if (_currentServerUrl == null) return null;

    final params = <String, String>{};
    if (tag != null) params['tag'] = tag;
    if (maxWidth != null) params['maxWidth'] = maxWidth.toString();
    if (maxHeight != null) params['maxHeight'] = maxHeight.toString();

    final queryString = params.isEmpty ? '' : '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    return '$_currentServerUrl/Items/$itemId/Images/Logo$queryString';
  }

  /// Récupère l'URL d'une image thumb
  String? getThumbUrl(String itemId, {String? tag, int? maxWidth, int? maxHeight}) {
    if (_currentServerUrl == null) return null;

    final params = <String, String>{};
    if (tag != null) params['tag'] = tag;
    if (maxWidth != null) params['maxWidth'] = maxWidth.toString();
    if (maxHeight != null) params['maxHeight'] = maxHeight.toString();

    final queryString = params.isEmpty ? '' : '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    return '$_currentServerUrl/Items/$itemId/Images/Thumb$queryString';
  }

  /// Récupère les items d'une bibliothèque avec pagination et filtres
  Future<BaseItemDtoQueryResult> getLibraryItems(
    String userId,
    String parentId, {
    int? startIndex,
    int? limit,
    List<ItemSortBy>? sortBy,
    List<SortOrder>? sortOrder,
    List<BaseItemKind>? includeItemTypes,
    bool? recursive,
    String? searchTerm,
    List<String>? genres,
    List<int>? years,
  }) async {
    if (_api == null) {
      throw Exception('Client API non initialisé');
    }

    try {
      final response = await _api!.itemsGet(
        userId: userId,
        parentId: parentId,
        startIndex: startIndex,
        limit: limit,
        sortBy: sortBy,
        sortOrder: sortOrder,
        includeItemTypes: includeItemTypes,
        recursive: recursive ?? true,
        searchTerm: searchTerm,
        genres: genres,
        years: years,
        enableUserData: true,
        enableImages: true,
        imageTypeLimit: 1,
      );

      if (response.isSuccessful && response.body != null) {
        return response.body!;
      }
      return BaseItemDtoQueryResult(items: [], totalRecordCount: 0);
    } catch (e) {
      print('❌ Erreur lors de la récupération des items de la bibliothèque: $e');
      return BaseItemDtoQueryResult(items: [], totalRecordCount: 0);
    }
  }

  /// Récupère les détails complets d'un item
  Future<BaseItemDto?> getItemDetails(String userId, String itemId) async {
    if (_api == null) {
      throw Exception('Client API non initialisé');
    }

    try {
      final response = await _api!.itemsItemIdGet(
        userId: userId,
        itemId: itemId,
      );

      if (response.isSuccessful && response.body != null) {
        return response.body!;
      }
      return null;
    } catch (e) {
      print('❌ Erreur lors de la récupération des détails de l\'item: $e');
      return null;
    }
  }

  /// Récupère les items similaires
  Future<List<BaseItemDto>> getSimilarItems(
    String userId,
    String itemId, {
    int limit = 10,
  }) async {
    if (_api == null) {
      throw Exception('Client API non initialisé');
    }

    try {
      final response = await _api!.itemsItemIdSimilarGet(
        userId: userId,
        itemId: itemId,
        limit: limit,
      );

      if (response.isSuccessful && response.body != null) {
        return response.body!.items ?? [];
      }
      return [];
    } catch (e) {
      print('❌ Erreur lors de la récupération des items similaires: $e');
      return [];
    }
  }

  /// Construit l'URL de streaming vidéo pour un item
  /// Utilise le streaming direct ou le transcodage selon les capacités
  String? getVideoStreamUrl(String itemId, {
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    int? maxStreamingBitrate,
  }) {
    if (_currentServerUrl == null || _accessToken == null) return null;

    // Construire l'URL de base pour le streaming HLS (HTTP Live Streaming)
    // C'est le format le plus compatible avec media_kit
    final params = <String, String>{
      'Static': 'true',
      'mediaSourceId': mediaSourceId ?? itemId,
      'deviceId': 'jellyfish_app',
      'api_key': _accessToken!,
    };

    if (audioStreamIndex != null) {
      params['AudioStreamIndex'] = audioStreamIndex.toString();
    }
    if (subtitleStreamIndex != null) {
      params['SubtitleStreamIndex'] = subtitleStreamIndex.toString();
    }
    if (maxStreamingBitrate != null) {
      params['MaxStreamingBitrate'] = maxStreamingBitrate.toString();
    }

    final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');

    // Utiliser l'endpoint de streaming direct
    return '$_currentServerUrl/Videos/$itemId/stream?$queryString';
  }

  /// Construit l'URL de streaming HLS master playlist pour un item
  /// Recommandé pour le streaming adaptatif
  String? getHlsStreamUrl(String itemId, {
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) {
    if (_currentServerUrl == null || _accessToken == null) return null;

    final params = <String, String>{
      'mediaSourceId': mediaSourceId ?? itemId,
      'deviceId': 'jellyfish_app',
      'api_key': _accessToken!,
      'PlaySessionId': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    if (audioStreamIndex != null) {
      params['AudioStreamIndex'] = audioStreamIndex.toString();
    }
    if (subtitleStreamIndex != null) {
      params['SubtitleStreamIndex'] = subtitleStreamIndex.toString();
    }

    final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');

    // Utiliser l'endpoint HLS master playlist
    return '$_currentServerUrl/Videos/$itemId/master.m3u8?$queryString';
  }

  /// Récupère les informations de playback pour un item
  /// Contient les MediaSources avec les pistes audio/sous-titres et leurs métadonnées
  Future<PlaybackInfoResponse?> getPlaybackInfo(String itemId, String userId) async {
    if (_api == null) {
      throw Exception('Client API non initialisé');
    }

    try {
      print('🎬 Récupération des informations de playback pour: $itemId');
      final response = await _api!.itemsItemIdPlaybackInfoGet(
        itemId: itemId,
        userId: userId,
      );

      if (response.isSuccessful && response.body != null) {
        print('✅ Informations de playback récupérées');
        final mediaSources = response.body!.mediaSources;
        if (mediaSources != null && mediaSources.isNotEmpty) {
          print('   📦 ${mediaSources.length} source(s) média trouvée(s)');
          final firstSource = mediaSources.first;
          final audioStreams = firstSource.mediaStreams?.where((s) => s.type == MediaStreamType.audio).length ?? 0;
          final subtitleStreams = firstSource.mediaStreams?.where((s) => s.type == MediaStreamType.subtitle).length ?? 0;
          print('   🎵 $audioStreams piste(s) audio');
          print('   💬 $subtitleStreams piste(s) de sous-titres');
        }
        return response.body;
      }
      print('⚠️ Aucune information de playback disponible');
      return null;
    } catch (e) {
      print('❌ Erreur lors de la récupération des informations de playback: $e');
      return null;
    }
  }

  /// Récupère le token d'accès actuel
  String? get accessToken => _accessToken;
}

