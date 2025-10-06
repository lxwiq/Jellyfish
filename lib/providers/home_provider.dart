import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../jellyfin/jellyfin_open_api.swagger.dart';
import '../providers/auth_provider.dart';
import '../providers/services_provider.dart';

/// Provider pour les éléments en cours de lecture
final resumeItemsProvider = FutureProvider.autoDispose<List<BaseItemDto>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final jellyfinService = ref.watch(jellyfinServiceProvider);

  if (authState.user == null || !jellyfinService.isInitialized) {
    return [];
  }

  final items = await jellyfinService.getResumeItems(authState.user!.id, limit: 10);

  // Filtrer pour ne garder que les éléments avec une vraie progression
  final filteredItems = items.where((item) {
    if (item.id == null) return false;

    final userData = item.userData;
    if (userData == null) return false;

    final playbackPositionTicks = userData.playbackPositionTicks ?? 0;
    final runtimeTicks = item.runTimeTicks ?? 0;

    // Ne garder que les éléments avec une progression réelle (>0% et <95%)
    if (playbackPositionTicks == 0 || runtimeTicks == 0) return false;

    final progressPercentage = playbackPositionTicks / runtimeTicks;
    if (progressPercentage >= 0.95) return false; // Exclure les éléments presque terminés

    return true;
  }).toList();

  // Dédupliquer par ID
  final seen = <String>{};
  return filteredItems.where((item) {
    if (seen.contains(item.id)) return false;
    seen.add(item.id!);
    return true;
  }).toList();
});

/// Provider pour les prochains épisodes
final nextUpEpisodesProvider = FutureProvider.autoDispose<List<BaseItemDto>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final jellyfinService = ref.watch(jellyfinServiceProvider);

  if (authState.user == null || !jellyfinService.isInitialized) {
    return [];
  }

  final items = await jellyfinService.getNextUpEpisodes(authState.user!.id, limit: 10);
  // Dédupliquer par ID
  final seen = <String>{};
  return items.where((item) {
    if (item.id == null) return false;
    if (seen.contains(item.id)) return false;
    seen.add(item.id!);
    return true;
  }).toList();
});

/// Provider pour les derniers éléments ajoutés (tous)
final latestItemsProvider = FutureProvider.autoDispose<List<BaseItemDto>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final jellyfinService = ref.watch(jellyfinServiceProvider);

  if (authState.user == null || !jellyfinService.isInitialized) {
    return [];
  }

  final items = await jellyfinService.getLatestItems(authState.user!.id, limit: 16);
  // Dédupliquer par ID
  final seen = <String>{};
  return items.where((item) {
    if (item.id == null) return false;
    if (seen.contains(item.id)) return false;
    seen.add(item.id!);
    return true;
  }).toList();
});

/// Provider pour les items du hero carousel
/// Uniquement des films et séries (pas d'épisodes, saisons ou items en cours)
final heroItemsProvider = FutureProvider.autoDispose<List<BaseItemDto>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final jellyfinService = ref.watch(jellyfinServiceProvider);

  if (authState.user == null || !jellyfinService.isInitialized) {
    return [];
  }

  // Récupérer des items optimisés pour le hero (films et séries avec bonnes notes)
  final heroItems = await jellyfinService.getHeroItems(authState.user!.id, limit: 30);

  // Filtrer strictement pour ne garder que films et séries avec backdrop
  final filteredItems = heroItems.where((item) {
    if (item.id == null) return false;

    // Vérifier le type : uniquement Movie ou Series
    final itemType = item.type?.value?.toLowerCase();
    if (itemType != 'movie' && itemType != 'series') return false;

    // Doit avoir un backdrop
    final hasBackdrop = item.backdropImageTags != null && item.backdropImageTags!.isNotEmpty;

    return hasBackdrop;
  }).toList();

  // Mélanger pour la variété
  filteredItems.shuffle();

  // Retourner jusqu'à 10 items
  return filteredItems.take(10).toList();
});

/// Provider pour les derniers éléments ajoutés par bibliothèque
final latestItemsByLibraryProvider = FutureProvider.autoDispose.family<List<BaseItemDto>, String>((ref, libraryId) async {
  final authState = ref.watch(authStateProvider);
  final jellyfinService = ref.watch(jellyfinServiceProvider);

  if (authState.user == null || !jellyfinService.isInitialized) {
    return [];
  }

  return await jellyfinService.getLatestItems(
    authState.user!.id,
    parentId: libraryId,
    limit: 16,
  );
});

