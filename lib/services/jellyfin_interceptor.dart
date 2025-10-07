import 'dart:async';
import 'package:chopper/chopper.dart';
import 'package:jellyfish/services/logger_service.dart';



/// Intercepteur pour ajouter les headers requis par l'API Jellyfin
class JellyfinInterceptor implements Interceptor {
  final String? accessToken;
  final String clientName;
  final String clientVersion;
  final String deviceId;
  final String deviceName;

  JellyfinInterceptor({
    this.accessToken,
    this.clientName = 'Jellyfish',
    this.clientVersion = '1.0.0',
    required this.deviceId,
    this.deviceName = 'Flutter App',
  });

  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(
    Chain<BodyType> chain,
  ) async {
    final authHeader = _buildAuthHeader();
    await LoggerService.instance.debug('Jellyfin Interceptor - Adding headers');
    await LoggerService.instance.debug('URL: ${chain.request.url}');
    await LoggerService.instance.debug('Method: ${chain.request.method}');
    await LoggerService.instance.debug('X-Emby-Authorization: $authHeader');

    final request = applyHeaders(
      chain.request,
      {
        'X-Emby-Authorization': authHeader,
        'Content-Type': 'application/json',
      },
      override: false,
    );

    await LoggerService.instance.debug('All headers: ${request.headers}');

    final response = await chain.proceed(request);

    await LoggerService.instance.debug('Response received:');
    await LoggerService.instance.debug('Status: ${response.statusCode}');
    await LoggerService.instance.debug('Success: ${response.isSuccessful}');
    if (!response.isSuccessful) {
      await LoggerService.instance.warning('Error: ${response.error}');
      await LoggerService.instance.debug('Body: ${response.body}');
    }

    return response;
  }

  /// Construit le header d'authentification Jellyfin/Emby
  String _buildAuthHeader() {
    final parts = [
      'MediaBrowser Client="$clientName"',
      'Device="$deviceName"',
      'DeviceId="$deviceId"',
      'Version="$clientVersion"',
    ];

    if (accessToken != null && accessToken!.isNotEmpty) {
      parts.add('Token="$accessToken"');
    }

    return parts.join(', ');
  }
}

