import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../theme/app_colors.dart';
import '../../providers/video_player_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/services_provider.dart';
import '../../jellyfin/jellyfin_open_api.swagger.dart';
import 'widgets/custom_video_controls.dart';

/// Écran de lecture vidéo avec media_kit
class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String itemId;
  final BaseItemDto? item;
  final int? startPositionTicks;

  const VideoPlayerScreen({
    super.key,
    required this.itemId,
    this.item,
    this.startPositionTicks,
  });

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  late final Player player;
  late final VideoController controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  BoxFit _videoFit = BoxFit.contain; // Mode d'affichage par défaut
  Timer? _progressReportTimer;
  bool _hasReportedStart = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // Créer le player
      player = Player();
      controller = VideoController(player);

      // Récupérer les informations de playback depuis Jellyfin
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;

      if (userId == null) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Utilisateur non connecté';
        });
        return;
      }

      print('🎬 Récupération des informations de playback...');
      await ref.read(videoPlayerProvider.notifier).fetchPlaybackInfo(
        widget.itemId,
        userId,
      );

      // Obtenir l'URL de streaming
      final streamUrl = ref.read(videoPlayerProvider.notifier).getStreamUrl(widget.itemId);

      if (streamUrl == null) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Impossible de générer l\'URL de streaming';
        });
        return;
      }

      print('🎬 URL de streaming: $streamUrl');

      // Configurer la position de départ si disponible
      try {
        if (widget.startPositionTicks != null) {
          final startSeconds = widget.startPositionTicks! ~/ 10000000;
          print('🎬 Ouverture de la vidéo avec position de départ: ${startSeconds}s');

          // Ouvrir la vidéo et démarrer la lecture
          await player.open(
            Media(streamUrl),
            play: true,
          );

          // Attendre que la vidéo soit prête et positionner
          _scheduleSeek(startSeconds);
        } else {
          print('🎬 Ouverture de la vidéo sans position de départ');
          await player.open(
            Media(streamUrl),
            play: true,
          );
          print('✅ Vidéo ouverte');
        }
      } catch (e) {
        print('❌ Erreur lors de l\'ouverture de la vidéo: $e');
        setState(() {
          _hasError = true;
          _errorMessage = 'Erreur lors de l\'ouverture de la vidéo: $e';
        });
        return;
      }

      // Mettre en plein écran
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      setState(() {
        _isInitialized = true;
      });

      // Démarrer le reporting de progression après l'initialisation
      _startProgressReporting();
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation du player: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Erreur lors de l\'initialisation: $e';
      });
    }
  }

  /// Démarre le reporting de progression vers Jellyfin
  void _startProgressReporting() {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) return;

    // Signaler le début de lecture
    _reportPlaybackStart();

    // Créer un timer pour reporter la progression toutes les 10 secondes
    _progressReportTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _reportPlaybackProgress();
    });
  }

  /// Signale le début de lecture à Jellyfin
  Future<void> _reportPlaybackStart() async {
    if (_hasReportedStart) return;

    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    final jellyfinService = ref.read(jellyfinServiceProvider);

    if (userId == null) return;

    final positionTicks = player.state.position.inMicroseconds * 10;

    await jellyfinService.reportPlaybackStart(
      itemId: widget.itemId,
      userId: userId,
      positionTicks: positionTicks,
    );

    _hasReportedStart = true;
  }

  /// Signale la progression de lecture à Jellyfin
  Future<void> _reportPlaybackProgress() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    final jellyfinService = ref.read(jellyfinServiceProvider);

    if (userId == null) return;

    final positionTicks = player.state.position.inMicroseconds * 10;
    final isPaused = !player.state.playing;

    await jellyfinService.reportPlaybackProgress(
      itemId: widget.itemId,
      userId: userId,
      positionTicks: positionTicks,
      isPaused: isPaused,
    );
  }

  /// Signale l'arrêt de lecture à Jellyfin
  Future<void> _reportPlaybackStopped() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    final jellyfinService = ref.read(jellyfinServiceProvider);

    if (userId == null) return;

    final positionTicks = player.state.position.inMicroseconds * 10;

    await jellyfinService.reportPlaybackStopped(
      itemId: widget.itemId,
      userId: userId,
      positionTicks: positionTicks,
    );
  }

  /// Planifie le seek à la position de départ après que la vidéo soit prête
  void _scheduleSeek(int startSeconds) {
    // Essayer plusieurs fois avec des délais croissants
    _attemptSeek(startSeconds, 0);
  }

  void _attemptSeek(int startSeconds, int attempt) async {
    if (attempt >= 10) {
      print('⚠️ Abandon du positionnement après 10 tentatives');
      return;
    }

    // Délais croissants : 500ms, 1s, 1.5s, 2s, etc.
    final delay = Duration(milliseconds: 500 + (attempt * 500));
    await Future.delayed(delay);

    final duration = player.state.duration;
    if (duration.inSeconds > 0) {
      print('🎬 Tentative ${attempt + 1}: Durée détectée: ${duration.inSeconds}s, positionnement à ${startSeconds}s');
      try {
        await player.seek(Duration(seconds: startSeconds));
        print('✅ Vidéo positionnée à ${startSeconds}s après ${attempt + 1} tentative(s)');
      } catch (e) {
        print('❌ Erreur lors du seek: $e');
        // Réessayer
        _attemptSeek(startSeconds, attempt + 1);
      }
    } else {
      print('🔄 Tentative ${attempt + 1}: Durée non disponible, nouvelle tentative...');
      _attemptSeek(startSeconds, attempt + 1);
    }
  }

  @override
  void dispose() {
    // Arrêter le timer de progression
    _progressReportTimer?.cancel();

    // Signaler l'arrêt de lecture à Jellyfin
    _reportPlaybackStopped();

    // Restaurer l'orientation et l'UI système
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Libérer les ressources du player
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur de lecture',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage ?? 'Une erreur est survenue',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.jellyfinPurple,
          ),
        ),
      );
    }

    // Récupérer le playbackInfo depuis le provider
    final playbackInfo = ref.watch(videoPlayerProvider).playbackInfo;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Video(
          controller: controller,
          fit: _videoFit,
          controls: (state) => CustomVideoControls(
            state: state,
            onFitChanged: (newFit) {
              setState(() {
                _videoFit = newFit;
              });
            },
            currentFit: _videoFit,
            playbackInfo: playbackInfo,
          ),
        ),
      ),
    );
  }
}