/// Provider pour les bibliothèques de l'utilisateur
final userLibrariesProvider = FutureProvider.autoDispose<List<BaseItemDto>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final jellyfinService = ref.watch(jellyfinServiceProvider);

  if (authState.user == null || !jellyfinService.isInitialized) {
    return [];
  }

  return await jellyfinService.getUserViews(authState.user!.id);
});

/// Helper pour obtenir l'URL d'une image Primary (poster)
String? getItemImageUrl(WidgetRef ref, BaseItemDto item, {int? maxWidth, int? maxHeight}) {
  final jellyfinService = ref.watch(jellyfinServiceProvider);

  if (item.id == null) return null;

  return jellyfinService.getImageUrl(
    item.id!,
    tag: item.imageTags?['Primary'],
    maxWidth: maxWidth,
    maxHeight: maxHeight,
  );
}

/// Helper pour obtenir l'URL d'une image backdrop haute qualité pour les cards
/// Avec fallback vers trickplay et thumb si backdrop non disponible
String? getItemCardBackdropUrl(WidgetRef ref, BaseItemDto item, {int? maxWidth}) {
  final urls = getItemCardBackdropUrls(ref, item, maxWidth: maxWidth);
  return urls.isNotEmpty ? urls.first : null;
}

/// Helper pour obtenir une liste d'URLs d'images avec fallbacks
/// Retourne toutes les URLs possibles dans l'ordre de priorité
List<String?> getItemCardBackdropUrls(WidgetRef ref, BaseItemDto item, {int? maxWidth}) {
  final jellyfinService = ref.watch(jellyfinServiceProvider);
  final urls = <String?>[];

  if (item.id == null) return urls;

  // Pour les épisodes, utiliser le backdrop de la série parente
  if (item.type?.value == 'Episode') {
    // 1. Backdrop de la série parente avec tag
    if (item.parentBackdropItemId != null &&
        item.parentBackdropImageTags != null &&
        item.parentBackdropImageTags!.isNotEmpty) {
      urls.add(jellyfinService.getBackdropUrl(
        item.parentBackdropItemId!,
        tag: item.parentBackdropImageTags!.first,
        maxWidth: maxWidth,
      ));
    }

    // 2. Backdrop de la série parente sans tag
    if (item.seriesId != null) {
      urls.add(jellyfinService.getBackdropUrl(
        item.seriesId!,
        maxWidth: maxWidth,
      ));
    }

    // 3. Backdrop de l'épisode lui-même
    final episodeBackdropTags = item.backdropImageTags;
    if (episodeBackdropTags != null && episodeBackdropTags.isNotEmpty) {
      urls.add(jellyfinService.getBackdropUrl(
        item.id!,
        tag: episodeBackdropTags.first,
        maxWidth: maxWidth,
      ));
    }

    // 4. Image Primary de l'épisode
    final primaryTag = item.imageTags?['Primary'];
    if (primaryTag != null) {
      urls.add(jellyfinService.getImageUrl(
        item.id!,
        tag: primaryTag,
        maxWidth: maxWidth,
      ));
    }

    // 5. Trickplay (capture d'écran de la vidéo)
    urls.add(jellyfinService.getTrickplayUrl(
      item.id!,
      width: maxWidth,
      index: 0,
    ));

    // 6. Thumb
    urls.add(jellyfinService.getThumbUrl(
      item.id!,
      maxWidth: maxWidth,
    ));
  } else {
    // Pour les films et séries

    // 1. Backdrop avec tag
    final backdropTags = item.backdropImageTags;
    if (backdropTags != null && backdropTags.isNotEmpty) {
      urls.add(jellyfinService.getBackdropUrl(
        item.id!,
        tag: backdropTags.first,
        maxWidth: maxWidth,
      ));
    }

    // 2. Image Primary
    final primaryTag = item.imageTags?['Primary'];
    if (primaryTag != null) {
      urls.add(jellyfinService.getImageUrl(
        item.id!,
        tag: primaryTag,
        maxWidth: maxWidth,
      ));
    }

    // 3. Thumb
    urls.add(jellyfinService.getThumbUrl(
      item.id!,
      maxWidth: maxWidth,
    ));
  }

  return urls;
}

