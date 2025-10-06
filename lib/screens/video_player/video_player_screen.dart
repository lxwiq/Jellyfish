import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../theme/app_colors.dart';
import '../../providers/video_player_provider.dart';
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
      if (widget.startPositionTicks != null) {
        final startSeconds = widget.startPositionTicks! ~/ 10000000;
        await player.open(
          Media(streamUrl),
          play: true,
        );
        await player.seek(Duration(seconds: startSeconds));
      } else {
        await player.open(
          Media(streamUrl),
          play: true,
        );
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
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation du player: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Erreur lors de l\'initialisation: $e';
      });
    }
  }

  @override
  void dispose() {
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
          ),
        ),
      ),
    );
  }
}

