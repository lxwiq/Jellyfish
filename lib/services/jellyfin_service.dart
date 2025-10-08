import 'package:jellyfish/jellyfin/jellyfin_open_api.swagger.dart';
import 'package:jellyfish/services/jellyfin_interceptor.dart';
import 'package:jellyfish/services/custom_http_client.dart';
import '../models/user.dart' as app_models;
import 'package:jellyfish/services/logger_service.dart';



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

    LoggerService.instance.info('Initialisation du client Jellyfin');
    LoggerService.instance.debug('Server URL: $_currentServerUrl');
    LoggerService.instance.debug('Device ID: $_deviceId');
    LoggerService.instance.debug('Has Token: ${_accessToken != null}');

    // Créer l'API avec l'URL de base et l'intercepteur
    // Utiliser le converter par défaut de l'API (pas besoin de le spécifier)
    // Utiliser un client HTTP personnalisé pour gérer les certificats SSL sur Windows
    _api = JellyfinOpenApi.create(
      baseUrl: Uri.parse(_currentServerUrl!),
      httpClient: CustomHttpClient(),
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
      await LoggerService.instance.info('Tentative d\'authentification pour: $username');
      await LoggerService.instance.debug('URL du serveur: $_currentServerUrl');

      final authRequest = AuthenticateUserByName(
        username: username,
        pw: password,
      );

      await LoggerService.instance.info('Envoi de la requete d\'authentification...');
      final response = await _api!.usersAuthenticateByNamePost(body: authRequest);

      await LoggerService.instance.info('Reponse recue - Status: ${response.statusCode}');
      await LoggerService.instance.debug('isSuccessful: ${response.isSuccessful}');

      if (response.isSuccessful && response.body != null) {
        final result = response.body!;

        if (result.accessToken == null || result.accessToken!.isEmpty) {
          throw Exception('Token d\'accès manquant dans la réponse du serveur');
        }

        if (result.user == null) {
          throw Exception('Données utilisateur manquantes dans la réponse du serveur');
        }

        await LoggerService.instance.info('Authentification reussie pour: ${result.user!.name}');

        // Convertir UserDto en notre modèle User
        final user = _convertUserDtoToUser(result.user!);

        // Réinitialiser le client avec le token (garder le même deviceId)
        _accessToken = result.accessToken!;
        initializeClient(_currentServerUrl!, accessToken: _accessToken, deviceId: _deviceId);

        return (user, result.accessToken!);
      } else {
        // Gérer les différents codes d'erreur HTTP
        await LoggerService.instance.warning('Echec de l\'authentification - Status: ${response.statusCode}');

        if (response.statusCode == 401) {
          throw Exception('Nom d\'utilisateur ou mot de passe incorrect');
        } else if (response.statusCode == 403) {
          throw Exception('Accès refusé. Votre compte est peut-être désactivé');
        } else if (response.statusCode == 404) {
          throw Exception('Serveur Jellyfin introuvable. Vérifiez l\'URL');
        } else if (response.statusCode == 500) {
          throw Exception('Erreur interne du serveur Jellyfin');
        } else if (response.statusCode == 503) {
          throw Exception('Le serveur Jellyfin est temporairement indisponible');
        } else {
          throw Exception('Erreur de connexion (code ${response.statusCode})');
        }
      }
    } catch (e) {
      await LoggerService.instance.error('Erreur d\'authentification', error: e);

      // Fournir des messages d'erreur clairs
      if (e.toString().contains('timeout')) {
        throw Exception('Le serveur ne répond pas. Vérifiez votre connexion internet.');
      } else if (e.toString().contains('SocketException') ||
                 e.toString().contains('Failed host lookup')) {
        throw Exception('Impossible de joindre le serveur. Vérifiez l\'URL et votre connexion internet.');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Erreur lors de l\'authentification: $e');
      }
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

  /// Vérifie si le serveur est accessible et fonctionnel
  /// Retourne true si le serveur répond correctement
  /// Lance une exception avec un message clair en cas d'erreur
  Future<bool> checkServerHealth(String serverUrl) async {
    try {
      await LoggerService.instance.info('Verification de la sante du serveur: $serverUrl');

      // Nettoyer l'URL (enlever le trailing slash si présent)
      final cleanUrl = serverUrl.endsWith('/')
          ? serverUrl.substring(0, serverUrl.length - 1)
          : serverUrl;

      // Créer un client temporaire pour le ping
      // Utiliser un client HTTP personnalisé pour gérer les certificats SSL
      final tempApi = JellyfinOpenApi.create(
        baseUrl: Uri.parse(cleanUrl),
        httpClient: CustomHttpClient(),
      );

      // Appeler l'endpoint de ping avec un timeout
      final response = await tempApi.systemPingGet().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Le serveur ne répond pas (timeout après 10 secondes)');
        },
      );

      if (response.isSuccessful) {
        await LoggerService.instance.info('Serveur accessible et fonctionnel');
        return true;
      } else {
        await LoggerService.instance.warning('Le serveur a repondu avec une erreur: ${response.statusCode}');
        throw Exception('Le serveur a répondu avec une erreur (code ${response.statusCode})');
      }
    } catch (e) {
      await LoggerService.instance.error('Erreur lors de la verification du serveur', error: e);

      // Fournir des messages d'erreur clairs selon le type d'erreur
      if (e.toString().contains('timeout')) {
        throw Exception('Le serveur ne répond pas. Vérifiez l\'URL et votre connexion internet.');
      } else if (e.toString().contains('SocketException') ||
                 e.toString().contains('Failed host lookup')) {
        throw Exception('Impossible de joindre le serveur. Vérifiez l\'URL et votre connexion internet.');
      } else if (e.toString().contains('HandshakeException') ||
                 e.toString().contains('CERTIFICATE_VERIFY_FAILED')) {
        throw Exception('Erreur de certificat SSL. Le serveur utilise peut-être un certificat auto-signé.');
      } else if (e.toString().contains('FormatException')) {
        throw Exception('L\'URL du serveur n\'est pas valide.');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Erreur de connexion au serveur: ${e.toString()}');
      }
    }
  }

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
        imageTypeLimit: 3, // Augmenter pour avoir plus d'options d'images
        fields: [
          ItemFields.primaryimageaspectratio,
          ItemFields.overview,
        ],
      );

      if (response.isSuccessful && response.body != null) {
        return response.body!.items ?? [];
      }
      return [];
    } catch (e) {
      await LoggerService.instance.error('Erreur lors de la recuperation des elements en cours', error: e);
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
        imageTypeLimit: 3, // Augmenter pour avoir plus d'options d'images
        fields: [
          ItemFields.primaryimageaspectratio,
          ItemFields.overview,
        ],
      );

      if (response.isSuccessful && response.body != null) {
        return response.body!.items ?? [];
      }
      return [];
    } catch (e) {
      await LoggerService.instance.error('Erreur lors de la recuperation des prochains episodes', error: e);
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
      await LoggerService.instance.error('Erreur lors de la recuperation des derniers elements', error: e);
      return [];
    }
  }

  /// Récupère des items pour le hero carousel avec des critères optimisés
  /// Retourne des films et séries avec de bonnes notes, des backdrops et des descriptions
  Future<List<BaseItemDto>> getHeroItems(String userId, {int limit = 20}) async {
    if (_api == null) {
      throw Exception('Client API non initialisé');
    }

    try {
      final response = await _api!.itemsGet(
        userId: userId,
        limit: limit,
        recursive: true,
        sortBy: [ItemSortBy.datecreated, ItemSortBy.communityrating],
        sortOrder: [SortOrder.descending],
        includeItemTypes: [BaseItemKind.movie, BaseItemKind.series],
        minCommunityRating: 6.0, // Minimum 6/10
        hasOverview: true, // Doit avoir une description
        enableUserData: true,
        enableImages: true,
        imageTypeLimit: 1,
        fields: [
          ItemFields.overview,
          ItemFields.genres,
        ],
      );

      if (response.isSuccessful && response.body != null) {
        return response.body!.items ?? [];
      }
      return [];
    } catch (e) {
      await LoggerService.instance.error('Erreur lors de la recuperation des items hero', error: e);
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
      await LoggerService.instance.error('Erreur lors de la recuperation des bibliotheques', error: e);
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

  /// Récupère l'URL d'une image trickplay (capture d'écran de la vidéo)
  /// Utilisé comme fallback quand pas de backdrop disponible
  String? getTrickplayUrl(String itemId, {int? width, int index = 0, String? mediaSourceId}) {
    if (_currentServerUrl == null) return null;

    final effectiveWidth = width ?? 320;
    final params = <String, String>{};
    if (mediaSourceId != null) params['mediaSourceId'] = mediaSourceId;

    final queryString = params.isEmpty ? '' : '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    return '$_currentServerUrl/Videos/$itemId/Trickplay/$effectiveWidth/$index.jpg$queryString';
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
      await LoggerService.instance.error('Erreur lors de la recuperation des items de la bibliotheque', error: e);
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
      await LoggerService.instance.error('Erreur lors de la recuperation des details de l\'item', error: e);
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
      await LoggerService.instance.error('Erreur lors de la recuperation des items similaires', error: e);
      return [];
    }
  }

  /// Récupère les détails d'une personne (acteur, réalisateur, etc.)
  Future<BaseItemDto?> getPersonDetails(String personId, String userId) async {
    if (_api == null) {
      throw Exception('Client API non initialisé');
    }

    try {
      final response = await _api!.itemsItemIdGet(
        userId: userId,
        itemId: personId,
      );

      if (response.isSuccessful && response.body != null) {
        return response.body!;
      }
      return null;
    } catch (e) {
      await LoggerService.instance.error('Erreur lors de la recuperation des details de la personne', error: e);
      return null;
    }
  }

  /// Récupère les items dans lesquels une personne apparaît
  Future<List<BaseItemDto>> getItemsByPerson(
    String userId,
    String personId, {
    int limit = 50,
  }) async {
    if (_api == null) {
      throw Exception('Client API non initialisé');
    }

    try {
      final response = await _api!.itemsGet(
        userId: userId,
        personIds: [personId],
        recursive: true,
        includeItemTypes: [BaseItemKind.movie, BaseItemKind.series, BaseItemKind.episode],
        sortBy: [ItemSortBy.premieredate, ItemSortBy.productionyear],
        sortOrder: [SortOrder.descending],
        limit: limit,
        enableUserData: true,
        enableImages: true,
        imageTypeLimit: 1,
        fields: [
          ItemFields.overview,
          ItemFields.genres,
          ItemFields.primaryimageaspectratio,
        ],
      );

      if (response.isSuccessful && response.body != null) {
        return response.body!.items ?? [];
      }
      return [];
    } catch (e) {
      await LoggerService.instance.error('Erreur lors de la recuperation des items de la personne', error: e);
      return [];
    }
  }

  /// Récupère les saisons d'une série
  Future<List<BaseItemDto>> getSeasons(String seriesId, String userId) async {
    if (_api == null) {
      throw Exception('Client API non initialisé');
    }

    try {
      final response = await _api!.showsSeriesIdSeasonsGet(
        seriesId: seriesId,
        userId: userId,
        enableUserData: true,
        enableImages: true,
        imageTypeLimit: 1,
        fields: [ItemFields.overview],
      );

      if (response.isSuccessful && response.body != null) {
        return response.body!.items ?? [];
      }
      return [];
    } catch (e) {
      await LoggerService.instance.error('Erreur lors de la recuperation des saisons', error: e);
      return [];
    }
  }

  /// Récupère les épisodes d'une saison
  Future<List<BaseItemDto>> getEpisodes(
    String seriesId,
    String userId, {
    String? seasonId,
    int? seasonNumber,
  }) async {
    if (_api == null) {
      throw Exception('Client API non initialisé');
    }

    try {
      final response = await _api!.showsSeriesIdEpisodesGet(
        seriesId: seriesId,
        userId: userId,
        seasonId: seasonId,
        season: seasonNumber,
        enableUserData: true,
        enableImages: true,
        imageTypeLimit: 3,
        fields: [
          ItemFields.overview,
          ItemFields.primaryimageaspectratio,
        ],
      );

      if (response.isSuccessful && response.body != null) {
        return response.body!.items ?? [];
      }
      return [];
    } catch (e) {
      await LoggerService.instance.error('Erreur lors de la recuperation des episodes', error: e);
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
      await LoggerService.instance.info('Recuperation des informations de playback pour: $itemId');
      final response = await _api!.itemsItemIdPlaybackInfoGet(
        itemId: itemId,
        userId: userId,
      );

      if (response.isSuccessful && response.body != null) {
        await LoggerService.instance.info('Informations de playback recuperees');
        final mediaSources = response.body!.mediaSources;
        if (mediaSources != null && mediaSources.isNotEmpty) {
          await LoggerService.instance.debug('${mediaSources.length} source(s) media trouvee(s)');
          final firstSource = mediaSources.first;
          final audioStreams = firstSource.mediaStreams?.where((s) => s.type == MediaStreamType.audio).length ?? 0;
          final subtitleStreams = firstSource.mediaStreams?.where((s) => s.type == MediaStreamType.subtitle).length ?? 0;
          await LoggerService.instance.debug('$audioStreams piste(s) audio');
          await LoggerService.instance.debug('$subtitleStreams piste(s) de sous-titres');
        }
        return response.body;
      }
      await LoggerService.instance.warning('Aucune information de playback disponible');
      return null;
    } catch (e) {
      await LoggerService.instance.error('Erreur lors de la recuperation des informations de playback', error: e);
      return null;
    }
  }

  /// Récupère le token d'accès actuel
  String? get accessToken => _accessToken;

  /// Signale le début de lecture d'un item
  Future<bool> reportPlaybackStart({
    required String itemId,
    required String userId,
    int? positionTicks,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    String? mediaSourceId,
  }) async {
    if (_api == null) {
      await LoggerService.instance.error('Client API non initialisé');
      return false;
    }

    try {
      await LoggerService.instance.info('Signalement du debut de lecture: $itemId');
      final playbackStartInfo = PlaybackStartInfo(
        itemId: itemId,
        positionTicks: positionTicks ?? 0,
        audioStreamIndex: audioStreamIndex,
        subtitleStreamIndex: subtitleStreamIndex,
        mediaSourceId: mediaSourceId ?? itemId,
        canSeek: true,
        isPaused: false,
        playMethod: PlayMethod.directplay,
      );

      final response = await _api!.sessionsPlayingPost(
        body: playbackStartInfo,
      );

      if (response.isSuccessful) {
        await LoggerService.instance.info('Debut de lecture signale');
        return true;
      } else {
        await LoggerService.instance.warning('Echec du signalement de debut de lecture: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      await LoggerService.instance.error('Erreur lors du signalement de debut de lecture', error: e);
      return false;
    }
  }

  /// Signale la progression de lecture d'un item
  Future<bool> reportPlaybackProgress({
    required String itemId,
    required String userId,
    required int positionTicks,
    bool isPaused = false,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    String? mediaSourceId,
  }) async {
    if (_api == null) {
      await LoggerService.instance.error('Client API non initialisé');
      return false;
    }

    try {
      final playbackProgressInfo = PlaybackProgressInfo(
        itemId: itemId,
        positionTicks: positionTicks,
        audioStreamIndex: audioStreamIndex,
        subtitleStreamIndex: subtitleStreamIndex,
        mediaSourceId: mediaSourceId ?? itemId,
        canSeek: true,
        isPaused: isPaused,
        playMethod: PlayMethod.directplay,
      );

      final response = await _api!.sessionsPlayingProgressPost(
        body: playbackProgressInfo,
      );

      if (response.isSuccessful) {
        // Ne pas logger à chaque fois pour éviter le spam
        return true;
      } else {
        await LoggerService.instance.warning('Echec du signalement de progression: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      await LoggerService.instance.error('Erreur lors du signalement de progression', error: e);
      return false;
    }
  }

  /// Signale l'arrêt de lecture d'un item
  Future<bool> reportPlaybackStopped({
    required String itemId,
    required String userId,
    required int positionTicks,
    String? mediaSourceId,
  }) async {
    if (_api == null) {
      await LoggerService.instance.error('Client API non initialisé');
      return false;
    }

    try {
      await LoggerService.instance.info('Signalement de l\'arret de lecture: $itemId a ${positionTicks ~/ 10000000}s');
      final playbackStopInfo = PlaybackStopInfo(
        itemId: itemId,
        positionTicks: positionTicks,
        mediaSourceId: mediaSourceId ?? itemId,
      );

      final response = await _api!.sessionsPlayingStoppedPost(
        body: playbackStopInfo,
      );

      if (response.isSuccessful) {
        await LoggerService.instance.info('Arret de lecture signale');
        return true;
      } else {
        await LoggerService.instance.warning('Echec du signalement d\'arret de lecture: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      await LoggerService.instance.error('Erreur lors du signalement d\'arret de lecture', error: e);
      return false;
    }
  }

  // ============================================================================
  // Méthodes pour les téléchargements hors ligne
  // ============================================================================

  /// Obtient l'URL de téléchargement direct pour un item
  String getDirectDownloadUrl(
    String itemId, {
    String quality = 'high',
  }) {
    if (_currentServerUrl == null) {
      throw Exception('Server URL not initialized');
    }

    // Construire l'URL de téléchargement direct
    // Format: /Items/{itemId}/Download
    return '$_currentServerUrl/Items/$itemId/Download';
  }

  /// Obtient le token d'accès actuel
  Future<String?> getAccessToken() async {
    return _accessToken;
  }

  /// Vérifie si un item est téléchargeable
  bool isDownloadable(BaseItemDto item) {
    // Vérifier si l'item est un média vidéo
    final type = item.type?.value;
    return type == 'Movie' || type == 'Episode';
  }

  /// Obtient la taille estimée du téléchargement (en bytes)
  Future<int> getEstimatedDownloadSize(
    String itemId,
    String quality,
  ) async {
    // Pour l'instant, retourner une estimation basée sur la qualité
    // TODO: Implémenter une vraie estimation basée sur les métadonnées
    switch (quality) {
      case 'original':
        return 5 * 1024 * 1024 * 1024; // 5 GB
      case 'high':
        return 3 * 1024 * 1024 * 1024; // 3 GB
      case 'medium':
        return 1 * 1024 * 1024 * 1024; // 1 GB
      case 'low':
        return 500 * 1024 * 1024; // 500 MB
      default:
        return 2 * 1024 * 1024 * 1024; // 2 GB
    }
  }
}

