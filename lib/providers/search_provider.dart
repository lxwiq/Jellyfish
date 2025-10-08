import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jellyfish/jellyfin/jellyfin_open_api.swagger.dart';
import 'package:jellyfish/models/search_filters.dart';
import 'package:jellyfish/providers/auth_provider.dart';
import 'package:jellyfish/providers/services_provider.dart';
import 'package:jellyfish/services/logger_service.dart';

/// Provider pour l'état des filtres de recherche
final searchFiltersProvider = StateProvider<SearchFilters>((ref) {
  return const SearchFilters();
});

/// Provider pour les résultats de recherche
final searchResultsProvider = FutureProvider.autoDispose<BaseItemDtoQueryResult>((ref) async {
  final filters = ref.watch(searchFiltersProvider);
  final jellyfinService = ref.watch(jellyfinServiceProvider);
  final auth = ref.watch(authStateProvider);

  // Si pas de terme de recherche et pas de filtres, retourner vide
  if (!filters.hasActiveFilters) {
    return BaseItemDtoQueryResult(items: [], totalRecordCount: 0);
  }

  final userId = auth.user?.id;
  if (userId == null) {
    throw Exception('Utilisateur non connecté');
  }

  try {
    await LoggerService.instance.info('Recherche avec filtres: ${filters.searchTerm}');

    // Utiliser la méthode searchItems du service
    final result = await jellyfinService.searchItems(
      userId,
      searchTerm: filters.searchTerm,
      includeItemTypes: filters.itemTypes,
      genres: filters.genres,
      studios: filters.studios,
      tags: filters.tags,
      years: filters.years,
      minRating: filters.minRating,
      isFavorite: filters.isFavorite,
      isUnplayed: filters.isUnplayed,
      sortBy: filters.sortBy != null ? [filters.sortBy!] : null,
      sortOrder: filters.sortOrder != null ? [filters.sortOrder!] : null,
      limit: 100,
    );

    await LoggerService.instance.info('Résultats trouvés: ${result.totalRecordCount}');
    return result;
  } catch (e) {
    await LoggerService.instance.error('Erreur lors de la recherche', error: e);
    rethrow;
  }
});

/// Provider pour récupérer tous les genres disponibles
final availableGenresProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final jellyfinService = ref.watch(jellyfinServiceProvider);
  final auth = ref.watch(authStateProvider);

  final userId = auth.user?.id;
  if (userId == null) {
    return [];
  }

  try {
    final genres = await jellyfinService.getGenres(userId);
    final genreNames = genres
        .map((item) => item.name ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    genreNames.sort();
    return genreNames;
  } catch (e) {
    await LoggerService.instance.error('Erreur lors de la récupération des genres', error: e);
    return [];
  }
});

/// Provider pour récupérer tous les studios disponibles
final availableStudiosProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final jellyfinService = ref.watch(jellyfinServiceProvider);
  final auth = ref.watch(authStateProvider);

  final userId = auth.user?.id;
  if (userId == null) {
    return [];
  }

  try {
    final studios = await jellyfinService.getStudios(userId);
    final studioNames = studios
        .map((item) => item.name ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    studioNames.sort();
    return studioNames;
  } catch (e) {
    await LoggerService.instance.error('Erreur lors de la récupération des studios', error: e);
    return [];
  }
});

/// Provider pour récupérer tous les tags disponibles
final availableTagsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final jellyfinService = ref.watch(jellyfinServiceProvider);
  final auth = ref.watch(authStateProvider);

  final userId = auth.user?.id;
  if (userId == null) {
    return [];
  }

  try {
    final tags = await jellyfinService.getTags(userId);
    final tagNames = tags.toList();
    tagNames.sort();
    return tagNames;
  } catch (e) {
    await LoggerService.instance.error('Erreur lors de la récupération des tags', error: e);
    return [];
  }
});

/// Provider pour récupérer les années disponibles
final availableYearsProvider = FutureProvider.autoDispose<List<int>>((ref) async {
  final jellyfinService = ref.watch(jellyfinServiceProvider);
  final auth = ref.watch(authStateProvider);

  final userId = auth.user?.id;
  if (userId == null) {
    return [];
  }

  try {
    final years = await jellyfinService.getYears(userId);
    years.sort((a, b) => b.compareTo(a)); // Tri décroissant
    return years;
  } catch (e) {
    await LoggerService.instance.error('Erreur lors de la récupération des années', error: e);
    return [];
  }
});

