import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:jellyfish/services/logger_service.dart';

import 'package:http/io_client.dart';


/// Cache manager personnalisé pour les images Jellyfin
/// Utilise un client HTTP qui accepte les certificats SSL auto-signés
class CustomCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'jellyfinImageCache';
  static CustomCacheManager? _instance;

  factory CustomCacheManager() {
    _instance ??= CustomCacheManager._();
    return _instance!;
  }

  CustomCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 200,
            repo: JsonCacheInfoRepository(databaseName: key),
            fileService: CustomHttpFileService(),
          ),
        );
}

/// Service de fichiers HTTP personnalisé avec gestion des certificats SSL
class CustomHttpFileService extends HttpFileService {
  CustomHttpFileService() : super(httpClient: _createHttpClient());

  static http.Client _createHttpClient() {
    // Sur Web, utiliser le client HTTP par défaut compatible navigateur
    if (kIsWeb) {
      return http.Client();
    }

    final ioClient = HttpClient();

    // Configuration pour accepter les certificats auto-signés
    // Même configuration que CustomHttpClient
    ioClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
      LoggerService.instance.warning('[Image Cache] Certificat SSL non verifie pour $host:$port');
      LoggerService.instance.info('Issuer: ${cert.issuer}');
      LoggerService.instance.info('Subject: ${cert.subject}');
      return true; // Accepter le certificat
    };

    return IOClient(ioClient);
  }
}

