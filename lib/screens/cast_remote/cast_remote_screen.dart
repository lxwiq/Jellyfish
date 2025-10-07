import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../providers/cast_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/services_provider.dart';
import '../../services/custom_cache_manager.dart';

/// Écran de télécommande complet pour contrôler le Chromecast
/// 
/// Fonctionnalités :
/// - Contrôles de lecture (play, pause, stop, seek)
/// - Contrôle du volume avec slider
/// - Sélection des sous-titres
/// - Affichage des métadonnées et de la progression
/// - Reporting automatique vers Jellyfin
class CastRemoteScreen extends ConsumerStatefulWidget {
  const CastRemoteScreen({super.key});

  @override
  ConsumerState<CastRemoteScreen> createState() => _CastRemoteScreenState();
}

class _CastRemoteScreenState extends ConsumerState<CastRemoteScreen> {
  Timer? _progressReportTimer;
  Timer? _positionUpdateTimer;
  double _currentSliderPosition = 0.0;
  bool _isUserDraggingSlider = false;
  double _currentVolume = 0.5;
  bool _showVolumeControl = false;

  @override
  void initState() {
    super.initState();
    _startProgressReporting();
    _startPositionUpdates();
    _initializeVolume();
  }

  @override
  void dispose() {
    _progressReportTimer?.cancel();
    _positionUpdateTimer?.cancel();
    super.dispose();
  }

