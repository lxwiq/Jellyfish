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

/// Écran de télécommande pour contrôler le Chromecast
class CastRemoteScreen extends ConsumerStatefulWidget {
  const CastRemoteScreen({super.key});

  @override
  ConsumerState<CastRemoteScreen> createState() => _CastRemoteScreenState();
}

class _CastRemoteScreenState extends ConsumerState<CastRemoteScreen> {
  Timer? _progressReportTimer;
  bool _isSeeking = false;

  @override
  void initState() {
    super.initState();
    _startProgressReporting();
  }

  @override
  void dispose() {
    _progressReportTimer?.cancel();
    super.dispose();
  }

  void _startProgressReporting() {
    _progressReportTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _reportPlaybackProgress();
    });
  }

  Future<void> _reportPlaybackProgress() async {
    if (_isSeeking) return;

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

    await jellyfinService.reportPlaybackProgress(
      itemId: itemId,
      userId: userId,
      positionTicks: positionTicks,
      isPaused: !isPlaying,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(castSessionProvider);
    final mediaState = ref.watch(castMediaStateProvider);
    final isPlaying = ref.watch(isCastPlayingProvider);
    final position = ref.watch(castPositionProvider);
    final duration = ref.watch(castDurationProvider);

    return sessionAsync.when(
      data: (session) {
        if (session == null) {
          // Si plus de session, retourner à l'écran précédent
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
                        session.device?.friendlyName ?? 'Chromecast',
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
            child: Column(
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
                
                // Timeline
                _buildTimeline(position, duration),
                
                const SizedBox(height: 32),
                
                // Contrôles de lecture
                _buildPlaybackControls(isPlaying),
                
                const SizedBox(height: 48),
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
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(color: AppColors.text4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Retour'),
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
    final positionSeconds = position?.inSeconds ?? 0;
    final durationSeconds = duration?.inSeconds ?? 1;
    final progress = durationSeconds > 0 ? positionSeconds / durationSeconds : 0.0;

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
                setState(() => _isSeeking = true);
              },
              onChanged: (value) {
                // Mise à jour visuelle uniquement
              },
              onChangeEnd: (value) async {
                final newPosition = Duration(seconds: (value * durationSeconds).round());
                final castService = ref.read(castServiceProvider);
                await castService.seek(newPosition);
                setState(() => _isSeeking = false);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position ?? Duration.zero),
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
            if (isPlaying) {
              await castService.pause();
            } else {
              await castService.play();
            }
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

