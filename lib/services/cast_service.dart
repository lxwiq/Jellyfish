import 'dart:async';
import 'dart:io';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:logging/logging.dart';

/// Service pour gérer les fonctionnalités de Chromecast
/// 
/// Ce service utilise le package flutter_chrome_cast pour gérer
/// la découverte, la connexion et le contrôle des appareils Chromecast
class CastService {
  static final CastService _instance = CastService._internal();
  factory CastService() => _instance;
  CastService._internal();

  final _logger = Logger('CastService');

  // Getters pour accéder aux streams du package
  Stream<GoogleCastSession?> get sessionStream =>
      GoogleCastSessionManager.instance.currentSessionStream;

  Stream<List<GoogleCastDevice>> get devicesStream =>
      GoogleCastDiscoveryManager.instance.devicesStream;

  Stream<GoggleCastMediaStatus?> get mediaStatusStream =>
      GoogleCastRemoteMediaClient.instance.mediaStatusStream;

  // Getters pour l'état actuel
  bool get isConnected =>
      GoogleCastSessionManager.instance.connectionState ==
      GoogleCastConnectState.connected;

  bool get isPlaying =>
      GoogleCastRemoteMediaClient.instance.mediaStatus?.playerState ==
      CastMediaPlayerState.playing;

  Duration get currentPosition =>
      GoogleCastRemoteMediaClient.instance.playerPosition;

  Duration? get duration =>
      GoogleCastRemoteMediaClient.instance.mediaStatus?.mediaInformation?.duration;

  /// Initialise le service de cast
  Future<void> initialize() async {
    try {
      _logger.info('🎬 Initialisation du service Cast');

      // Utiliser l'ID d'application par défaut de Google Cast
      const appId = GoogleCastDiscoveryCriteria.kDefaultApplicationId;
      _logger.info('📱 App ID: $appId');

      GoogleCastOptions? options;

      if (Platform.isIOS) {
        _logger.info('🍎 Configuration iOS');
        options = IOSGoogleCastOptions(
          GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(appId),
        );
      } else if (Platform.isAndroid) {
        _logger.info('🤖 Configuration Android');
        options = GoogleCastOptionsAndroid(
          appId: appId,
        );
      }

      if (options != null) {
        // Initialiser le contexte Google Cast
        _logger.info('⚙️ Initialisation du contexte Google Cast...');
        GoogleCastContext.instance.setSharedInstanceWithOptions(options);
        _logger.info('✅ Contexte Google Cast initialisé');

        // Écouter les changements de session
        sessionStream.listen((session) {
          _logger.info('📡 Session changée: ${session?.device?.friendlyName ?? "null"}');
        });

        // Écouter les appareils découverts
        devicesStream.listen((devices) {
          _logger.info('🔍 Appareils découverts: ${devices.length}');
          for (var device in devices) {
            _logger.info('   - ${device.friendlyName} (${device.modelName})');
          }
        });

        // Démarrer la découverte des appareils
        await startDiscovery();

        _logger.info('✅ Service Cast initialisé avec succès');
      } else {
        _logger.warning('⚠️ Plateforme non supportée pour le Cast');
      }
    } catch (e, stackTrace) {
      _logger.severe('❌ Erreur lors de l\'initialisation du Cast', e, stackTrace);
      rethrow;
    }
  }

  /// Démarre la découverte des appareils Chromecast
  Future<void> startDiscovery() async {
    try {
      _logger.info('🔍 Démarrage de la découverte des appareils Chromecast...');
      GoogleCastDiscoveryManager.instance.startDiscovery();
      _logger.info('✅ Découverte démarrée');
    } catch (e, stackTrace) {
      _logger.severe('❌ Erreur lors de la découverte', e, stackTrace);
    }
  }

  /// Arrête la découverte des appareils
  Future<void> stopDiscovery() async {
    try {
      GoogleCastDiscoveryManager.instance.stopDiscovery();
      _logger.info('Découverte arrêtée');
    } catch (e, stackTrace) {
      _logger.severe('Erreur lors de l\'arrêt de la découverte', e, stackTrace);
    }
  }

