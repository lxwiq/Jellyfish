import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:jellyfish/theme/app_colors.dart';
import 'package:jellyfish/providers/jellyseerr_provider.dart';
import 'package:jellyfish/providers/auth_provider.dart';

/// Écran de configuration et d'authentification Jellyseerr redesigné
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
  bool _obscurePassword = true;

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final maxWidth = isDesktop ? 500.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.background1,
      appBar: AppBar(
        backgroundColor: AppColors.background2,
        foregroundColor: AppColors.text6,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/jellyseerr.png',
              width: 28,
              height: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Configuration Jellyseerr',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.text6,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 32 : 16),
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Image.asset(
                    'assets/icons/jellyseerr.png',
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(height: 32),

                  // Titre
                  Text(
                    'Bienvenue sur Jellyseerr',
                    style: TextStyle(
                      fontSize: isDesktop ? 28 : 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    'Jellyseerr vous permet de demander des films et séries TV. '
                    'Configurez d\'abord votre serveur Jellyseerr, puis connectez-vous avec vos identifiants Jellyfin.',
                    style: TextStyle(
                      fontSize: isDesktop ? 15 : 14,
                      color: AppColors.text4,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Configuration du serveur
                  if (!_serverConfigured) ...[
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.jellyfinPurple,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              '1',
                              style: TextStyle(
                                color: AppColors.text6,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Configuration du serveur',
                          style: TextStyle(
                            fontSize: isDesktop ? 20 : 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _serverUrlController,
                      style: const TextStyle(color: AppColors.text6),
                      decoration: InputDecoration(
                        labelText: 'URL du serveur Jellyseerr',
                        labelStyle: const TextStyle(color: AppColors.text4),
                        hintText: 'https://jellyseerr.example.com',
                        hintStyle: const TextStyle(color: AppColors.text3),
                        prefixIcon: const Icon(
                          IconsaxPlusLinear.link,
                          color: AppColors.jellyfinPurple,
                        ),
                        filled: true,
                        fillColor: AppColors.surface1,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.jellyfinPurple,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.error,
                            width: 2,
                          ),
                        ),
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
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _configureServer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.jellyfinPurple,
                          foregroundColor: AppColors.text6,
                          disabledBackgroundColor: AppColors.surface1,
                          disabledForegroundColor: AppColors.text3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.text6,
                                ),
                              )
                            : const Text(
                                'Configurer le serveur',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],

                  // Authentification
                  if (_serverConfigured) ...[
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.jellyfinPurple,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              '2',
                              style: TextStyle(
                                color: AppColors.text6,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Connexion',
                          style: TextStyle(
                            fontSize: isDesktop ? 20 : 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Info sur l'utilisateur Jellyfin
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.jellyfinPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.jellyfinPurple.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            IconsaxPlusBold.info_circle,
                            color: AppColors.jellyfinPurple,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Utilisez vos identifiants Jellyfin pour vous connecter à Jellyseerr.',
                              style: TextStyle(
                                fontSize: isDesktop ? 14 : 13,
                                color: AppColors.text5,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _usernameController,
                      style: const TextStyle(color: AppColors.text6),
                      decoration: InputDecoration(
                        labelText: 'Nom d\'utilisateur Jellyfin',
                        labelStyle: const TextStyle(color: AppColors.text4),
                        prefixIcon: const Icon(
                          IconsaxPlusLinear.user,
                          color: AppColors.jellyfinPurple,
                        ),
                        filled: true,
                        fillColor: AppColors.surface1,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.jellyfinPurple,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.error,
                            width: 2,
                          ),
                        ),
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
                      style: const TextStyle(color: AppColors.text6),
                      decoration: InputDecoration(
                        labelText: 'Mot de passe Jellyfin',
                        labelStyle: const TextStyle(color: AppColors.text4),
                        prefixIcon: const Icon(
                          IconsaxPlusLinear.lock,
                          color: AppColors.jellyfinPurple,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? IconsaxPlusLinear.eye_slash
                                : IconsaxPlusLinear.eye,
                            color: AppColors.text4,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: AppColors.surface1,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.jellyfinPurple,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.error,
                            width: 2,
                          ),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre mot de passe';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.jellyfinPurple,
                          foregroundColor: AppColors.text6,
                          disabledBackgroundColor: AppColors.surface1,
                          disabledForegroundColor: AppColors.text3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.text6,
                                ),
                              )
                            : const Text(
                                'Se connecter',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () {
                        setState(() {
                          _serverConfigured = false;
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.text4,
                      ),
                      child: const Text('Modifier l\'URL du serveur'),
                    ),
                  ],

                  // Message d'erreur
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: isDesktop ? 14 : 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
