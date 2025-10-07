import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:jellyfish/services/logger_service.dart';



/// Client HTTP personnalisé avec gestion des certificats SSL
/// Résout le problème "CERTIFICATE_VERIFY_FAILED" sur Windows
class CustomHttpClient extends http.BaseClient {
  final http.Client _inner;

  CustomHttpClient._internal(this._inner);

  /// Crée un client HTTP avec gestion appropriée des certificats SSL
  factory CustomHttpClient() {
    final ioClient = HttpClient();

    // Configuration pour accepter les certificats auto-signés en développement
    // ATTENTION: En production, vous devriez valider correctement les certificats
    ioClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // Pour le développement, accepter tous les certificats
      // En production, vous devriez vérifier le certificat correctement
      LoggerService.instance.warning('Certificat SSL non verifie pour $host:$port');
      LoggerService.instance.info('Issuer: ${cert.issuer}');
      LoggerService.instance.info('Subject: ${cert.subject}');
      return true; // Accepter le certificat
    };

    return CustomHttpClient._internal(IOClient(ioClient));
  }

  /// Crée un client HTTP avec validation stricte des certificats
  /// Utilise les certificats système de Windows
  factory CustomHttpClient.secure() {
    final ioClient = HttpClient();

    // Sur Windows, utiliser les certificats du système
    // Le SecurityContext par défaut devrait utiliser les certificats Windows
    ioClient.badCertificateCallback = null; // Validation stricte

    return CustomHttpClient._internal(IOClient(ioClient));
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}

