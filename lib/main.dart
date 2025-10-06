import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:media_kit/media_kit.dart';
import 'theme/material_theme.dart';
import 'screens/splash_screen.dart';
import 'providers/services_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de MediaKit pour la lecture vidéo
  MediaKit.ensureInitialized();

  // Configuration de l'orientation (portrait uniquement pour mobile)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialisation de SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

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

