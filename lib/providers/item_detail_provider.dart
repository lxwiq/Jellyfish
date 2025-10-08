import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../jellyfin/jellyfin_open_api.swagger.dart';
import 'auth_provider.dart';
import 'services_provider.dart';

/// Provider pour les détails d'un item
final itemDetailProvider = FutureProvider.family<BaseItemDto?, String>((ref, itemId) async {
  final authState = ref.watch(authStateProvider);
  final jellyfinService = ref.watch(jellyfinServiceProvider);

  if (authState.user == null || !jellyfinService.isInitialized) {
    return null;
  }

  return await jellyfinService.getItemDetails(authState.user!.id, itemId);
});

/// Provider pour les items similaires
final similarItemsProvider = FutureProvider.family<List<BaseItemDto>, String>((ref, itemId) async {
  final authState = ref.watch(authStateProvider);
  final jellyfinService = ref.watch(jellyfinServiceProvider);

  if (authState.user == null || !jellyfinService.isInitialized) {
    return [];
  }

  return await jellyfinService.getSimilarItems(authState.user!.id, itemId, limit: 12);
});

/// Provider pour les saisons d'une série
final seasonsProvider = FutureProvider.family<List<BaseItemDto>, String>((ref, seriesId) async {
  final authState = ref.watch(authStateProvider);
  final jellyfinService = ref.watch(jellyfinServiceProvider);

  if (authState.user == null || !jellyfinService.isInitialized) {
    return [];
  }

  return await jellyfinService.getSeasons(seriesId, authState.user!.id);
});

/// State provider pour la saison sélectionnée (index dans la liste des saisons)
final selectedSeasonIndexProvider = StateProvider.family<int, String>((ref, seriesId) => 0);

/// Paramètres pour le provider d'épisodes
class EpisodeParams {
  final String seriesId;
  final String? seasonId;
  final int? seasonNumber;

  const EpisodeParams({
    required this.seriesId,
    this.seasonId,
    this.seasonNumber,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpisodeParams &&
          runtimeType == other.runtimeType &&
          seriesId == other.seriesId &&
          seasonId == other.seasonId &&
          seasonNumber == other.seasonNumber;

  @override
  int get hashCode => Object.hash(seriesId, seasonId, seasonNumber);
}

/// Provider pour les épisodes d'une saison
final episodesProvider = FutureProvider.family<List<BaseItemDto>, EpisodeParams>((ref, params) async {
  final authState = ref.watch(authStateProvider);
  final jellyfinService = ref.watch(jellyfinServiceProvider);

  if (authState.user == null || !jellyfinService.isInitialized) {
    return [];
  }

  return await jellyfinService.getEpisodes(
    params.seriesId,
    authState.user!.id,
    seasonId: params.seasonId,
    seasonNumber: params.seasonNumber,
  );
});

/// Provider pour obtenir le prochain épisode à regarder d'une série
final nextUpEpisodeForSeriesProvider = FutureProvider.family<BaseItemDto?, String>((ref, seriesId) async {
  final authState = ref.watch(authStateProvider);
  final jellyfinService = ref.watch(jellyfinServiceProvider);

  if (authState.user == null || !jellyfinService.isInitialized) {
    return null;
  }

  // Récupérer tous les prochains épisodes
  final nextUpEpisodes = await jellyfinService.getNextUpEpisodes(authState.user!.id, limit: 50);

  // Trouver le premier épisode de cette série
  try {
    return nextUpEpisodes.firstWhere((episode) => episode.seriesId == seriesId);
  } catch (e) {
    return null;
  }
});

/// Provider pour les détails d'une personne (acteur, réalisateur, etc.)
final personDetailProvider = FutureProvider.family<BaseItemDto?, String>((ref, personId) async {
  final authState = ref.watch(authStateProvider);
  final jellyfinService = ref.watch(jellyfinServiceProvider);

  if (authState.user == null || !jellyfinService.isInitialized) {
    return null;
  }

  return await jellyfinService.getPersonDetails(personId, authState.user!.id);
});

/// Provider pour les items dans lesquels une personne apparaît
final personItemsProvider = FutureProvider.family<List<BaseItemDto>, String>((ref, personId) async {
  final authState = ref.watch(authStateProvider);
  final jellyfinService = ref.watch(jellyfinServiceProvider);

  if (authState.user == null || !jellyfinService.isInitialized) {
    return [];
  }

  return await jellyfinService.getItemsByPerson(authState.user!.id, personId, limit: 50);
});
