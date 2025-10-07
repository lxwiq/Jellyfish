import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jellyfish/models/jellyseerr_models.dart';
import 'package:jellyfish/services/jellyseerr_service.dart';
import 'package:jellyfish/services/storage_service.dart';
import 'package:flutter/foundation.dart';

import 'services_provider.dart';

/// Provider pour l'état d'authentification Jellyseerr
final jellyseerrAuthStateProvider =
    NotifierProvider<JellyseerrAuthNotifier, JellyseerrAuthState>(() {
  return JellyseerrAuthNotifier();
});

/// Provider pour la liste des requêtes
final jellyseerrRequestsProvider = FutureProvider.autoDispose
    .family<JellyseerrRequestsResponse, RequestsFilter>((ref, filter) async {
  final authState = ref.watch(jellyseerrAuthStateProvider);

  if (!authState.isAuthenticated) {
    throw Exception('Non authentifié');
  }

  final service = ref.read(jellyseerrServiceProvider);
  return await service.getRequests(
    take: filter.take,
    skip: filter.skip,
    filter: filter.filter,
    sort: filter.sort,
  );
});

/// Provider pour la recherche de médias
final jellyseerrSearchProvider = FutureProvider.autoDispose
    .family<SearchResponse, String>((ref, query) async {
  final authState = ref.watch(jellyseerrAuthStateProvider);

  if (!authState.isAuthenticated) {
    throw Exception('Non authentifié');
  }

  final service = ref.read(jellyseerrServiceProvider);
  return await service.searchMedia(query);
});

/// Provider pour les médias trending
final jellyseerrTrendingProvider = FutureProvider.autoDispose
    .family<SearchResponse, int>((ref, page) async {
  final authState = ref.watch(jellyseerrAuthStateProvider);

  if (!authState.isAuthenticated) {
    throw Exception('Non authentifié');
  }

  final service = ref.read(jellyseerrServiceProvider);
  return await service.getTrending(page: page);
});

/// Provider pour les films populaires
final jellyseerrPopularMoviesProvider = FutureProvider.autoDispose
    .family<SearchResponse, int>((ref, page) async {
  final authState = ref.watch(jellyseerrAuthStateProvider);

  if (!authState.isAuthenticated) {
    throw Exception('Non authentifié');
  }

  final service = ref.read(jellyseerrServiceProvider);
  return await service.getPopularMovies(page: page);
});

/// Provider pour les séries TV populaires
final jellyseerrPopularTvProvider = FutureProvider.autoDispose
    .family<SearchResponse, int>((ref, page) async {
  final authState = ref.watch(jellyseerrAuthStateProvider);

  if (!authState.isAuthenticated) {
    throw Exception('Non authentifié');
  }

  final service = ref.read(jellyseerrServiceProvider);
  return await service.getPopularTv(page: page);
});

/// Provider pour les détails d'un film
final jellyseerrMovieDetailsProvider = FutureProvider.autoDispose
    .family<MovieDetails, int>((ref, movieId) async {
  final authState = ref.watch(jellyseerrAuthStateProvider);

  if (!authState.isAuthenticated) {
    throw Exception('Non authentifié');
  }

  final service = ref.read(jellyseerrServiceProvider);
  return await service.getMovieDetails(movieId);
});

/// Provider pour les détails d'une série TV
final jellyseerrTvDetailsProvider = FutureProvider.autoDispose
    .family<TvDetails, int>((ref, tvId) async {
  final authState = ref.watch(jellyseerrAuthStateProvider);

  if (!authState.isAuthenticated) {
    throw Exception('Non authentifié');
  }

  final service = ref.read(jellyseerrServiceProvider);
  return await service.getTvDetails(tvId);
});

