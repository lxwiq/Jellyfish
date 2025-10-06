import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../theme/app_colors.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../jellyfin/jellyfin_open_api.swagger.dart';
import '../../../providers/video_player_provider.dart';

/// Contrôles vidéo personnalisés avec le design de l'app
class CustomVideoControls extends ConsumerStatefulWidget {
  final VideoState state;
  final Function(BoxFit)? onFitChanged;
  final BoxFit currentFit;
  final PlaybackInfoResponse? playbackInfo;

  const CustomVideoControls({
    super.key,
    required this.state,
    this.onFitChanged,
    this.currentFit = BoxFit.contain,
    this.playbackInfo,
  });

  @override
  ConsumerState<CustomVideoControls> createState() => _CustomVideoControlsState();
}

class _CustomVideoControlsState extends ConsumerState<CustomVideoControls> {
  bool _isVisible = true;
  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Zone cliquable pour afficher/masquer les contrôles (sauf sur le slider)
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isVisible = !_isVisible;
              });
            },
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),

        // Contrôles principaux
        AnimatedOpacity(
          opacity: _isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: _isVisible ? _buildControls() : const SizedBox.shrink(),
        ),

        // Menu des paramètres
        if (_showSettings)
          _buildSettingsMenu(),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.7),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Column(
        children: [
          // Barre supérieure
          _buildTopBar(),
          
          const Spacer(),
          
          // Bouton play/pause au centre
          _buildCenterControls(),
          
          const Spacer(),
          
          // Barre inférieure avec timeline et contrôles
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Bouton retour
            IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            
            const SizedBox(width: 8),
            
            // Titre (si disponible)
            Expanded(
              child: StreamBuilder<Duration>(
                stream: widget.state.widget.controller.player.stream.position,
                builder: (context, snapshot) {
                  return const Text(
                    '', // Le titre sera passé depuis l'écran parent
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ),
            
            // Bouton paramètres
            IconButton(
              icon: const Icon(
                IconsaxPlusLinear.setting_2,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () {
                setState(() {
                  _showSettings = !_showSettings;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    return StreamBuilder<bool>(
      stream: widget.state.widget.controller.player.stream.playing,
      builder: (context, playing) {
        final isPlaying = playing.data ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Reculer de 10 secondes
            _buildControlButton(
              icon: IconsaxPlusLinear.backward_10_seconds,
              onPressed: () {
                final player = widget.state.widget.controller.player;
                final currentPosition = player.state.position;
                player.seek(currentPosition - const Duration(seconds: 10));
              },
            ),
            
            const SizedBox(width: 32),
            
            // Play/Pause
            _buildControlButton(
              icon: isPlaying ? IconsaxPlusBold.pause : IconsaxPlusBold.play,
              size: 64,
              onPressed: () {
                widget.state.widget.controller.player.playOrPause();
              },
            ),
            
            const SizedBox(width: 32),
            
            // Avancer de 10 secondes
            _buildControlButton(
              icon: IconsaxPlusLinear.forward_10_seconds,
              onPressed: () {
                final player = widget.state.widget.controller.player;
                final currentPosition = player.state.position;
                player.seek(currentPosition + const Duration(seconds: 10));
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 48,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.jellyfinPurple.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: size * 0.6),
        iconSize: size,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Timeline
            StreamBuilder<Duration>(
              stream: widget.state.widget.controller.player.stream.position,
              builder: (context, positionSnapshot) {
                return StreamBuilder<Duration>(
                  stream: widget.state.widget.controller.player.stream.duration,
                  builder: (context, durationSnapshot) {
                    final position = positionSnapshot.data ?? Duration.zero;
                    final duration = durationSnapshot.data ?? Duration.zero;
                    final value = duration.inMilliseconds > 0
                        ? position.inMilliseconds / duration.inMilliseconds
                        : 0.0;

                    return Column(
                      children: [
                        // Envelopper le slider pour qu'il capture les événements tactiles
                        GestureDetector(
                          onTap: () {}, // Empêche la propagation du tap au parent
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: AppColors.jellyfinPurple,
                              inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                              thumbColor: AppColors.jellyfinPurple,
                              overlayColor: AppColors.jellyfinPurple.withValues(alpha: 0.3),
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                              ),
                            ),
                            child: Slider(
                              value: value.clamp(0.0, 1.0),
                              onChanged: (newValue) {
                                final newPosition = Duration(
                                  milliseconds: (newValue * duration.inMilliseconds).round(),
                                );
                                widget.state.widget.controller.player.seek(newPosition);
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsMenu() {
    print('🎛️ _buildSettingsMenu appelé');
    print('   playbackInfo disponible: ${widget.playbackInfo != null}');
    if (widget.playbackInfo != null) {
      final mediaSources = widget.playbackInfo!.mediaSources;
      if (mediaSources != null && mediaSources.isNotEmpty) {
        final streams = mediaSources.first.mediaStreams;
        print('   Nombre de streams: ${streams?.length ?? 0}');
        if (streams != null) {
          print('   📋 Détails des streams Jellyfin:');
          for (var stream in streams) {
            print('      - Type: ${stream.type}, Index: ${stream.index}, Language: ${stream.language}, Title: ${stream.title}, DisplayTitle: ${stream.displayTitle}');
          }
        }
      }
    }

    return Positioned(
      right: 16,
      top: 80,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 280,
          decoration: BoxDecoration(
            color: AppColors.background2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.jellyfinPurple.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Builder(
            builder: (context) {
              // Utiliser les métadonnées Jellyfin directement au lieu d'attendre media_kit
              String audioLabel = 'Aucune';
              String subtitleLabel = 'Désactivés';

              if (widget.playbackInfo != null) {
                final mediaSources = widget.playbackInfo!.mediaSources;
                if (mediaSources != null && mediaSources.isNotEmpty) {
                  final streams = mediaSources.first.mediaStreams;
                  if (streams != null) {
                    // Trouver la piste audio par défaut
                    final defaultAudio = streams.firstWhere(
                      (s) => s.type == MediaStreamType.audio && (s.isDefault == true),
                      orElse: () => streams.firstWhere(
                        (s) => s.type == MediaStreamType.audio,
                        orElse: () => MediaStream(),
                      ),
                    );
                    if (defaultAudio.type == MediaStreamType.audio) {
                      audioLabel = defaultAudio.displayTitle ?? defaultAudio.title ?? defaultAudio.language ?? 'Piste audio';
                    }

                    // Trouver la piste de sous-titres par défaut
                    final defaultSubtitle = streams.firstWhere(
                      (s) => s.type == MediaStreamType.subtitle && (s.isDefault == true),
                      orElse: () => MediaStream(),
                    );
                    if (defaultSubtitle.type == MediaStreamType.subtitle) {
                      subtitleLabel = defaultSubtitle.displayTitle ?? defaultSubtitle.title ?? defaultSubtitle.language ?? 'Sous-titres';
                    }
                  }
                }
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSettingsHeader(),
                  _buildSettingsOption(
                    icon: IconsaxPlusLinear.video,
                    title: 'Qualité',
                    subtitle: 'Auto',
                    onTap: () => _showQualityOptions(),
                  ),
                  _buildSettingsOption(
                    icon: IconsaxPlusLinear.volume_high,
                    title: 'Langue audio',
                    subtitle: audioLabel,
                    onTap: () => _showAudioOptions(),
                  ),
                  _buildSettingsOption(
                    icon: IconsaxPlusLinear.subtitle,
                    title: 'Sous-titres',
                    subtitle: subtitleLabel,
                    onTap: () => _showSubtitleOptions(),
                  ),
                  _buildSettingsOption(
                    icon: IconsaxPlusLinear.maximize_4,
                    title: 'Mode d\'affichage',
                    subtitle: _getFitLabel(widget.currentFit),
                    onTap: () => _showFitOptions(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.surface1.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            IconsaxPlusLinear.setting_2,
            color: AppColors.jellyfinPurple,
            size: 20,
          ),
          const SizedBox(width: 12),
          const Text(
            'Paramètres',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _showSettings = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.surface1.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.text3,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.text2,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.text2,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showQualityOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildQualitySheet(),
    );
  }

  void _showAudioOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildAudioSheet(),
    );
  }

  void _showSubtitleOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildSubtitleSheet(),
    );
  }

  Widget _buildQualitySheet() {
    final qualities = [
      {'label': 'Auto', 'bitrate': null},
      {'label': '4K (40 Mbps)', 'bitrate': 40000000},
      {'label': '1080p (20 Mbps)', 'bitrate': 20000000},
      {'label': '1080p (10 Mbps)', 'bitrate': 10000000},
      {'label': '720p (8 Mbps)', 'bitrate': 8000000},
      {'label': '720p (4 Mbps)', 'bitrate': 4000000},
      {'label': '480p (3 Mbps)', 'bitrate': 3000000},
      {'label': '480p (1.5 Mbps)', 'bitrate': 1500000},
    ];

    return _buildOptionSheet(
      title: 'Qualité vidéo',
      icon: IconsaxPlusLinear.video,
      options: qualities,
      currentValue: null,
      onSelect: (quality) {
        // TODO: Implémenter le changement de qualité
        Navigator.pop(context);
        setState(() {
          _showSettings = false;
        });
      },
    );
  }

  Widget _buildAudioSheet() {
    // Utiliser les métadonnées Jellyfin directement
    if (widget.playbackInfo == null) {
      return _buildEmptySheet('Aucune information de playback disponible');
    }

    final mediaSources = widget.playbackInfo!.mediaSources;
    if (mediaSources == null || mediaSources.isEmpty) {
      return _buildEmptySheet('Aucune source média disponible');
    }

    final streams = mediaSources.first.mediaStreams;
    if (streams == null) {
      return _buildEmptySheet('Aucun stream disponible');
    }

    final audioStreams = streams.where((s) => s.type == MediaStreamType.audio).toList();

    if (audioStreams.isEmpty) {
      return _buildEmptySheet('Aucune piste audio disponible');
    }

    // Trouver la piste audio par défaut
    final defaultAudio = audioStreams.firstWhere(
      (s) => s.isDefault == true,
      orElse: () => audioStreams.first,
    );

    return _buildOptionSheet(
      title: 'Langue audio',
      icon: IconsaxPlusLinear.volume_high,
      options: audioStreams.map((stream) => {
        'label': stream.displayTitle ?? stream.title ?? stream.language ?? 'Piste ${stream.index}',
        'value': stream,
      }).toList(),
      currentValue: defaultAudio,
      onSelect: (stream) {
        _changeAudioTrack(stream['value'] as MediaStream);
        Navigator.pop(context);
        setState(() {
          _showSettings = false;
        });
      },
    );
  }

  Widget _buildSubtitleSheet() {
    // Utiliser les métadonnées Jellyfin pour les sous-titres
    if (widget.playbackInfo == null) {
      return _buildEmptySheet('Aucune information de playback disponible');
    }

    final mediaSources = widget.playbackInfo!.mediaSources;
    if (mediaSources == null || mediaSources.isEmpty) {
      return _buildEmptySheet('Aucune source média disponible');
    }

    final streams = mediaSources.first.mediaStreams;
    if (streams == null) {
      return _buildEmptySheet('Aucun stream disponible');
    }

    final subtitleStreams = streams.where((s) => s.type == MediaStreamType.subtitle).toList();

    // Créer la liste des options avec "Désactivés" en premier
    final subtitleOptions = [
      {'label': 'Désactivés', 'value': null, 'jellyfinStream': null},
      ...subtitleStreams.map((stream) => {
        'label': stream.displayTitle ?? stream.title ?? stream.language ?? 'Sous-titre ${stream.index}',
        'value': null, // Sera défini lors de la sélection
        'jellyfinStream': stream,
      }),
    ];

    return _buildOptionSheet(
      title: 'Sous-titres',
      icon: IconsaxPlusLinear.subtitle,
      options: subtitleOptions,
      currentValue: widget.state.widget.controller.player.state.track.subtitle,
      onSelect: (option) {
        _changeSubtitleTrack(option['jellyfinStream'] as MediaStream?);
        Navigator.pop(context);
        setState(() {
          _showSettings = false;
        });
      },
    );
  }

  Widget _buildOptionSheet({
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> options,
    required dynamic currentValue,
    required Function(Map<String, dynamic>) onSelect,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.jellyfinPurple,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.surface1, height: 1),

          // Options
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = option['value'] == currentValue;

                return InkWell(
                  onTap: () => onSelect(option),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.jellyfinPurple.withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option['label'] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.jellyfinPurple
                                  : Colors.white,
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check,
                            color: AppColors.jellyfinPurple,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySheet(String message) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: AppColors.text2,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String _getAudioTrackLabel(AudioTrack? track) {
    if (track == null || track == AudioTrack.no()) {
      return 'Aucune';
    }

    print('🎵 _getAudioTrackLabel appelé - track.id: ${track.id}, track.title: ${track.title}, track.language: ${track.language}');
    print('   playbackInfo disponible: ${widget.playbackInfo != null}');

    // Essayer de trouver les métadonnées Jellyfin pour cette piste
    final jellyfinMetadata = _getJellyfinAudioMetadata(track.id);
    if (jellyfinMetadata != null) {
      final language = jellyfinMetadata.language;
      final title = jellyfinMetadata.title;
      final displayTitle = jellyfinMetadata.displayTitle;

      if (displayTitle != null && displayTitle.isNotEmpty) {
        return displayTitle;
      } else if (title != null && title.isNotEmpty) {
        return title;
      } else if (language != null && language.isNotEmpty) {
        return language;
      }
    }

    // Fallback sur les métadonnées de media_kit
    print('   ⚠️ Utilisation du fallback media_kit');
    return track.title ?? track.language ?? 'Piste ${track.id}';
  }

  String _getSubtitleTrackLabel(SubtitleTrack? track) {
    if (track == null || track == SubtitleTrack.no()) {
      return 'Désactivés';
    }

    // Essayer de trouver les métadonnées Jellyfin pour cette piste
    final jellyfinMetadata = _getJellyfinSubtitleMetadata(track.id);
    if (jellyfinMetadata != null) {
      final language = jellyfinMetadata.language;
      final title = jellyfinMetadata.title;
      final displayTitle = jellyfinMetadata.displayTitle;

      if (displayTitle != null && displayTitle.isNotEmpty) {
        return displayTitle;
      } else if (title != null && title.isNotEmpty) {
        return title;
      } else if (language != null && language.isNotEmpty) {
        return language;
      }
    }

    // Fallback sur les métadonnées de media_kit
    return track.title ?? track.language ?? 'Sous-titre ${track.id}';
  }

  /// Change la piste audio en utilisant setAudioTrack de media_kit (sans recharger)
  Future<void> _changeAudioTrack(MediaStream audioStream) async {
    try {
      print('🎵 Changement de piste audio vers index: ${audioStream.index}');

      // Récupérer les pistes audio disponibles depuis media_kit
      final tracks = widget.state.widget.controller.player.state.tracks;
      final audioTracks = tracks.audio;

      print('   📋 Pistes audio disponibles dans media_kit: ${audioTracks.length}');
      for (var track in audioTracks) {
        print('      - ID: ${track.id}, Title: ${track.title}, Language: ${track.language}');
      }

      // Trouver la piste correspondante dans media_kit
      AudioTrack? targetTrack;

      // Méthode 1: Essayer de trouver par index Jellyfin
      try {
        final targetIndex = audioStream.index;
        if (targetIndex != null) {
          // Essayer d'abord la correspondance directe (Jellyfin index = media_kit ID)
          targetTrack = audioTracks.firstWhere(
            (track) => track.id == targetIndex.toString(),
            orElse: () => throw Exception('Not found by direct index'),
          );
          print('   ✅ Piste trouvée par correspondance directe: ${targetTrack.id} (Jellyfin: $targetIndex)');
        }
      } catch (e) {
        print('   ⚠️ Correspondance directe échouée: $e');
        // Si la correspondance directe échoue, essayer index - 1
        try {
          final targetIndex = audioStream.index;
          if (targetIndex != null && targetIndex > 0) {
            targetTrack = audioTracks.firstWhere(
              (track) => track.id == (targetIndex - 1).toString(),
              orElse: () => throw Exception('Not found by index-1'),
            );
            print('   ✅ Piste trouvée par index-1: ${targetTrack.id} (Jellyfin: $targetIndex)');
          }
        } catch (e2) {
          print('   ⚠️ Correspondance index-1 échouée: $e2');
        }
      }

      // Méthode 2: Si pas trouvé par index, essayer par langue
      if (targetTrack == null) {
        final targetLanguage = audioStream.language;
        if (targetLanguage != null && targetLanguage.isNotEmpty) {
          try {
            targetTrack = audioTracks.firstWhere(
              (track) => track.language?.toLowerCase() == targetLanguage.toLowerCase(),
              orElse: () => throw Exception('Not found by language'),
            );
            print('   ✅ Piste trouvée par langue: ${targetTrack.id} (${targetLanguage})');
          } catch (e2) {
            print('   ⚠️ Piste non trouvée par langue: $targetLanguage');
          }
        }
      }

      // Méthode 3: Si toujours pas trouvé, utiliser l'ordre des pistes
      if (targetTrack == null && audioTracks.isNotEmpty) {
        final targetIndex = audioStream.index;
        if (targetIndex != null) {
          // Calculer l'index relatif (en supposant que l'index 1 de Jellyfin = index 0 de media_kit)
          final relativeIndex = (targetIndex - 1).clamp(0, audioTracks.length - 1);
          if (relativeIndex < audioTracks.length) {
            targetTrack = audioTracks[relativeIndex];
            print('   ⚠️ Utilisation de l\'index relatif: ${targetTrack.id} (position $relativeIndex)');
          }
        }
      }

      if (targetTrack != null) {
        // Changer la piste audio sans recharger la vidéo
        await widget.state.widget.controller.player.setAudioTrack(targetTrack);
        print('✅ Changement de piste audio terminé vers: ${targetTrack.id}');
      } else {
        print('❌ Aucune piste audio trouvée - fallback vers rechargement');
        // Fallback: recharger la vidéo si setAudioTrack ne fonctionne pas
        await _changeAudioTrackFallback(audioStream);
      }

    } catch (e) {
      print('❌ Erreur lors du changement de piste audio: $e');
      // Fallback en cas d'erreur
      await _changeAudioTrackFallback(audioStream);
    }
  }

  /// Fallback: Change la piste audio en rechargeant la vidéo (méthode de secours)
  Future<void> _changeAudioTrackFallback(MediaStream audioStream) async {
    try {
      print('🔄 Fallback: rechargement de la vidéo pour changement audio');

      // Sauvegarder l'état actuel
      final currentPosition = widget.state.widget.controller.player.state.position;
      final isPlaying = widget.state.widget.controller.player.state.playing;

      print('   📍 Position actuelle: ${currentPosition.inSeconds}s');

      // Obtenir l'itemId depuis le playbackInfo
      final itemId = widget.playbackInfo?.mediaSources?.first.id;
      if (itemId == null) {
        print('❌ Impossible de récupérer l\'itemId');
        return;
      }

      // Générer une nouvelle URL avec l'audioStreamIndex
      final videoPlayerNotifier = ref.read(videoPlayerProvider.notifier);
      final newStreamUrl = videoPlayerNotifier.getStreamUrl(
        itemId,
        audioStreamIndex: audioStream.index,
        useHls: false,
      );

      if (newStreamUrl == null) {
        print('❌ Impossible de générer la nouvelle URL de streaming');
        return;
      }

      print('🔄 Nouvelle URL: $newStreamUrl');

      // Recharger la vidéo
      await widget.state.widget.controller.player.pause();
      await Future.delayed(const Duration(milliseconds: 100));

      await widget.state.widget.controller.player.open(
        Media(newStreamUrl),
        play: false,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      // Restaurer la position
      final seekPosition = Duration(
        milliseconds: (currentPosition.inMilliseconds - 1000).clamp(0, currentPosition.inMilliseconds)
      );
      await widget.state.widget.controller.player.seek(seekPosition);
      await Future.delayed(const Duration(milliseconds: 200));

      if (isPlaying) {
        await widget.state.widget.controller.player.play();
      }

      print('✅ Fallback terminé');

    } catch (e) {
      print('❌ Erreur lors du fallback: $e');
    }
  }

  /// Change la piste de sous-titres en utilisant setSubtitleTrack de media_kit
  Future<void> _changeSubtitleTrack(MediaStream? subtitleStream) async {
    try {
      if (subtitleStream == null) {
        // Désactiver les sous-titres
        print('💬 Désactivation des sous-titres');
        await widget.state.widget.controller.player.setSubtitleTrack(SubtitleTrack.no());
        print('✅ Sous-titres désactivés');
        return;
      }

      print('💬 Changement de sous-titre vers index: ${subtitleStream.index}');

      // Récupérer les pistes de sous-titres disponibles depuis media_kit
      final tracks = widget.state.widget.controller.player.state.tracks;
      final subtitleTracks = tracks.subtitle;

      print('   📋 Pistes de sous-titres disponibles dans media_kit: ${subtitleTracks.length}');
      for (var track in subtitleTracks) {
        print('      - ID: ${track.id}, Title: ${track.title}, Language: ${track.language}');
      }

      // Nouvelle approche: utiliser directement l'index dans la liste des pistes media_kit
      SubtitleTrack? targetTrack;

      // Essayer de trouver la piste par langue d'abord (plus fiable)
      final targetLanguage = subtitleStream.language;
      if (targetLanguage != null && targetLanguage.isNotEmpty) {
        try {
          targetTrack = subtitleTracks.firstWhere(
            (track) => track.language?.toLowerCase() == targetLanguage.toLowerCase(),
            orElse: () => throw Exception('Not found by language'),
          );
          print('   ✅ Piste trouvée par langue: ${targetTrack.id} (${targetLanguage})');
        } catch (e) {
          print('   ⚠️ Piste non trouvée par langue: $targetLanguage');
        }
      }

      // Si pas trouvé par langue, essayer par position dans la liste
      if (targetTrack == null && subtitleTracks.isNotEmpty) {
        // Compter les pistes de sous-titres Jellyfin avant celle-ci
        final mediaSources = widget.playbackInfo?.mediaSources;
        if (mediaSources != null && mediaSources.isNotEmpty) {
          final streams = mediaSources.first.mediaStreams;
          if (streams != null) {
            final allSubtitleStreams = streams.where((s) => s.type == MediaStreamType.subtitle).toList();
            final currentIndex = allSubtitleStreams.indexOf(subtitleStream);

            if (currentIndex >= 0 && currentIndex < subtitleTracks.length) {
              // Exclure les pistes "auto" et "no" qui sont généralement en début de liste
              final realTracks = subtitleTracks.where((track) =>
                track.id != 'auto' && track.id != 'no'
              ).toList();

              if (currentIndex < realTracks.length) {
                targetTrack = realTracks[currentIndex];
                print('   ✅ Piste trouvée par position: ${targetTrack.id} (position $currentIndex)');
              }
            }
          }
        }
      }

      // Fallback: utiliser la première piste réelle disponible
      if (targetTrack == null && subtitleTracks.isNotEmpty) {
        final realTracks = subtitleTracks.where((track) =>
          track.id != 'auto' && track.id != 'no'
        ).toList();

        if (realTracks.isNotEmpty) {
          targetTrack = realTracks.first;
          print('   ⚠️ Utilisation de la première piste réelle disponible: ${targetTrack.id}');
        }
      }

      if (targetTrack != null) {
        // Changer la piste de sous-titres
        await widget.state.widget.controller.player.setSubtitleTrack(targetTrack);
        print('✅ Changement de sous-titre terminé vers: ${targetTrack.id}');
      } else {
        print('❌ Aucune piste de sous-titres trouvée');
      }

    } catch (e) {
      print('❌ Erreur lors du changement de sous-titre: $e');
    }
  }

  /// Récupère les métadonnées Jellyfin pour une piste audio
  MediaStream? _getJellyfinAudioMetadata(String trackId) {
    if (widget.playbackInfo == null) {
      print('⚠️ Pas de playbackInfo disponible');
      return null;
    }

    final mediaSources = widget.playbackInfo!.mediaSources;
    if (mediaSources == null || mediaSources.isEmpty) {
      print('⚠️ Pas de mediaSources disponibles');
      return null;
    }

    final mediaStreams = mediaSources.first.mediaStreams;
    if (mediaStreams == null) {
      print('⚠️ Pas de mediaStreams disponibles');
      return null;
    }

    print('🔍 Recherche piste audio - trackId: $trackId');

    // Lister toutes les pistes audio disponibles
    final audioStreams = mediaStreams.where((s) => s.type == MediaStreamType.audio).toList();
    print('   📋 ${audioStreams.length} pistes audio Jellyfin:');
    for (var stream in audioStreams) {
      print('      - Index: ${stream.index}, Language: ${stream.language}, Title: ${stream.title}, DisplayTitle: ${stream.displayTitle}');
    }

    // Chercher la piste audio correspondante par index
    // L'ID de media_kit correspond généralement à l'index du stream dans le fichier
    try {
      final index = int.parse(trackId);
      final match = mediaStreams.firstWhere(
        (stream) => stream.type == MediaStreamType.audio && stream.index == index,
        orElse: () => throw Exception('Not found'),
      );
      print('   ✅ Correspondance trouvée: ${match.displayTitle ?? match.title ?? match.language}');
      return match;
    } catch (e) {
      print('   ⚠️ Pas de correspondance exacte, utilisation de la première piste audio');
      // Fallback: retourner la première piste audio si pas de correspondance exacte
      return audioStreams.isNotEmpty ? audioStreams.first : null;
    }
  }

  /// Récupère les métadonnées Jellyfin pour une piste de sous-titres
  MediaStream? _getJellyfinSubtitleMetadata(String trackId) {
    if (widget.playbackInfo == null) {
      print('⚠️ Pas de playbackInfo disponible');
      return null;
    }

    final mediaSources = widget.playbackInfo!.mediaSources;
    if (mediaSources == null || mediaSources.isEmpty) {
      print('⚠️ Pas de mediaSources disponibles');
      return null;
    }

    final mediaStreams = mediaSources.first.mediaStreams;
    if (mediaStreams == null) {
      print('⚠️ Pas de mediaStreams disponibles');
      return null;
    }

    print('🔍 Recherche sous-titre - trackId: $trackId');

    // Lister tous les sous-titres disponibles
    final subtitleStreams = mediaStreams.where((s) => s.type == MediaStreamType.subtitle).toList();
    print('   📋 ${subtitleStreams.length} sous-titres Jellyfin:');
    for (var stream in subtitleStreams) {
      print('      - Index: ${stream.index}, Language: ${stream.language}, Title: ${stream.title}, DisplayTitle: ${stream.displayTitle}');
    }

    // Chercher le sous-titre correspondant par index
    try {
      final index = int.parse(trackId);
      final match = mediaStreams.firstWhere(
        (stream) => stream.type == MediaStreamType.subtitle && stream.index == index,
        orElse: () => throw Exception('Not found'),
      );
      print('   ✅ Correspondance trouvée: ${match.displayTitle ?? match.title ?? match.language}');
      return match;
    } catch (e) {
      print('   ⚠️ Pas de correspondance exacte, utilisation du premier sous-titre');
      // Fallback: retourner le premier sous-titre si pas de correspondance exacte
      return subtitleStreams.isNotEmpty ? subtitleStreams.first : null;
    }
  }

  String _getFitLabel(BoxFit fit) {
    switch (fit) {
      case BoxFit.contain:
        return 'Ajuster';
      case BoxFit.cover:
        return 'Remplir';
      case BoxFit.fill:
        return 'Étirer';
      case BoxFit.fitWidth:
        return 'Largeur';
      case BoxFit.fitHeight:
        return 'Hauteur';
      default:
        return 'Ajuster';
    }
  }

  void _showFitOptions() {
    final fitOptions = [
      {'label': 'Ajuster (recommandé)', 'fit': BoxFit.contain},
      {'label': 'Remplir l\'écran', 'fit': BoxFit.cover},
      {'label': 'Étirer', 'fit': BoxFit.fill},
      {'label': 'Adapter à la largeur', 'fit': BoxFit.fitWidth},
      {'label': 'Adapter à la hauteur', 'fit': BoxFit.fitHeight},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildOptionSheet(
        title: 'Mode d\'affichage',
        icon: IconsaxPlusLinear.maximize_4,
        options: fitOptions,
        currentValue: widget.currentFit,
        onSelect: (option) {
          final newFit = option['fit'] as BoxFit;
          widget.onFitChanged?.call(newFit);
          Navigator.pop(context);
          setState(() {
            _showSettings = false;
          });
        },
      ),
    );
  }
}