  /// Se connecte à un appareil Chromecast
  Future<bool> connectToDevice(GoogleCastDevice device) async {
    try {
      _logger.info('Connexion à l\'appareil: \${device.friendlyName}');
      await GoogleCastSessionManager.instance.startSessionWithDevice(device);
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Erreur lors de la connexion', e, stackTrace);
      return false;
    }
  }

  /// Se déconnecte de l'appareil actuel
  Future<void> disconnect() async {
    try {
      _logger.info('Déconnexion de l\'appareil');
      await GoogleCastSessionManager.instance.endSessionAndStopCasting();
    } catch (e, stackTrace) {
      _logger.severe('Erreur lors de la déconnexion', e, stackTrace);
    }
  }

  /// Charge et lit un média sur le Chromecast
  Future<bool> loadMedia({
    required String url,
    required String title,
    String? subtitle,
    String? imageUrl,
    Duration? startPosition,
    String? contentType,
  }) async {
    try {
      _logger.info('🎬 Chargement du média: \$title');
      _logger.info('📍 URL: \$url');
      _logger.info('⏱️ Position de départ: \${startPosition?.inSeconds ?? 0}s');

      // Créer les métadonnées du média
      final metadata = GoogleCastMovieMediaMetadata(
        title: title,
        subtitle: subtitle,
        studio: 'Jellyfin',
        releaseDate: DateTime.now(), // Requis par l'API
        images: imageUrl != null
            ? [
                GoogleCastImage(
                  url: Uri.parse(imageUrl),
                  height: 480,
                  width: 854,
                )
              ]
            : [],
      );

      // Créer l'information du média
      final mediaInfo = GoogleCastMediaInformationIOS(
        contentId: url, // Utiliser l'URL comme contentId unique
        streamType: CastMediaStreamType.buffered,
        contentUrl: Uri.parse(url),
        contentType: contentType ?? 'video/mp4',
        metadata: metadata,
      );

      _logger.info('📤 Envoi du média au Chromecast...');

      // Charger le média
      await GoogleCastRemoteMediaClient.instance.loadMedia(
        mediaInfo,
        autoPlay: true,
        playPosition: startPosition ?? Duration.zero,
        playbackRate: 1.0,
      );

      _logger.info('✅ Média chargé avec succès');
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Erreur lors du chargement du média', e, stackTrace);
      return false;
    }
  }

  /// Lit le média en cours
  Future<void> play() async {
    try {
      await GoogleCastRemoteMediaClient.instance.play();
      _logger.info('Lecture démarrée');
    } catch (e, stackTrace) {
      _logger.severe('Erreur lors de la lecture', e, stackTrace);
    }
  }

  /// Met en pause le média en cours
  Future<void> pause() async {
    try {
      await GoogleCastRemoteMediaClient.instance.pause();
      _logger.info('Lecture mise en pause');
    } catch (e, stackTrace) {
      _logger.severe('Erreur lors de la mise en pause', e, stackTrace);
    }
  }

  /// Arrête la lecture
  Future<void> stop() async {
    try {
      await GoogleCastRemoteMediaClient.instance.stop();
      _logger.info('Lecture arrêtée');
    } catch (e, stackTrace) {
      _logger.severe('Erreur lors de l\'arrêt', e, stackTrace);
    }
  }

  /// Se déplace à une position spécifique
  Future<void> seek(Duration position) async {
    try {
      await GoogleCastRemoteMediaClient.instance.seek(
        GoogleCastMediaSeekOption(position: position),
      );
      _logger.info('Seek à \${position.inSeconds}s');
    } catch (e, stackTrace) {
      _logger.severe('Erreur lors du seek', e, stackTrace);
    }
  }

  /// Bascule entre lecture et pause
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Nettoie les ressources
  void dispose() {
    stopDiscovery();
  }
}