/// Provider pour les recommandations d'un film
final jellyseerrMovieRecommendationsProvider = FutureProvider.autoDispose
    .family<SearchResponse, ({int id, int page})>((ref, params) async {
  final authState = ref.watch(jellyseerrAuthStateProvider);

  if (!authState.isAuthenticated) {
    throw Exception('Non authentifié');
  }

  final service = ref.read(jellyseerrServiceProvider);
  return await service.getMovieRecommendations(params.id, page: params.page);
});

/// Provider pour les recommandations d'une série TV
final jellyseerrTvRecommendationsProvider = FutureProvider.autoDispose
    .family<SearchResponse, ({int id, int page})>((ref, params) async {
  final authState = ref.watch(jellyseerrAuthStateProvider);

  if (!authState.isAuthenticated) {
    throw Exception('Non authentifié');
  }

  final service = ref.read(jellyseerrServiceProvider);
  return await service.getTvRecommendations(params.id, page: params.page);
});

/// Filtre pour les requêtes
class RequestsFilter {
  final int take;
  final int skip;
  final String? filter;
  final String? sort;

  const RequestsFilter({
    this.take = 20,
    this.skip = 0,
    this.filter,
    this.sort,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RequestsFilter &&
          runtimeType == other.runtimeType &&
          take == other.take &&
          skip == other.skip &&
          filter == other.filter &&
          sort == other.sort;

  @override
  int get hashCode =>
      take.hashCode ^ skip.hashCode ^ filter.hashCode ^ sort.hashCode;
}

/// État d'authentification Jellyseerr
class JellyseerrAuthState {
  final bool isAuthenticated;
  final JellyseerrAuthResponse? user;
  final String? errorMessage;
  final bool isLoading;

  const JellyseerrAuthState({
    required this.isAuthenticated,
    this.user,
    this.errorMessage,
    this.isLoading = false,
  });

  factory JellyseerrAuthState.initial() {
    return const JellyseerrAuthState(
      isAuthenticated: false,
      isLoading: false,
    );
  }

  factory JellyseerrAuthState.loading() {
    return const JellyseerrAuthState(
      isAuthenticated: false,
      isLoading: true,
    );
  }

  factory JellyseerrAuthState.authenticated(JellyseerrAuthResponse user) {
    return JellyseerrAuthState(
      isAuthenticated: true,
      user: user,
      isLoading: false,
    );
  }

  factory JellyseerrAuthState.unauthenticated([String? errorMessage]) {
    return JellyseerrAuthState(
      isAuthenticated: false,
      errorMessage: errorMessage,
      isLoading: false,
    );
  }
}

/// Notifier pour gérer l'état d'authentification Jellyseerr
class JellyseerrAuthNotifier extends Notifier<JellyseerrAuthState> {
  late final StorageService _storageService;
  late final JellyseerrService _jellyseerrService;

  @override
  JellyseerrAuthState build() {
    _storageService = ref.read(storageServiceProvider);
    _jellyseerrService = ref.read(jellyseerrServiceProvider);
    return JellyseerrAuthState.initial();
  }

  /// Configure le serveur Jellyseerr
  Future<void> configureServer(String serverUrl) async {
    try {
      debugPrint('🔧 Configuration du serveur Jellyseerr: $serverUrl');

      // Sauvegarder l'URL du serveur
      await _storageService.saveJellyseerrServerUrl(serverUrl);

      // Initialiser le client
      _jellyseerrService.initializeClient(serverUrl);

      debugPrint('✅ Serveur Jellyseerr configuré');
    } catch (e) {
      debugPrint('❌ Erreur lors de la configuration du serveur: $e');
      rethrow;
    }
  }

  /// Connexion avec les credentials Jellyfin
  Future<void> login(String username, String password) async {
    debugPrint('\n🚀 ========== DÉBUT LOGIN JELLYSEERR ==========');
    debugPrint('👤 Username: $username');
    debugPrint('🔒 Password: ${password.replaceAll(RegExp(r'.'), '*')} (${password.length} caractères)');

    state = JellyseerrAuthState.loading();

    try {
      // Vérifier que le serveur est configuré
      final serverUrl = _storageService.getJellyseerrServerUrl();
      if (serverUrl == null) {
        throw Exception('Serveur Jellyseerr non configuré');
      }

      debugPrint('\n🔐 Tentative d\'authentification...');
      // Authentification avec l'API Jellyseerr
      final (authResponse, cookie) =
          await _jellyseerrService.authenticate(username, password);
      debugPrint('✅ Authentification réussie !');
      debugPrint('   User ID: ${authResponse.id}');
      debugPrint('   Display Name: ${authResponse.displayName}');

      debugPrint('\n💾 Sauvegarde du cookie...');
      // Sauvegarder le cookie
      await _storageService.saveJellyseerrCookie(cookie);
      debugPrint('   ✓ Cookie sauvegardé');

      // Mettre à jour l'état
      state = JellyseerrAuthState.authenticated(authResponse);
      debugPrint('\n✅ ========== LOGIN JELLYSEERR RÉUSSI ==========\n');
    } catch (e, stackTrace) {
      debugPrint('\n❌ ========== ERREUR LOGIN JELLYSEERR ==========');
      debugPrint('❌ Erreur: $e');
      debugPrint('📚 Stack trace:');
      debugPrint(stackTrace.toString());
      debugPrint('❌ ====================================\n');

      state = JellyseerrAuthState.unauthenticated(
          'Erreur de connexion: ${e.toString()}');
      rethrow;
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    try {
      debugPrint('👋 Déconnexion de Jellyseerr');
      await _storageService.clearJellyseerr();
      state = JellyseerrAuthState.unauthenticated();
      debugPrint('✅ Déconnexion réussie');
    } catch (e) {
      debugPrint('❌ Erreur lors de la déconnexion: $e');
      rethrow;
    }
  }

  /// Vérifie et restaure la session si elle existe
  Future<void> checkSession() async {
    debugPrint('🔍 Vérification de la session Jellyseerr...');

    state = JellyseerrAuthState.loading();

    try {
      // Vérifier si une session valide existe
      final hasSession = await _storageService.hasValidJellyseerrSession();

      if (!hasSession) {
        debugPrint('❌ Aucune session valide trouvée');
        state = JellyseerrAuthState.unauthenticated();
        return;
      }

      // Récupérer les données stockées
      final serverUrl = _storageService.getJellyseerrServerUrl();
      final cookie = await _storageService.getJellyseerrCookie();

      if (serverUrl == null || cookie == null) {
        debugPrint('❌ Données de session incomplètes');
        state = JellyseerrAuthState.unauthenticated();
        return;
      }

      // Réinitialiser le client avec le cookie
      _jellyseerrService.initializeClient(serverUrl, cookie: cookie);

      // Pour l'instant, on considère que la session est valide
      // Dans une version future, on pourrait faire un appel API pour vérifier
      debugPrint('✅ Session Jellyseerr restaurée');
      state = JellyseerrAuthState.authenticated(
        JellyseerrAuthResponse(
          displayName: 'User', // Placeholder
        ),
      );
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification de la session: $e');
      state = JellyseerrAuthState.unauthenticated();
    }
  }

  /// Crée une nouvelle requête
  Future<JellyseerrRequest> createRequest(CreateRequestBody request) async {
    if (!state.isAuthenticated) {
      throw Exception('Non authentifié');
    }

    try {
      return await _jellyseerrService.createRequest(request);
    } catch (e) {
      debugPrint('❌ Erreur lors de la création de la requête: $e');
      rethrow;
    }
  }

  /// Supprime une requête
  Future<void> deleteRequest(int requestId) async {
    if (!state.isAuthenticated) {
      throw Exception('Non authentifié');
    }

    try {
      await _jellyseerrService.deleteRequest(requestId);
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression de la requête: $e');
      rethrow;
    }
  }
}

