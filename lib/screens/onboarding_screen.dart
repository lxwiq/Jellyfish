import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/services_provider.dart';
import 'home/home_screen.dart';

/// Écran d'onboarding avec flux de connexion en deux étapes
/// Étape 1: Saisie de l'URL du serveur
/// Étape 2: Saisie des identifiants (username/password)
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final TextEditingController _serverUrlController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  int _currentPage = 0;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _pageController.dispose();
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Valide l'URL du serveur et passe à l'étape suivante
  Future<void> _validateServerUrl() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final serverUrl = _serverUrlController.text.trim();

    if (serverUrl.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer l\'URL du serveur';
        _isLoading = false;
      });
      return;
    }

    // Validation basique de l'URL
    if (!serverUrl.startsWith('http://') && !serverUrl.startsWith('https://')) {
      setState(() {
        _errorMessage = 'L\'URL doit commencer par http:// ou https://';
        _isLoading = false;
      });
      return;
    }

    // Vérifier que le serveur est accessible
    try {
      final jellyfinService = ref.read(jellyfinServiceProvider);
      await jellyfinService.checkServerHealth(serverUrl);

      // Si la vérification réussit, passer à la page suivante
      setState(() {
        _isLoading = false;
      });

      // Animation vers la page suivante
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      setState(() {
        // Extraire le message d'erreur propre
        String errorMsg = e.toString();
        if (errorMsg.startsWith('Exception: ')) {
          errorMsg = errorMsg.substring('Exception: '.length);
        }
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  /// Tente de se connecter avec les identifiants
  Future<void> _attemptLogin() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final serverUrl = _serverUrlController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez remplir tous les champs';
        _isLoading = false;
      });
      return;
    }

    try {
      await ref.read(authStateProvider.notifier).login(
        username,
        password,
        serverUrl,
      );

      // Navigation vers la page d'accueil après un login réussi
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        // Extraire le message d'erreur propre
        String errorMsg = e.toString();
        if (errorMsg.startsWith('Exception: ')) {
          errorMsg = errorMsg.substring('Exception: '.length);
        }
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background1,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                  _errorMessage = null;
                });
              },
              children: [
                _buildServerUrlPage(),
                _buildLoginPage(),
              ],
            ),
            // Bouton retour pour la page 2
            if (_currentPage == 1)
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: AppColors.text6,
                  ),
                  onPressed: () {
                    _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Page 1: Saisie de l'URL du serveur
  Widget _buildServerUrlPage() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dns_outlined,
              size: 80,
              color: AppColors.jellyfinPurple,
            ),
            const SizedBox(height: 32),
            Text(
              'Serveur Jellyfin',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.text6,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Entrez l\'URL de votre serveur Jellyfin',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.text5,
                  ),
            ),
            const SizedBox(height: 48),
            TextField(
              controller: _serverUrlController,
              decoration: InputDecoration(
                labelText: 'URL du serveur',
                hintText: 'https://jellyfin.example.com',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.background2,
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
              enabled: !_isLoading,
              onSubmitted: (_) => _validateServerUrl(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red[400],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red[400],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _validateServerUrl,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.jellyfinPurple,
                  foregroundColor: AppColors.text6,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Suivant',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Page 2: Saisie des identifiants
  Widget _buildLoginPage() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 80,
              color: AppColors.jellyfinPurple,
            ),
            const SizedBox(height: 32),
            Text(
              'Connexion',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.text6,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Entrez vos identifiants Jellyfin',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.text5,
                  ),
            ),
            const SizedBox(height: 48),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Nom d\'utilisateur',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.background2,
              ),
              autocorrect: false,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.background2,
              ),
              obscureText: _obscurePassword,
              autocorrect: false,
              enabled: !_isLoading,
              onSubmitted: (_) => _attemptLogin(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red[400],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red[400],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _attemptLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.jellyfinPurple,
                  foregroundColor: AppColors.text6,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Se connecter',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