  void _initializeVolume() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final volume = ref.read(castVolumeProvider);
      if (volume != null) {
        setState(() {
          _currentVolume = volume;
        });
      }
    });
  }

  void _startProgressReporting() {
    _progressReportTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _reportPlaybackProgress();
    });
  }

  void _startPositionUpdates() {
    _positionUpdateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!_isUserDraggingSlider && mounted) {
        final position = ref.read(castPositionProvider);
        final duration = ref.read(castDurationProvider);
        if (position != null && duration != null && duration.inSeconds > 0) {
          setState(() {
            _currentSliderPosition = position.inSeconds.toDouble();
          });
        }
      }
    });
  }

  Future<void> _reportPlaybackProgress() async {
    if (_isUserDraggingSlider) return;

    final mediaState = ref.read(castMediaStateProvider);
    final itemId = mediaState.itemId;
    if (itemId == null) return;

    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId == null) return;

    final position = ref.read(castPositionProvider);
    if (position == null) return;

    final isPlaying = ref.read(isCastPlayingProvider);
    final jellyfinService = ref.read(jellyfinServiceProvider);

    final positionTicks = position.inMicroseconds * 10;

    try {
      await jellyfinService.reportPlaybackProgress(
        itemId: itemId,
        userId: userId,
        positionTicks: positionTicks,
        isPaused: !isPlaying,
      );
    } catch (e) {
      print('Erreur lors du reporting de progression: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(castSessionProvider);
    final mediaState = ref.watch(castMediaStateProvider);
    final isPlaying = ref.watch(isCastPlayingProvider);
    final isBuffering = ref.watch(castIsBufferingProvider);
    final position = ref.watch(castPositionProvider);
    final duration = ref.watch(castDurationProvider);
    final deviceName = ref.watch(castDeviceNameProvider);

    return sessionAsync.when(
      data: (session) {
        if (session == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background1,
          appBar: AppBar(
            backgroundColor: AppColors.background2,
            foregroundColor: AppColors.text6,
            title: Row(
              children: [
                Icon(
                  IconsaxPlusBold.screenmirroring,
                  color: AppColors.jellyfinPurple,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lecture sur',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.text4,
                        ),
                      ),
                      Text(
                        deviceName ?? 'Chromecast',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Bouton sous-titres
              IconButton(
                icon: const Icon(IconsaxPlusLinear.subtitle),
                tooltip: 'Sous-titres',
                onPressed: () => _showSubtitlesDialog(context),
              ),
              // Bouton volume
              IconButton(
                icon: Icon(
                  _currentVolume == 0 
                    ? IconsaxPlusLinear.volume_slash 
                    : IconsaxPlusLinear.volume_high,
                ),
                tooltip: 'Volume',
                onPressed: () {
                  setState(() {
                    _showVolumeControl = !_showVolumeControl;
                  });
                },
              ),
              // Bouton déconnexion
              IconButton(
                icon: const Icon(IconsaxPlusLinear.logout),
                tooltip: 'Déconnecter',
                onPressed: () async {
                  final castService = ref.read(castServiceProvider);
                  await castService.disconnect();
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 32),
                    
                    // Image du média
                    _buildMediaImage(mediaState.imageUrl),
                    
                    const SizedBox(height: 32),
                    
                    // Titre et sous-titre
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Text(
                            mediaState.title ?? 'Titre inconnu',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.text6,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (mediaState.subtitle != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              mediaState.subtitle!,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.text5,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Indicateur de buffering
                    if (isBuffering)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.jellyfinPurple,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Chargement...',
                              style: TextStyle(
                                color: AppColors.text5,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Timeline
                    _buildTimeline(position, duration),
                    
                    const SizedBox(height: 32),
                    
                    // Contrôles de lecture
                    _buildPlaybackControls(isPlaying),
                    
                    const SizedBox(height: 48),
                  ],
                ),
                
                // Contrôle de volume flottant
                if (_showVolumeControl)
                  _buildVolumeControl(),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.jellyfinPurple),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: AppColors.background1,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                IconsaxPlusLinear.danger,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur de connexion',
                style: TextStyle(
                  color: AppColors.text6,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaImage(String? imageUrl) {
    return Container(
      width: 300,
      height: 450,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                cacheManager: CustomCacheManager(),
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.background3,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.jellyfinPurple,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.background3,
                  child: Icon(
                    IconsaxPlusLinear.video,
                    size: 64,
                    color: AppColors.text4,
                  ),
                ),
              )
            : Container(
                color: AppColors.background3,
                child: Icon(
                  IconsaxPlusLinear.video,
                  size: 64,
                  color: AppColors.text4,
                ),
              ),
      ),
    );
  }

  Widget _buildTimeline(Duration? position, Duration? duration) {
    final durationSeconds = duration?.inSeconds ?? 1;
    final progress = durationSeconds > 0 ? _currentSliderPosition / durationSeconds : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.jellyfinPurple,
              inactiveTrackColor: AppColors.text3.withValues(alpha: 0.3),
              thumbColor: AppColors.jellyfinPurple,
              overlayColor: AppColors.jellyfinPurple.withValues(alpha: 0.3),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChangeStart: (_) {
                setState(() => _isUserDraggingSlider = true);
              },
              onChanged: (value) {
                setState(() {
                  _currentSliderPosition = value * durationSeconds;
                });
              },
              onChangeEnd: (value) async {
                final newPosition = Duration(seconds: (value * durationSeconds).round());
                final castService = ref.read(castServiceProvider);
                await castService.seek(newPosition);
                setState(() => _isUserDraggingSlider = false);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(Duration(seconds: _currentSliderPosition.round())),
                style: TextStyle(color: AppColors.text5, fontSize: 14),
              ),
              Text(
                _formatDuration(duration ?? Duration.zero),
                style: TextStyle(color: AppColors.text5, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls(bool isPlaying) {
    final castService = ref.read(castServiceProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reculer de 10 secondes
        _buildControlButton(
          icon: IconsaxPlusLinear.backward_10_seconds,
          onPressed: () async {
            final position = ref.read(castPositionProvider);
            if (position != null) {
              final newPosition = position - const Duration(seconds: 10);
              await castService.seek(newPosition);
            }
          },
        ),

        const SizedBox(width: 32),

        // Play/Pause
        _buildControlButton(
          icon: isPlaying ? IconsaxPlusBold.pause : IconsaxPlusBold.play,
          size: 80,
          onPressed: () async {
            await castService.togglePlayPause();
          },
        ),

        const SizedBox(width: 32),

        // Avancer de 10 secondes
        _buildControlButton(
          icon: IconsaxPlusLinear.forward_10_seconds,
          onPressed: () async {
            final position = ref.read(castPositionProvider);
            if (position != null) {
              final newPosition = position + const Duration(seconds: 10);
              await castService.seek(newPosition);
            }
          },
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 64,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.jellyfinPurple.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: size * 0.5),
        iconSize: size,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildVolumeControl() {
    final castService = ref.read(castServiceProvider);

    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        width: 60,
        height: 300,
        decoration: BoxDecoration(
          color: AppColors.background2,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                IconsaxPlusLinear.volume_high,
                color: AppColors.text6,
              ),
              onPressed: () async {
                final newVolume = (_currentVolume + 0.1).clamp(0.0, 1.0);
                setState(() => _currentVolume = newVolume);
                await castService.setVolume(newVolume);
              },
            ),
            Expanded(
              child: RotatedBox(
                quarterTurns: -1,
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.jellyfinPurple,
                    inactiveTrackColor: AppColors.text3.withValues(alpha: 0.3),
                    thumbColor: AppColors.jellyfinPurple,
                    overlayColor: AppColors.jellyfinPurple.withValues(alpha: 0.3),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: _currentVolume,
                    onChanged: (value) {
                      setState(() => _currentVolume = value);
                    },
                    onChangeEnd: (value) async {
                      await castService.setVolume(value);
                    },
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                IconsaxPlusLinear.volume_slash,
                color: AppColors.text6,
              ),
              onPressed: () async {
                final newVolume = (_currentVolume - 0.1).clamp(0.0, 1.0);
                setState(() => _currentVolume = newVolume);
                await castService.setVolume(newVolume);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSubtitlesDialog(BuildContext context) {
    final tracks = ref.read(castAvailableTracksProvider);
    final activeTrackIds = ref.read(castActiveTrackIdsProvider);
    final castService = ref.read(castServiceProvider);

    if (tracks == null || tracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Aucun sous-titre disponible'),
          backgroundColor: AppColors.background3,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background2,
        title: Row(
          children: [
            Icon(
              IconsaxPlusBold.subtitle,
              color: AppColors.jellyfinPurple,
            ),
            const SizedBox(width: 12),
            Text(
              'Sous-titres',
              style: TextStyle(color: AppColors.text6),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              // Option pour désactiver les sous-titres
              ListTile(
                leading: Icon(
                  IconsaxPlusLinear.close_circle,
                  color: AppColors.text5,
                ),
                title: Text(
                  'Désactivé',
                  style: TextStyle(color: AppColors.text6),
                ),
                trailing: (activeTrackIds == null || activeTrackIds.isEmpty)
                    ? Icon(
                        IconsaxPlusBold.tick_circle,
                        color: AppColors.jellyfinPurple,
                      )
                    : null,
                onTap: () async {
                  await castService.setActiveTrack(null);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
              const Divider(),
              // Liste des pistes de sous-titres
              ...tracks.map((track) {
                final isActive = activeTrackIds?.contains(track.trackId) ?? false;
                return ListTile(
                  leading: Icon(
                    IconsaxPlusLinear.subtitle,
                    color: isActive ? AppColors.jellyfinPurple : AppColors.text5,
                  ),
                  title: Text(
                    track.name ?? 'Piste ${track.trackId}',
                    style: TextStyle(
                      color: AppColors.text6,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: track.language != null
                      ? Text(
                          track.language.toString(),
                          style: TextStyle(color: AppColors.text4),
                        )
                      : null,
                  trailing: isActive
                      ? Icon(
                          IconsaxPlusBold.tick_circle,
                          color: AppColors.jellyfinPurple,
                        )
                      : null,
                  onTap: () async {
                    await castService.setActiveTrack(track.trackId);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fermer',
              style: TextStyle(color: AppColors.text5),
            ),
          ),
        ],
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
}

