import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';

/// Écran d'accueil principal
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background1,
      appBar: AppBar(
        title: const Text('Jellyfish'),
        backgroundColor: AppColors.background2,
        foregroundColor: AppColors.text6,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Naviguer vers les paramètres
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie,
              size: 64,
              color: AppColors.jellyfinPurple,
            ),
            const SizedBox(height: 16),
            Text(
              'Bienvenue dans Jellyfish',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.text6,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre client Jellyfin moderne',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.text3,
              ),
            ),
            const SizedBox(height: 32),
            
            // Statut d'authentification
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: AppColors.background3,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.surface1,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Statut: ${_getStatusText(authState.status)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.text4,
                    ),
                  ),
                  if (authState.user != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Utilisateur: ${authState.user!.name}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.text5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (authState.error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Erreur: ${authState.error}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Boutons d'action
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Naviguer vers la connexion
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Se connecter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.jellyfinPurple,
                    foregroundColor: AppColors.text6,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Naviguer vers les paramètres
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Paramètres'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text4,
                    side: const BorderSide(color: AppColors.surface1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _getStatusText(AuthStatus status) {
    switch (status) {
      case AuthStatus.initial:
        return 'Initial';
      case AuthStatus.loading:
        return 'Chargement...';
      case AuthStatus.authenticated:
        return 'Connecté';
      case AuthStatus.unauthenticated:
        return 'Non connecté';
    }
  }
}
