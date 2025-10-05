import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Service locator global pour l'injection de dépendances
final GetIt getIt = GetIt.instance;

/// Configuration de l'injection de dépendances
class ServiceLocator {
  static Future<void> init() async {
    // Configuration de Dio pour les appels HTTP
    final dio = Dio();
    dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Ajout d'intercepteurs pour le logging en mode debug
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
        error: true,
      ),
    );

    // Enregistrement des services
    getIt.registerLazySingleton<Dio>(() => dio);
    
    // Configuration du cache manager pour les images
    getIt.registerLazySingleton<CacheManager>(
      () => DefaultCacheManager(),
    );

    // TODO: Ajouter ici les autres services (API client, repositories, etc.)
    // Une fois que l'API Jellyfin sera configurée
  }

  /// Nettoyage des ressources
  static Future<void> dispose() async {
    await getIt.reset();
  }
}
