import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jellyfish/theme/app_colors.dart';
import 'package:jellyfish/models/jellyseerr_models.dart';
import 'package:jellyfish/providers/jellyseerr_provider.dart';
import 'package:jellyfish/providers/services_provider.dart';
import 'widgets/media_detail_header.dart';
import 'widgets/media_info_section.dart';
import 'widgets/media_overview_section.dart';
import 'widgets/media_cast_section.dart';
import 'widgets/media_request_button.dart';

/// Écran de détails d'un média redesigné (film ou série TV)
/// Utilise des widgets modulaires et réutilisables
class JellyseerrMediaDetailScreen extends ConsumerStatefulWidget {
  final int mediaId;
  final String mediaType; // 'movie' ou 'tv'

  const JellyseerrMediaDetailScreen({
    super.key,
    required this.mediaId,
    required this.mediaType,
  });

  @override
  ConsumerState<JellyseerrMediaDetailScreen> createState() =>
      _JellyseerrMediaDetailScreenState();
}

class _JellyseerrMediaDetailScreenState
    extends ConsumerState<JellyseerrMediaDetailScreen> {
  bool _isRequesting = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    // Récupérer les détails selon le type de média
    final detailsAsync = widget.mediaType == 'movie'
        ? ref.watch(jellyseerrMovieDetailsProvider(widget.mediaId))
        : ref.watch(jellyseerrTvDetailsProvider(widget.mediaId));

    return Scaffold(
      backgroundColor: AppColors.background1,
      body: detailsAsync.when(
        data: (details) => _buildContent(details, isDesktop, isTablet),
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.jellyfinPurple,
          ),
        ),
        error: (error, stack) => _buildErrorState(error.toString(), isDesktop),
      ),
    );
  }

  Widget _buildContent(dynamic details, bool isDesktop, bool isTablet) {
    // Extraire les données du média
    final backdropUrl = _getBackdropUrl(details);
    final posterUrl = _getPosterUrl(details);
    final title = _getTitle(details);
    final overview = _getOverview(details);
    final voteAverage = _getVoteAverage(details);
    final releaseDate = _getReleaseDate(details);
    final runtime = _getRuntime(details);
    final genres = _getGenres(details);
    final cast = _getCast(details);
    final mediaInfo = _getMediaInfo(details);

    return CustomScrollView(
      slivers: [
        // Header avec backdrop et poster
        MediaDetailHeader(
          backdropUrl: backdropUrl,
          posterUrl: posterUrl,
          title: title,
          voteAverage: voteAverage,
          isDesktop: isDesktop,
        ),

        // Contenu scrollable
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Informations (date, durée, genres)
              MediaInfoSection(
                releaseDate: releaseDate,
                runtime: runtime,
                genres: genres,
                isDesktop: isDesktop,
              ),

              // Bouton de demande
              MediaRequestButton(
                isRequesting: _isRequesting,
                isRequested: mediaInfo?.status != null &&
                    mediaInfo!.status != 'UNKNOWN',
                isAvailable: mediaInfo?.status == 'AVAILABLE',
                onRequest: () => _requestMedia(details),
                isDesktop: isDesktop,
              ),

              const SizedBox(height: 8),

              // Synopsis
              MediaOverviewSection(
                overview: overview,
                isDesktop: isDesktop,
              ),

              const SizedBox(height: 16),

              // Casting
              MediaCastSection(
                cast: cast,
                isDesktop: isDesktop,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error, bool isDesktop) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 32 : 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: isDesktop ? 20 : 18,
                color: AppColors.text5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isDesktop ? 14 : 13,
                color: AppColors.text3,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(widget.mediaType == 'movie'
                    ? jellyseerrMovieDetailsProvider
                    : jellyseerrTvDetailsProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.jellyfinPurple,
                foregroundColor: AppColors.text6,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestMedia(dynamic details) async {
    setState(() {
      _isRequesting = true;
    });

    try {
      final service = ref.read(jellyseerrServiceProvider);

      // Créer la requête
      final request = CreateRequestBody(
        mediaId: widget.mediaId,
        mediaType: widget.mediaType,
      );

      await service.createRequest(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demande envoyée pour ${_getTitle(details)}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Rafraîchir les détails
        ref.invalidate(widget.mediaType == 'movie'
            ? jellyseerrMovieDetailsProvider
            : jellyseerrTvDetailsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
      }
    }
  }

  // Méthodes d'extraction de données
  String? _getBackdropUrl(dynamic details) {
    if (details is MovieDetails && details.backdropPath != null) {
      return 'https://image.tmdb.org/t/p/original${details.backdropPath}';
    } else if (details is TvDetails && details.backdropPath != null) {
      return 'https://image.tmdb.org/t/p/original${details.backdropPath}';
    }
    return null;
  }

  String? _getPosterUrl(dynamic details) {
    if (details is MovieDetails && details.posterPath != null) {
      return 'https://image.tmdb.org/t/p/w500${details.posterPath}';
    } else if (details is TvDetails && details.posterPath != null) {
      return 'https://image.tmdb.org/t/p/w500${details.posterPath}';
    }
    return null;
  }

  String _getTitle(dynamic details) {
    if (details is MovieDetails) {
      return details.title ?? 'Sans titre';
    } else if (details is TvDetails) {
      return details.name ?? 'Sans titre';
    }
    return 'Sans titre';
  }

  String _getOverview(dynamic details) {
    if (details is MovieDetails) {
      return details.overview ?? '';
    } else if (details is TvDetails) {
      return details.overview ?? '';
    }
    return '';
  }

  double? _getVoteAverage(dynamic details) {
    if (details is MovieDetails) {
      return details.voteAverage;
    } else if (details is TvDetails) {
      return details.voteAverage;
    }
    return null;
  }

  String? _getReleaseDate(dynamic details) {
    if (details is MovieDetails && details.releaseDate != null) {
      return details.releaseDate;
    } else if (details is TvDetails && details.firstAirDate != null) {
      return details.firstAirDate;
    }
    return null;
  }

  int? _getRuntime(dynamic details) {
    if (details is MovieDetails) {
      return details.runtime;
    } else if (details is TvDetails &&
               details.episodeRunTime != null &&
               details.episodeRunTime!.isNotEmpty) {
      return details.episodeRunTime!.first;
    }
    return null;
  }

  List<String> _getGenres(dynamic details) {
    if (details is MovieDetails && details.genres != null) {
      return details.genres!.map((g) => g.name).toList();
    } else if (details is TvDetails && details.genres != null) {
      return details.genres!.map((g) => g.name).toList();
    }
    return [];
  }

  List<CastMember> _getCast(dynamic details) {
    // Extraire le casting depuis les crédits
    // Cette partie dépend de la structure de vos modèles
    return [];
  }

  MediaInfo? _getMediaInfo(dynamic details) {
    if (details is MovieDetails) {
      return details.mediaInfo;
    } else if (details is TvDetails) {
      return details.mediaInfo;
    }
    return null;
  }
}

