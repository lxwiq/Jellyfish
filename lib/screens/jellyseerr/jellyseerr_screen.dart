import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jellyfish/providers/jellyseerr_provider.dart';
import 'jellyseerr_setup_screen.dart';
import 'jellyseerr_discover_screen.dart';

/// Écran principal de Jellyseerr qui gère la navigation entre setup et requêtes
class JellyseerrScreen extends ConsumerStatefulWidget {
  const JellyseerrScreen({super.key});

  @override
  ConsumerState<JellyseerrScreen> createState() => _JellyseerrScreenState();
}

class _JellyseerrScreenState extends ConsumerState<JellyseerrScreen> {
  @override
  void initState() {
    super.initState();
    // Vérifier la session au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(jellyseerrAuthStateProvider.notifier).checkSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(jellyseerrAuthStateProvider);

    // Afficher un loader pendant la vérification de la session
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Si non authentifié, afficher l'écran de setup
    if (!authState.isAuthenticated) {
      return const JellyseerrSetupScreen();
    }

    // Si authentifié, afficher l'écran de découverte
    return const JellyseerrDiscoverScreen();
  }
}

