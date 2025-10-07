import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:media_kit/media_kit.dart';
import 'theme/material_theme.dart';
import 'screens/splash_screen.dart';
import 'providers/services_provider.dart';
import 'services/logger_service.dart';
import 'services/permission_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser le logger en premier
  await LoggerService.instance.initialize();

  // Capturer les erreurs Flutter
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    LoggerService.instance.error(
      'Flutter Error: ${details.exception}',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // Capturer les erreurs Dart non gérées
  PlatformDispatcher.instance.onError = (error, stack) {
    LoggerService.instance.error(
      'Unhandled Error: $error',
      error: error,
      stackTrace: stack,
    );
    return true;
  };

  // Initialisation de MediaKit pour la lecture vidéo
  MediaKit.ensureInitialized();

  // Configuration de l'orientation (portrait uniquement pour mobile)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialisation de SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Demander les permissions nécessaires
  await PermissionService.instance.requestInitialPermissions();

  LoggerService.instance.info('Application initialisée avec succès');

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const JellyfishApp(),
    ),
  );
}

class JellyfishApp extends StatelessWidget {
  const JellyfishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jellyfin Client',
      theme: JellyfishMaterialTheme.darkTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

