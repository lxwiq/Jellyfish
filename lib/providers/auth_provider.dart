import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/storage_service.dart';
import '../services/jellyfin_service.dart';
import 'services_provider.dart';

/// Provider pour l'état d'authentification
final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

/// Notifier pour gérer l'état d'authentification
class AuthNotifier extends Notifier<AuthState> {
  late final StorageService _storageService;
  late final JellyfinService _jellyfinService;

  @override
  AuthState build() {
    _storageService = ref.read(storageServiceProvider);
    _jellyfinService = ref.read(jellyfinServiceProvider);
    return AuthState.initial();
  }

  /// Connexion utilisateur avec l'API Jellyfin
  Future<void> login(String username, String password, String serverUrl) async {
    debugPrint('\n🚀 ========== DÉBUT LOGIN ==========');
    debugPrint('👤 Username: $username');
    debugPrint('🔒 Password: ${password.replaceAll(RegExp(r'.'), '*')} (${password.length} caractères)');
    debugPrint('🌐 Server URL: $serverUrl');

    state = AuthState.loading();

    try {
      // Récupérer ou créer le DeviceId unique
      final deviceId = _storageService.getOrCreateDeviceId();

      debugPrint('\n📡 Initialisation du client API...');
      // Initialiser le client API avec l'URL du serveur et le deviceId
      _jellyfinService.initializeClient(serverUrl, deviceId: deviceId);
      debugPrint('✅ Client API initialisé');

      debugPrint('\n🔐 Tentative d\'authentification...');
      // Authentification avec l'API Jellyfin
      final (user, token) = await _jellyfinService.authenticate(username, password);
      debugPrint('✅ Authentification réussie !');
      debugPrint('   User ID: ${user.id}');
      debugPrint('   User Name: ${user.name}');
      debugPrint('   Token: ${token.substring(0, 10)}...');

      debugPrint('\n💾 Sauvegarde des données...');
      // Sauvegarder les données
      await _storageService.saveServerUrl(serverUrl);
      debugPrint('   ✓ Server URL sauvegardé');
      await _storageService.saveUser(user);
      debugPrint('   ✓ User sauvegardé');
      await _storageService.saveToken(token);
      debugPrint('   ✓ Token sauvegardé');

      // Mettre à jour l'état
      state = AuthState.authenticated(user, token);
      debugPrint('\n✅ ========== LOGIN RÉUSSI ==========\n');
    } catch (e, stackTrace) {
      debugPrint('\n❌ ========== ERREUR LOGIN ==========');
      debugPrint('❌ Erreur: $e');
      debugPrint('📚 Stack trace:');
      debugPrint(stackTrace.toString());
      debugPrint('❌ ====================================\n');

      state = AuthState.unauthenticated('Erreur de connexion: ${e.toString()}');
      rethrow;
    }
  }

  /// Déconnexion utilisateur
  Future<void> logout() async {
    try {
      await _storageService.clearAll();
      state = AuthState.unauthenticated();
    } catch (e) {
      // En cas d'erreur, on déconnecte quand même l'utilisateur
      state = AuthState.unauthenticated();
    }
  }

  /// Vérification du token au démarrage
  Future<void> checkAuthStatus() async {
    state = AuthState.loading();

    try {
      // Vérifier si une session valide existe
      final hasSession = await _storageService.hasValidSession();

      if (!hasSession) {
        state = AuthState.unauthenticated();
        return;
      }

      // Récupérer les données stockées
      final serverUrl = _storageService.getServerUrl();
      final user = _storageService.getUser();
      final token = await _storageService.getToken();
      final deviceId = _storageService.getOrCreateDeviceId();

      if (serverUrl == null || user == null || token == null) {
        state = AuthState.unauthenticated();
        return;
      }

      // Réinitialiser le client API avec l'URL du serveur, le token et le deviceId
      _jellyfinService.initializeClient(
        serverUrl,
        accessToken: token,
        deviceId: deviceId,
      );

      // TODO: Optionnel - Vérifier que le token est toujours valide avec l'API
      // Pour l'instant, on fait confiance au token stocké

      state = AuthState.authenticated(user, token);
    } catch (e) {
      state = AuthState.unauthenticated('Erreur lors de la vérification: ${e.toString()}');
    }
  }
}
