import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../jellyfin/jellyfin_open_api.swagger.dart';
import '../services/jellyfin_service.dart';
import 'auth_provider.dart';
import 'services_provider.dart';

/// État pour la pagination et les filtres de la bibliothèque
class LibraryState {
  final List<BaseItemDto> items;
  final int totalCount;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int currentPage;
  final ItemSortBy sortBy;
  final SortOrder sortOrder;
  final List<BaseItemKind>? itemTypeFilter;
  final String? searchQuery;

  const LibraryState({
    this.items = const [],
    this.totalCount = 0,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 0,
    this.sortBy = ItemSortBy.sortname,
    this.sortOrder = SortOrder.ascending,
    this.itemTypeFilter,
    this.searchQuery,
  });

  LibraryState copyWith({
    List<BaseItemDto>? items,
    int? totalCount,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? currentPage,
    ItemSortBy? sortBy,
    SortOrder? sortOrder,
    List<BaseItemKind>? itemTypeFilter,
    String? searchQuery,
  }) {
    return LibraryState(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      itemTypeFilter: itemTypeFilter ?? this.itemTypeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Notifier pour gérer l'état de la bibliothèque
class LibraryNotifier extends StateNotifier<LibraryState> {
  final String libraryId;
  final JellyfinService jellyfinService;
  final String userId;
  
  static const int _pageSize = 50;

  LibraryNotifier({
    required this.libraryId,
    required this.jellyfinService,
    required this.userId,
  }) : super(const LibraryState()) {
    loadInitialItems();
  }

  /// Charge les premiers items
  Future<void> loadInitialItems() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await jellyfinService.getLibraryItems(
        userId,
        libraryId,
        startIndex: 0,
        limit: _pageSize,
        sortBy: [state.sortBy],
        sortOrder: [state.sortOrder],
        includeItemTypes: state.itemTypeFilter,
        searchTerm: state.searchQuery,
      );

      state = state.copyWith(
        items: result.items ?? [],
        totalCount: result.totalRecordCount ?? 0,
        isLoading: false,
        hasMore: (result.items?.length ?? 0) >= _pageSize,
        currentPage: 0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Charge la page suivante
  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.currentPage + 1;
      final result = await jellyfinService.getLibraryItems(
        userId,
        libraryId,
        startIndex: nextPage * _pageSize,
        limit: _pageSize,
        sortBy: [state.sortBy],
        sortOrder: [state.sortOrder],
        includeItemTypes: state.itemTypeFilter,
        searchTerm: state.searchQuery,
      );

      final newItems = result.items ?? [];
      state = state.copyWith(
        items: [...state.items, ...newItems],
        totalCount: result.totalRecordCount ?? state.totalCount,
        isLoading: false,
        hasMore: newItems.length >= _pageSize,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Change le tri
  void changeSorting(ItemSortBy sortBy, SortOrder sortOrder) {
    state = state.copyWith(
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
    loadInitialItems();
  }

  /// Change le filtre de type d'item
  void changeItemTypeFilter(List<BaseItemKind>? itemTypes) {
    state = state.copyWith(
      itemTypeFilter: itemTypes,
    );
    loadInitialItems();
  }

  /// Change la recherche
  void search(String? query) {
    state = state.copyWith(
      searchQuery: query,
    );
    loadInitialItems();
  }

  /// Rafraîchit les données
  Future<void> refresh() async {
    await loadInitialItems();
  }
}

/// Provider pour une bibliothèque spécifique
final libraryProvider = StateNotifierProvider.family<LibraryNotifier, LibraryState, String>(
  (ref, libraryId) {
    final authState = ref.watch(authStateProvider);
    final jellyfinService = ref.watch(jellyfinServiceProvider);

    if (authState.user == null) {
      throw Exception('Utilisateur non connecté');
    }

    return LibraryNotifier(
      libraryId: libraryId,
      jellyfinService: jellyfinService,
      userId: authState.user!.id,
    );
  },
);

