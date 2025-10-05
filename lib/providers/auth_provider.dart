import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';

/// Provider pour l'état d'authentification
final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

/// Notifier pour gérer l'état d'authentification
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => AuthState.initial();

  /// Connexion utilisateur
  Future<void> login(String username, String password, String serverUrl) async {
    state = AuthState.loading();
    
    try {
      // TODO: Implémenter la logique de connexion avec l'API Jellyfin
      await Future.delayed(const Duration(seconds: 2)); // Simulation
      
      // Exemple d'utilisateur connecté
      final user = User(
        id: '1',
        name: username,
        email: '$username@example.com',
        isAdmin: false,
        lastLoginDate: DateTime.now(),
      );
      
      state = AuthState.authenticated(user, 'fake_token');
    } catch (e) {
      state = AuthState.unauthenticated(e.toString());
    }
  }

  /// Déconnexion utilisateur
  void logout() {
    state = AuthState.unauthenticated();
  }

  /// Vérification du token au démarrage
  Future<void> checkAuthStatus() async {
    state = AuthState.loading();
    
    try {
      // TODO: Vérifier le token stocké localement
      await Future.delayed(const Duration(seconds: 1)); // Simulation
      
      // Si pas de token valide
      state = AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.unauthenticated(e.toString());
    }
  }
}
