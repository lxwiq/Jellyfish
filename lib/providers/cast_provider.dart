import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import '../services/cast_service.dart';
import '../jellyfin/jellyfin_open_api.swagger.dart';

/// Provider pour le service de cast
final castServiceProvider = Provider<CastService>((ref) {
  return CastService();
});

/// Provider pour l'état de la session de cast
final castSessionProvider = StreamProvider<GoogleCastSession?>((ref) {
  final castService = ref.watch(castServiceProvider);
  return castService.sessionStream;
});

/// Provider pour l'état du média en cours de cast
final castMediaStatusProvider = StreamProvider<GoggleCastMediaStatus?>((ref) {
  final castService = ref.watch(castServiceProvider);
  return castService.mediaStatusStream;
});

/// Provider pour la liste des appareils disponibles
final castDevicesProvider = StreamProvider<List<GoogleCastDevice>>((ref) {
  final castService = ref.watch(castServiceProvider);
  return castService.devicesStream;
});

/// Provider pour savoir si on est connecté à un appareil
final isConnectedToCastProvider = Provider<bool>((ref) {
  final sessionAsync = ref.watch(castSessionProvider);
  return sessionAsync.when(
    data: (session) => session != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider pour savoir si le média est en cours de lecture
final isCastPlayingProvider = Provider<bool>((ref) {
  final statusAsync = ref.watch(castMediaStatusProvider);
  return statusAsync.when(
    data: (status) => status?.playerState == CastMediaPlayerState.playing,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider pour la position actuelle de lecture
final castPositionProvider = Provider<Duration?>((ref) {
  final castService = ref.watch(castServiceProvider);
  return castService.currentPosition;
});

/// Provider pour la durée totale du média
final castDurationProvider = Provider<Duration?>((ref) {
  final castService = ref.watch(castServiceProvider);
  return castService.duration;
});

/// Provider pour le volume actuel
final castVolumeProvider = Provider<double?>((ref) {
  final castService = ref.watch(castServiceProvider);
  // Forcer la mise à jour en écoutant la session
  ref.watch(castSessionProvider);
  return castService.getVolume();
});

/// Provider pour l'état muet
final castMutedProvider = Provider<bool?>((ref) {
  final castService = ref.watch(castServiceProvider);
  // Forcer la mise à jour en écoutant la session
  ref.watch(castSessionProvider);
  return castService.isMuted();
});

/// Provider pour les pistes disponibles
final castAvailableTracksProvider = Provider<List<GoogleCastMediaTrack>?>((ref) {
  final castService = ref.watch(castServiceProvider);
  // Forcer la mise à jour en écoutant le statut du média
  ref.watch(castMediaStatusProvider);
  return castService.getAvailableTracks();
});

/// Provider pour les IDs des pistes actives
final castActiveTrackIdsProvider = Provider<List<int>?>((ref) {
  final castService = ref.watch(castServiceProvider);
  // Forcer la mise à jour en écoutant le statut du média
  ref.watch(castMediaStatusProvider);
  return castService.getActiveTrackIds();
});

/// Provider pour le nom de l'appareil connecté
final castDeviceNameProvider = Provider<String?>((ref) {
  final sessionAsync = ref.watch(castSessionProvider);
  return sessionAsync.when(
    data: (session) => session?.device?.friendlyName,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider pour savoir si un média est chargé
final castHasMediaProvider = Provider<bool>((ref) {
  final castService = ref.watch(castServiceProvider);
  // Forcer la mise à jour en écoutant le statut du média
  ref.watch(castMediaStatusProvider);
  return castService.hasMedia;
});

/// Provider pour savoir si le média est en buffering
final castIsBufferingProvider = Provider<bool>((ref) {
  final statusAsync = ref.watch(castMediaStatusProvider);
  return statusAsync.when(
    data: (status) => status?.playerState == CastMediaPlayerState.buffering,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// État pour gérer le média en cours de cast
class CastMediaState {
  final String? itemId;
  final String? title;
  final String? subtitle;
  final String? imageUrl;
  final BaseItemDto? item;

  const CastMediaState({
    this.itemId,
    this.title,
    this.subtitle,
    this.imageUrl,
    this.item,
  });

  CastMediaState copyWith({
    String? itemId,
    String? title,
    String? subtitle,
    String? imageUrl,
    BaseItemDto? item,
  }) {
    return CastMediaState(
      itemId: itemId ?? this.itemId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      item: item ?? this.item,
    );
  }
}

/// Notifier pour gérer l'état du média en cours de cast
class CastMediaNotifier extends StateNotifier<CastMediaState> {
  CastMediaNotifier() : super(const CastMediaState());

  void setMedia({
    required String itemId,
    required String title,
    String? subtitle,
    String? imageUrl,
    BaseItemDto? item,
  }) {
    state = CastMediaState(
      itemId: itemId,
      title: title,
      subtitle: subtitle,
      imageUrl: imageUrl,
      item: item,
    );
  }

  void clearMedia() {
    state = const CastMediaState();
  }
}

/// Provider pour l'état du média en cours de cast
final castMediaStateProvider = StateNotifierProvider<CastMediaNotifier, CastMediaState>((ref) {
  return CastMediaNotifier();
});

