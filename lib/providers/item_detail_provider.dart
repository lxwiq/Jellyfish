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

