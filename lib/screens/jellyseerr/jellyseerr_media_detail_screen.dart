import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jellyfish/models/jellyseerr_models.dart';
import 'package:jellyfish/providers/jellyseerr_provider.dart';
import 'package:jellyfish/providers/services_provider.dart';
import 'package:jellyfish/widgets/card_constants.dart';

/// Écran de détails d'un média (film ou série TV)
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
    // Récupérer les détails selon le type de média
    final detailsAsync = widget.mediaType == 'movie'
        ? ref.watch(jellyseerrMovieDetailsProvider(widget.mediaId))
        : ref.watch(jellyseerrTvDetailsProvider(widget.mediaId));

    return Scaffold(
      body: detailsAsync.when(
        data: (details) => _buildContent(details),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(widget.mediaType == 'movie'
                      ? jellyseerrMovieDetailsProvider
                      : jellyseerrTvDetailsProvider);
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(dynamic details) {
    final backdropUrl = _getBackdropUrl(details);
    final posterUrl = _getPosterUrl(details);
    final title = _getTitle(details);
    final overview = _getOverview(details);
    final voteAverage = _getVoteAverage(details);
    final releaseDate = _getReleaseDate(details);
    final runtime = _getRuntime(details);
    final genres = _getGenres(details);
    final cast = _getCast(details);

    return CustomScrollView(
      slivers: [
        // AppBar avec backdrop
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Image de fond
                if (backdropUrl != null)
                  Image.network(
                    backdropUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: Colors.grey.shade900);
                    },
                  )
                else
                  Container(color: Colors.grey.shade900),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                // Poster et infos de base
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Poster
                      if (posterUrl != null)
                        Container(
                          width: 120,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              posterUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade700,
                                  child: const Icon(Icons.movie, size: 48),
                                );
                              },
                            ),
                          ),
                        ),
                      const SizedBox(width: 16),
                      // Titre et infos
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (voteAverage != null) ...[
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    voteAverage.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                if (releaseDate != null)
                                  Text(
                                    releaseDate,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                if (runtime != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '• $runtime min',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Contenu
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bouton de demande
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isRequesting ? null : () => _requestMedia(details),
                    icon: _isRequesting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: Text(_isRequesting ? 'Demande en cours...' : 'Demander'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Genres
                if (genres.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: genres.map((genre) {
                      return Chip(
                        label: Text(genre.name),
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
                // Synopsis
                if (overview.isNotEmpty) ...[
                  const Text(
                    'Synopsis',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    overview,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                ],
                // Cast
                if (cast.isNotEmpty) ...[
                  const Text(
                    'Casting',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: cast.length > 10 ? 10 : cast.length,
                      itemBuilder: (context, index) {
                        final member = cast[index];
                        return _buildCastCard(member);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                // Recommandations
                const Text(
                  'Recommandations',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRecommendations(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCastCard(CastMember member) {
    final profileUrl = member.profilePath != null
        ? 'https://image.tmdb.org/t/p/w185${member.profilePath}'
        : null;

    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade300,
            ),
            child: ClipOval(
              child: profileUrl != null
                  ? Image.network(
                      profileUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person, size: 48);
                      },
                    )
                  : const Icon(Icons.person, size: 48),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            member.name ?? 'Unknown',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (member.character != null)
            Text(
              member.character!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendationsAsync = widget.mediaType == 'movie'
        ? ref.watch(jellyseerrMovieRecommendationsProvider(
            (id: widget.mediaId, page: 1)))
        : ref.watch(
            jellyseerrTvRecommendationsProvider((id: widget.mediaId, page: 1)));

    return recommendationsAsync.when(
      data: (response) {
        if (response.results.isEmpty) {
          return const Text('Aucune recommandation disponible');
        }

        return SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: response.results.length > 10 ? 10 : response.results.length,
            itemBuilder: (context, index) {
              final media = response.results[index];
              return _buildRecommendationCard(media);
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Text('Erreur: $error'),
    );
  }

  Widget _buildRecommendationCard(MediaSearchResult media) {
    final posterUrl = media.posterPath != null
        ? 'https://image.tmdb.org/t/p/w500${media.posterPath}'
        : null;

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JellyseerrMediaDetailScreen(
                mediaId: media.id,
                mediaType: media.mediaType,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: CardConstants.posterAspectRatio,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: posterUrl != null
                      ? Image.network(
                          posterUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.movie, size: 48),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.movie, size: 48),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              media.displayTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (media.voteAverage != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, size: 12, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text(
                    media.voteAverage!.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
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

      // Créer la demande avec CreateRequestBody
      await service.createRequest(
        CreateRequestBody(
          mediaId: widget.mediaId,
          mediaType: widget.mediaType,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande créée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
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

  // Méthodes utilitaires pour extraire les données
  String? _getBackdropUrl(dynamic details) {
    if (details is MovieDetails) {
      return details.backdropPath != null
          ? 'https://image.tmdb.org/t/p/original${details.backdropPath}'
          : null;
    } else if (details is TvDetails) {
      return details.backdropPath != null
          ? 'https://image.tmdb.org/t/p/original${details.backdropPath}'
          : null;
    }
    return null;
  }

  String? _getPosterUrl(dynamic details) {
    if (details is MovieDetails) {
      return details.posterPath != null
          ? 'https://image.tmdb.org/t/p/w500${details.posterPath}'
          : null;
    } else if (details is TvDetails) {
      return details.posterPath != null
          ? 'https://image.tmdb.org/t/p/w500${details.posterPath}'
          : null;
    }
    return null;
  }

  String _getTitle(dynamic details) {
    if (details is MovieDetails) {
      return details.title ?? 'Unknown';
    } else if (details is TvDetails) {
      return details.name ?? 'Unknown';
    }
    return 'Unknown';
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
    if (details is MovieDetails) {
      return details.releaseDate?.split('-').first;
    } else if (details is TvDetails) {
      return details.firstAirDate?.split('-').first;
    }
    return null;
  }

  int? _getRuntime(dynamic details) {
    if (details is MovieDetails) {
      return details.runtime;
    } else if (details is TvDetails) {
      return details.episodeRunTime?.isNotEmpty == true
          ? details.episodeRunTime!.first
          : null;
    }
    return null;
  }

  List<Genre> _getGenres(dynamic details) {
    if (details is MovieDetails) {
      return details.genres ?? [];
    } else if (details is TvDetails) {
      return details.genres ?? [];
    }
    return [];
  }

  List<CastMember> _getCast(dynamic details) {
    if (details is MovieDetails) {
      return details.credits?.cast ?? [];
    } else if (details is TvDetails) {
      return details.credits?.cast ?? [];
    }
    return [];
  }
}

