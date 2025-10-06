import 'dart:async';
import 'package:chopper/chopper.dart';

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
    print('🔑 Jellyfin Interceptor - Adding headers');
    print('   URL: ${chain.request.url}');
    print('   Method: ${chain.request.method}');
    print('   X-Emby-Authorization: $authHeader');

    final request = applyHeaders(
      chain.request,
      {
        'X-Emby-Authorization': authHeader,
        'Content-Type': 'application/json',
      },
      override: false,
    );

    print('   All headers: ${request.headers}');

    final response = await chain.proceed(request);

    print('📨 Response received:');
    print('   Status: ${response.statusCode}');
    print('   Success: ${response.isSuccessful}');
    if (!response.isSuccessful) {
      print('   Error: ${response.error}');
      print('   Body: ${response.body}');
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

