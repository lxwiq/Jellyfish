import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services_provider.dart';
import '../jellyfin/jellyfin_open_api.swagger.dart';

/// Provider pour gérer l'état du lecteur vidéo
final videoPlayerProvider = StateNotifierProvider<VideoPlayerNotifier, VideoPlayerState>((ref) {
  return VideoPlayerNotifier(ref);
});

/// État du lecteur vidéo
class VideoPlayerState {
  final String? currentItemId;
  final Duration? currentPosition;
  final Duration? duration;
  final bool isPlaying;
  final bool isBuffering;
  final double volume;
  final double playbackSpeed;
  final PlaybackInfoResponse? playbackInfo;

  const VideoPlayerState({
    this.currentItemId,
    this.currentPosition,
    this.duration,
    this.isPlaying = false,
    this.isBuffering = false,
    this.volume = 1.0,
    this.playbackSpeed = 1.0,
    this.playbackInfo,
  });

  VideoPlayerState copyWith({
    String? currentItemId,
    Duration? currentPosition,
    Duration? duration,
    bool? isPlaying,
    bool? isBuffering,
    double? volume,
    double? playbackSpeed,
    PlaybackInfoResponse? playbackInfo,
  }) {
    return VideoPlayerState(
      currentItemId: currentItemId ?? this.currentItemId,
      currentPosition: currentPosition ?? this.currentPosition,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      volume: volume ?? this.volume,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      playbackInfo: playbackInfo ?? this.playbackInfo,
    );
  }
}

/// Notifier pour gérer les actions du lecteur vidéo
class VideoPlayerNotifier extends StateNotifier<VideoPlayerState> {
  final Ref ref;

  VideoPlayerNotifier(this.ref) : super(const VideoPlayerState());

  /// Récupère les informations de playback depuis Jellyfin
  Future<PlaybackInfoResponse?> fetchPlaybackInfo(String itemId, String userId) async {
    final jellyfinService = ref.read(jellyfinServiceProvider);
    final playbackInfo = await jellyfinService.getPlaybackInfo(itemId, userId);

    if (playbackInfo != null) {
      state = state.copyWith(playbackInfo: playbackInfo);
    }

    return playbackInfo;
  }

  /// Obtient l'URL de streaming pour un item
  String? getStreamUrl(String itemId, {
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    bool useHls = false, // Revenir au streaming direct par défaut
  }) {
    final jellyfinService = ref.read(jellyfinServiceProvider);

    if (useHls) {
      return jellyfinService.getHlsStreamUrl(
        itemId,
        mediaSourceId: mediaSourceId,
        audioStreamIndex: audioStreamIndex,
        subtitleStreamIndex: subtitleStreamIndex,
      );
    } else {
      return jellyfinService.getVideoStreamUrl(
        itemId,
        mediaSourceId: mediaSourceId,
        audioStreamIndex: audioStreamIndex,
        subtitleStreamIndex: subtitleStreamIndex,
      );
    }
  }

  /// Met à jour l'item en cours de lecture
  void setCurrentItem(String itemId) {
    state = state.copyWith(currentItemId: itemId);
  }

  /// Met à jour la position de lecture
  void updatePosition(Duration position) {
    state = state.copyWith(currentPosition: position);
  }

  /// Met à jour la durée totale
  void updateDuration(Duration duration) {
    state = state.copyWith(duration: duration);
  }

  /// Met à jour l'état de lecture
  void setPlaying(bool isPlaying) {
    state = state.copyWith(isPlaying: isPlaying);
  }

  /// Met à jour l'état de buffering
  void setBuffering(bool isBuffering) {
    state = state.copyWith(isBuffering: isBuffering);
  }

  /// Met à jour le volume
  void setVolume(double volume) {
    state = state.copyWith(volume: volume.clamp(0.0, 1.0));
  }

  /// Met à jour la vitesse de lecture
  void setPlaybackSpeed(double speed) {
    state = state.copyWith(playbackSpeed: speed);
  }

  /// Réinitialise l'état
  void reset() {
    state = const VideoPlayerState();
  }
}

