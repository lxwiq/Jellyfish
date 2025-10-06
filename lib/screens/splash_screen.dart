import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../services/update_service.dart';
import 'home/home_screen.dart';
import 'onboarding_screen.dart';


/// Écran de chargement avec le logo Jellyfin
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late Animation<double> _logoAnimation;
  late Animation<double> _fadeAnimation;

  String _updateStatus = 'Chargement...';
  bool _isDownloadingUpdate = false;

  @override
  void initState() {
    super.initState();

    // Animation du logo (scale + rotation)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Animation de fade pour le texte
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    // Démarrer l'animation du logo
    _logoController.forward();

    // Attendre un peu puis démarrer le fade du texte
    await Future.delayed(const Duration(milliseconds: 500));
    _fadeController.forward();

    // Vérifier et télécharger les mises à jour Shorebird
    await _checkForUpdates();

    // Vérifier le statut d'authentification
    ref.read(authStateProvider.notifier).checkAuthStatus();

    // Attendre la fin des animations puis naviguer
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _navigateToNextScreen();
    }
  }

  Future<void> _checkForUpdates() async {
    await for (final status in UpdateService.instance.checkAndDownloadUpdates()) {
      if (mounted) {
        setState(() {
          _updateStatus = status.message;
          _isDownloadingUpdate = status.isDownloading;
        });
      }
    }
  }

  void _navigateToNextScreen() {
    final auth = ref.read(authStateProvider);
    final bool goToOnboarding = auth.user == null || auth.token == null;
    final Widget next = goToOnboarding
        ? const OnboardingScreen()
        : const HomeScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => next,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background1,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animé
            AnimatedBuilder(
              animation: _logoAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoAnimation.value,
                  child: Transform.rotate(
                    angle: _logoAnimation.value * 0.1, // Légère rotation
                    child: Container(
                      width: 120,
                      height: 120,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background2,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.jellyfinPurple.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: SvgPicture.asset(
                        'assets/images/jelly_logo.svg',
                        colorFilter: const ColorFilter.mode(
                          AppColors.jellyfinPurple,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Texte animé
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    children: [
                      Text(
                        'Jellyfish',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.text6,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),

                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 48),

            // Indicateur de chargement
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isDownloadingUpdate
                                ? AppColors.jellyfinPurple
                                : AppColors.jellyfinPurple.withValues(alpha: 0.8),
                          ),
                          backgroundColor: AppColors.surface1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _updateStatus,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.text4,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
