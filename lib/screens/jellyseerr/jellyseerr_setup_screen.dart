import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jellyfish/providers/jellyseerr_provider.dart';
import 'package:jellyfish/providers/auth_provider.dart';
import 'package:jellyfish/models/user.dart';

/// Écran de configuration et d'authentification Jellyseerr
class JellyseerrSetupScreen extends ConsumerStatefulWidget {
  const JellyseerrSetupScreen({super.key});

  @override
  ConsumerState<JellyseerrSetupScreen> createState() =>
      _JellyseerrSetupScreenState();
}

class _JellyseerrSetupScreenState extends ConsumerState<JellyseerrSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _serverConfigured = false;
  String? _errorMessage;

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _configureServer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(jellyseerrAuthStateProvider.notifier)
          .configureServer(_serverUrlController.text.trim());

      setState(() {
        _serverConfigured = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serveur configuré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Utiliser les credentials Jellyfin si disponibles
      final jellyfinAuthState = ref.read(authStateProvider);
      
      String username = _usernameController.text.trim();
      String password = _passwordController.text.trim();

      // Si les champs sont vides et qu'on est connecté à Jellyfin,
      // on pourrait proposer d'utiliser les mêmes credentials
      // Mais pour la sécurité, on demande toujours le mot de passe

      await ref
          .read(jellyseerrAuthStateProvider.notifier)
          .login(username, password);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connexion réussie !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final jellyfinAuthState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Jellyseerr'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo ou icône
              const Icon(
                Icons.movie_filter,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),

              // Titre
              Text(
                'Bienvenue sur Jellyseerr',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                'Jellyseerr vous permet de demander des films et séries TV. '
                'Configurez d\'abord votre serveur Jellyseerr, puis connectez-vous avec vos identifiants Jellyfin.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Configuration du serveur
              if (!_serverConfigured) ...[
                Text(
                  'Étape 1: Configuration du serveur',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _serverUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL du serveur Jellyseerr',
                    hintText: 'https://jellyseerr.example.com',
                    prefixIcon: Icon(Icons.link),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer l\'URL du serveur';
                    }
                    if (!value.startsWith('http://') &&
                        !value.startsWith('https://')) {
                      return 'L\'URL doit commencer par http:// ou https://';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _isLoading ? null : _configureServer,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Configurer le serveur'),
                ),
              ],

              // Authentification
              if (_serverConfigured) ...[
                Text(
                  'Étape 2: Connexion',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),

                // Info sur l'utilisateur Jellyfin
                if (jellyfinAuthState.status == AuthStatus.authenticated && jellyfinAuthState.user != null) ...[
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Connecté à Jellyfin en tant que ${jellyfinAuthState.user!.name}. '
                              'Utilisez les mêmes identifiants pour Jellyseerr.',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom d\'utilisateur Jellyfin',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre nom d\'utilisateur';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe Jellyfin',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre mot de passe';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Se connecter'),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    setState(() {
                      _serverConfigured = false;
                    });
                  },
                  child: const Text('Modifier l\'URL du serveur'),
                ),
              ],

              // Message d'erreur
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