/// Helper pour obtenir l'URL d'une image backdrop haute qualité pour le hero carousel
String? getItemBackdropUrl(WidgetRef ref, BaseItemDto item, {int? maxWidth}) {
  final jellyfinService = ref.watch(jellyfinServiceProvider);

  if (item.id == null) return null;

  // Pour les épisodes, utiliser le backdrop de la série parente
  if (item.type?.value == 'Episode') {
    if (item.parentBackdropItemId != null &&
        item.parentBackdropImageTags != null &&
        item.parentBackdropImageTags!.isNotEmpty) {
      return jellyfinService.getBackdropUrl(
        item.parentBackdropItemId!,
        tag: item.parentBackdropImageTags!.first,
        maxWidth: maxWidth,
      );
    }
    if (item.seriesId != null) {
      return jellyfinService.getBackdropUrl(
        item.seriesId!,
        maxWidth: maxWidth,
      );
    }
  }

  // Pour les films et séries, utiliser leur backdrop
  final backdropTags = item.backdropImageTags;
  if (backdropTags != null && backdropTags.isNotEmpty) {
    return jellyfinService.getBackdropUrl(
      item.id!,
      tag: backdropTags.first,
      maxWidth: maxWidth,
    );
  }

  return null;
}

/// Helper pour formater la durée de lecture restante
String getResumeTimeText(BaseItemDto item) {
  final userData = item.userData;
  if (userData == null) return '';
  
  final playbackPositionTicks = userData.playbackPositionTicks ?? 0;
  final runtimeTicks = item.runTimeTicks ?? 0;
  
  if (runtimeTicks == 0) return '';
  
  final remainingTicks = runtimeTicks - playbackPositionTicks;
  final remainingMinutes = (remainingTicks / 600000000).round();
  
  if (remainingMinutes < 60) {
    return '$remainingMinutes min restantes';
  } else {
    final hours = remainingMinutes ~/ 60;
    final minutes = remainingMinutes % 60;
    return '${hours}h${minutes > 0 ? ' ${minutes}min' : ''} restantes';
  }
}

/// Helper pour obtenir le pourcentage de progression
double getProgressPercentage(BaseItemDto item) {
  final userData = item.userData;
  if (userData == null) return 0.0;
  
  final playbackPositionTicks = userData.playbackPositionTicks ?? 0;
  final runtimeTicks = item.runTimeTicks ?? 0;
  
  if (runtimeTicks == 0) return 0.0;
  
  return playbackPositionTicks / runtimeTicks;
}

/// Helper pour obtenir le nombre d'éléments dans une bibliothèque
String getLibraryItemCount(BaseItemDto library) {
  final childCount = library.childCount ?? 0;
  return childCount.toString();
}

/// Helper pour formater les années de diffusion d'une série
/// Retourne un format comme "2020-2024" ou "2020" si pas de date de fin
String? getSeriesYears(BaseItemDto item) {
  if (item.type?.value != 'Series') return null;

  final startYear = item.productionYear;
  if (startYear == null) return null;

  // Si la série a une date de fin
  if (item.endDate != null) {
    final endYear = item.endDate!.year;
    if (endYear != startYear) {
      return '$startYear-$endYear';
    }
  }

  // Si la série est terminée mais sans endDate, utiliser juste l'année de début
  if (item.status?.toLowerCase() == 'ended') {
    return startYear.toString();
  }

  // Si la série est en cours, afficher "année-présent"
  return '$startYear-';
}

/// Helper pour formater le statut d'une série
/// Retourne "En production", "Terminée", etc.
String? getSeriesStatus(BaseItemDto item) {
  if (item.type?.value != 'Series') return null;

  final status = item.status?.toLowerCase();
  if (status == null || status.isEmpty) return null;

  switch (status) {
    case 'continuing':
      return 'En production';
    case 'ended':
      return 'Terminée';
    case 'unreleased':
      return 'À venir';
    default:
      // Capitaliser la première lettre pour les autres statuts
      return status[0].toUpperCase() + status.substring(1);
  }
}

/// Helper pour formater les métadonnées complètes d'une série
/// Retourne un format comme "2020-2024 • En production" ou "2015-2020 • Terminée"
String? getSeriesMetadata(BaseItemDto item) {
  final years = getSeriesYears(item);
  final status = getSeriesStatus(item);

  if (years == null && status == null) return null;
  if (years != null && status != null) return '$years • $status';
  return years ?? status;
}

