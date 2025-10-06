import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../theme/app_colors.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Contrôles vidéo personnalisés avec le design de l'app
class CustomVideoControls extends StatefulWidget {
  final VideoState state;
  final Function(BoxFit)? onFitChanged;
  final BoxFit currentFit;

  const CustomVideoControls({
    super.key,
    required this.state,
    this.onFitChanged,
    this.currentFit = BoxFit.contain,
  });

  @override
  State<CustomVideoControls> createState() => _CustomVideoControlsState();
}

class _CustomVideoControlsState extends State<CustomVideoControls> {
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
          child: StreamBuilder<Track>(
            stream: widget.state.widget.controller.player.stream.track,
            builder: (context, trackSnapshot) {
              final currentTrack = trackSnapshot.data;
              final audioLabel = _getAudioTrackLabel(currentTrack?.audio);
              final subtitleLabel = _getSubtitleTrackLabel(currentTrack?.subtitle);

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
    return StreamBuilder<Tracks>(
      stream: widget.state.widget.controller.player.stream.tracks,
      builder: (context, snapshot) {
        final tracks = snapshot.data;
        final audioTracks = tracks?.audio ?? [];

        if (audioTracks.isEmpty) {
          return _buildEmptySheet('Aucune piste audio disponible');
        }

        return _buildOptionSheet(
          title: 'Langue audio',
          icon: IconsaxPlusLinear.volume_high,
          options: audioTracks.map((track) => {
            'label': track.title ?? track.language ?? 'Piste ${track.id}',
            'value': track,
          }).toList(),
          currentValue: widget.state.widget.controller.player.state.track.audio,
          onSelect: (track) {
            widget.state.widget.controller.player.setAudioTrack(track['value'] as AudioTrack);
            Navigator.pop(context);
            setState(() {
              _showSettings = false;
            });
          },
        );
      },
    );
  }

  Widget _buildSubtitleSheet() {
    return StreamBuilder<Tracks>(
      stream: widget.state.widget.controller.player.stream.tracks,
      builder: (context, snapshot) {
        final tracks = snapshot.data;
        final subtitleTracks = [
          {'label': 'Désactivés', 'value': SubtitleTrack.no()},
          ...?tracks?.subtitle.map((track) => {
            'label': track.title ?? track.language ?? 'Sous-titre ${track.id}',
            'value': track,
          }),
        ];

        return _buildOptionSheet(
          title: 'Sous-titres',
          icon: IconsaxPlusLinear.subtitle,
          options: subtitleTracks,
          currentValue: widget.state.widget.controller.player.state.track.subtitle,
          onSelect: (track) {
            widget.state.widget.controller.player.setSubtitleTrack(track['value'] as SubtitleTrack);
            Navigator.pop(context);
            setState(() {
              _showSettings = false;
            });
          },
        );
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
    return track.title ?? track.language ?? 'Piste ${track.id}';
  }

  String _getSubtitleTrackLabel(SubtitleTrack? track) {
    if (track == null || track == SubtitleTrack.no()) {
      return 'Désactivés';
    }
    return track.title ?? track.language ?? 'Sous-titre ${track.id}';
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
