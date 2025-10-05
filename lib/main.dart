import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'core/di/service_locator.dart';
import 'theme/material_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration de l'orientation (portrait uniquement pour mobile)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialisation de l'injection de dépendances
  await ServiceLocator.init();

  runApp(
    const ProviderScope(
      child: JellyfishApp(),
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


