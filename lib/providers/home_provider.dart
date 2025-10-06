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
  // Dédupliquer par ID
  final seen = <String>{};
  return items.where((item) {
    if (item.id == null) return false;
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

/// Helper pour obtenir l'URL d'une image
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

/// Helper pour obtenir l'URL d'un backdrop
/// Pour les épisodes, utilise le backdrop de la saison ou de la série
String? getItemBackdropUrl(WidgetRef ref, BaseItemDto item, {int? maxWidth}) {
  final jellyfinService = ref.watch(jellyfinServiceProvider);

  if (item.id == null) return null;

  // Pour les épisodes, essayer d'utiliser le backdrop du parent (saison ou série)
  if (item.type?.value == 'Episode') {
    // Essayer d'abord avec le backdrop du parent
    if (item.parentBackdropItemId != null &&
        item.parentBackdropImageTags != null &&
        item.parentBackdropImageTags!.isNotEmpty) {
      return jellyfinService.getBackdropUrl(
        item.parentBackdropItemId!,
        tag: item.parentBackdropImageTags!.first,
        maxWidth: maxWidth,
      );
    }

    // Sinon, essayer avec l'ID de la saison
    if (item.seasonId != null) {
      return jellyfinService.getBackdropUrl(
        item.seasonId!,
        maxWidth: maxWidth,
      );
    }

    // En dernier recours, utiliser l'ID de la série
    if (item.seriesId != null) {
      return jellyfinService.getBackdropUrl(
        item.seriesId!,
        maxWidth: maxWidth,
      );
    }
  }

  // Pour les autres types d'items, utiliser le backdrop de l'item lui-même
  final backdropTags = item.backdropImageTags;
  final tag = (backdropTags != null && backdropTags.isNotEmpty) ? backdropTags.first : null;

  return jellyfinService.getBackdropUrl(
    item.id!,
    tag: tag,
    maxWidth: maxWidth,
  );
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

