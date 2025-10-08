import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:logging/logging.dart';

/// Service complet pour gérer les fonctionnalités de Chromecast
///
/// Ce service utilise le package flutter_chrome_cast pour gérer :
/// - La découverte et connexion aux appareils
/// - Le contrôle de la lecture (play, pause, seek, stop)
/// - La gestion des sous-titres et pistes audio
/// - Le contrôle du volume
/// - La gestion de la file d'attente
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

  bool get isPaused =>
      GoogleCastRemoteMediaClient.instance.mediaStatus?.playerState ==
      CastMediaPlayerState.paused;

  bool get isBuffering =>
      GoogleCastRemoteMediaClient.instance.mediaStatus?.playerState ==
      CastMediaPlayerState.buffering;

  Duration get currentPosition =>
      GoogleCastRemoteMediaClient.instance.playerPosition;

  Duration? get duration =>
      GoogleCastRemoteMediaClient.instance.mediaStatus?.mediaInformation?.duration;

  GoogleCastSession? get currentSession =>
      GoogleCastSessionManager.instance.currentSession;

  GoggleCastMediaStatus? get mediaStatus =>
      GoogleCastRemoteMediaClient.instance.mediaStatus;

  /// Initialise le service de cast
  Future<void> initialize() async {
    try {
      _logger.info('🎬 Initialisation du service Cast');

      // Utiliser l'ID d'application par défaut de Google Cast
      const appId = GoogleCastDiscoveryCriteria.kDefaultApplicationId;
      _logger.info('📱 App ID: $appId');

      GoogleCastOptions? options;

      if (kIsWeb) {
        _logger.info('🌐 Cast non disponible sur Web');
        return;
      } else if (Platform.isIOS) {
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

  /// Charge et lit un média sur le Chromecast avec support complet
  Future<bool> loadMedia({
    required String url,
    required String title,
    String? subtitle,
    String? imageUrl,
    Duration? startPosition,
    String? contentType,
    List<GoogleCastMediaTrack>? subtitleTracks,
    List<int>? activeTrackIds,
  }) async {
    try {
      _logger.info('🎬 Chargement du média: $title');
      _logger.info('📍 URL: $url');
      _logger.info('⏱️ Position de départ: ${startPosition?.inSeconds ?? 0}s');
      if (subtitleTracks != null && subtitleTracks.isNotEmpty) {
        _logger.info('📝 Sous-titres disponibles: ${subtitleTracks.length}');
      }

      // Créer les métadonnées du média
      final metadata = GoogleCastMovieMediaMetadata(
        title: title,
        subtitle: subtitle,
        studio: 'Jellyfin',
        releaseDate: DateTime.now(),
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

      // Créer l'information du média (cross-platform)
      final mediaInfo = GoogleCastMediaInformation(
        contentId: url,
        streamType: CastMediaStreamType.buffered,
        contentUrl: Uri.parse(url),
        contentType: contentType ?? 'video/mp4',
        metadata: metadata,
        tracks: subtitleTracks ?? [],
      );

      _logger.info('📤 Envoi du média au Chromecast...');

      // Charger le média avec les pistes actives
      await GoogleCastRemoteMediaClient.instance.loadMedia(
        mediaInfo,
        autoPlay: true,
        playPosition: startPosition ?? Duration.zero,
        playbackRate: 1.0,
        activeTrackIds: activeTrackIds,
      );

      _logger.info('✅ Média chargé avec succès');
      return true;
    } catch (e, stackTrace) {
      _logger.severe('❌ Erreur lors du chargement du média', e, stackTrace);
      return false;
    }
  }

  /// Charge un média dans une file d'attente
  Future<bool> loadMediaQueue({
    required List<GoogleCastQueueItem> items,
    int startIndex = 0,
    Duration? startPosition,
  }) async {
    try {
      _logger.info('🎬 Chargement de la file d\'attente: ${items.length} éléments');

      await GoogleCastRemoteMediaClient.instance.queueLoadItems(
        items,
        options: GoogleCastQueueLoadOptions(
          startIndex: startIndex,
          playPosition: startPosition ?? Duration.zero,
        ),
      );

      _logger.info('✅ File d\'attente chargée avec succès');
      return true;
    } catch (e, stackTrace) {
      _logger.severe('❌ Erreur lors du chargement de la file d\'attente', e, stackTrace);
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

  // ============ Contrôles de la file d'attente ============

  /// Passe à l'élément suivant de la file d'attente
  Future<void> queueNext() async {
    try {
      await GoogleCastRemoteMediaClient.instance.queueNextItem();
      _logger.info('⏭️ Passage à l\'élément suivant');
    } catch (e, stackTrace) {
      _logger.severe('❌ Erreur lors du passage à l\'élément suivant', e, stackTrace);
    }
  }

  /// Revient à l'élément précédent de la file d'attente
  Future<void> queuePrevious() async {
    try {
      await GoogleCastRemoteMediaClient.instance.queuePrevItem();
      _logger.info('⏮️ Retour à l\'élément précédent');
    } catch (e, stackTrace) {
      _logger.severe('❌ Erreur lors du retour à l\'élément précédent', e, stackTrace);
    }
  }

  /// Insère un élément dans la file d'attente
  Future<void> queueInsertItem(GoogleCastQueueItem item, {int? beforeItemId}) async {
    try {
      await GoogleCastRemoteMediaClient.instance.queueInsertItems(
        [item],
        beforeItemWithId: beforeItemId,
      );
      _logger.info('➕ Élément ajouté à la file d\'attente');
    } catch (e, stackTrace) {
      _logger.severe('❌ Erreur lors de l\'ajout à la file d\'attente', e, stackTrace);
    }
  }

  // ============ Contrôles des sous-titres ============

  /// Active ou désactive une piste de sous-titres
  /// Note: setActiveTrackIds n'est pas disponible dans la version actuelle du package
  /// Les pistes doivent être activées lors du chargement du média via loadMedia()
  Future<void> setActiveTrack(int? trackId) async {
    try {
      _logger.warning('⚠️ setActiveTrack: Cette fonctionnalité nécessite de recharger le média avec les nouvelles pistes actives');
      _logger.info('💡 Utilisez loadMedia() avec le paramètre activeTrackIds pour activer les pistes');

      // TODO: Implémenter le rechargement du média avec les nouvelles pistes actives
      // Cela nécessiterait de sauvegarder l'état actuel du média et de le recharger
      // avec les nouveaux activeTrackIds

      if (trackId == null) {
        _logger.info('📝 Demande de désactivation des sous-titres');
      } else {
        _logger.info('📝 Demande d\'activation de la piste: $trackId');
      }
    } catch (e, stackTrace) {
      _logger.severe('❌ Erreur lors du changement de piste', e, stackTrace);
    }
  }

  /// Récupère les pistes disponibles
  List<GoogleCastMediaTrack>? getAvailableTracks() {
    return mediaStatus?.mediaInformation?.tracks;
  }

  /// Récupère les IDs des pistes actives
  List<int>? getActiveTrackIds() {
    return mediaStatus?.activeTrackIds;
  }

  // ============ Contrôles du volume ============
  // Note: Les méthodes de contrôle du volume ne sont pas disponibles dans la version actuelle
  // du package flutter_chrome_cast. Le contrôle du volume doit être fait via l'interface
  // utilisateur native du Chromecast ou via les contrôles système de l'appareil.

  /// Définit le volume (0.0 à 1.0)
  /// Note: setVolume n'est pas disponible dans la version actuelle du package
  Future<void> setVolume(double volume) async {
    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      _logger.warning('⚠️ setVolume: Cette fonctionnalité n\'est pas disponible dans la version actuelle du package');
      _logger.info('💡 Utilisez les contrôles système ou l\'interface Chromecast pour ajuster le volume');
      _logger.info('🔊 Volume demandé: ${(clampedVolume * 100).toInt()}%');
    } catch (e, stackTrace) {
      _logger.severe('❌ Erreur lors du changement de volume', e, stackTrace);
    }
  }

  /// Active ou désactive le mode muet
  /// Note: setMute n'est pas disponible dans la version actuelle du package
  Future<void> setMuted(bool muted) async {
    try {
      _logger.warning('⚠️ setMuted: Cette fonctionnalité n\'est pas disponible dans la version actuelle du package');
      _logger.info('💡 Utilisez les contrôles système ou l\'interface Chromecast pour couper/activer le son');
      _logger.info(muted ? '🔇 Demande de coupure du son' : '🔊 Demande d\'activation du son');
    } catch (e, stackTrace) {
      _logger.severe('❌ Erreur lors du changement de muet', e, stackTrace);
    }
  }

  /// Récupère le volume actuel (0.0 à 1.0)
  /// Note: volume getter n'est pas disponible dans la version actuelle du package
  double? getVolume() {
    _logger.warning('⚠️ getVolume: Cette fonctionnalité n\'est pas disponible dans la version actuelle du package');
    return null; // currentSession?.volume; // Non disponible
  }

  /// Vérifie si le son est coupé
  /// Note: isMuted getter n'est pas disponible dans la version actuelle du package
  bool? isMuted() {
    _logger.warning('⚠️ isMuted: Cette fonctionnalité n\'est pas disponible dans la version actuelle du package');
    return null; // currentSession?.isMuted; // Non disponible
  }

  // ============ Utilitaires ============

  /// Récupère le nom de l'appareil connecté
  String? getConnectedDeviceName() {
    return currentSession?.device?.friendlyName;
  }

  /// Récupère les informations du média en cours
  GoogleCastMediaInformation? getCurrentMediaInfo() {
    return mediaStatus?.mediaInformation;
  }

  /// Vérifie si un média est chargé
  bool get hasMedia => mediaStatus?.mediaInformation != null;

  /// Nettoie les ressources
  void dispose() {
    stopDiscovery();
  }
}
