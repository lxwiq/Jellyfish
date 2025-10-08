import 'package:jellyfish/jellyfin/jellyfin_open_api.swagger.dart';

/// Modèle pour les filtres de recherche globale
class SearchFilters {
  final String? searchTerm;
  final List<BaseItemKind>? itemTypes;
  final List<String>? genres;
  final List<String>? studios;
  final List<String>? tags;
  final List<int>? years;
  final double? minRating;
  final bool? isFavorite;
  final bool? isUnplayed;
  final ItemSortBy? sortBy;
  final SortOrder? sortOrder;

  const SearchFilters({
    this.searchTerm,
    this.itemTypes,
    this.genres,
    this.studios,
    this.tags,
    this.years,
    this.minRating,
    this.isFavorite,
    this.isUnplayed,
    this.sortBy,
    this.sortOrder,
  });

  /// Crée une copie avec les modifications spécifiées
  SearchFilters copyWith({
    String? searchTerm,
    List<BaseItemKind>? itemTypes,
    List<String>? genres,
    List<String>? studios,
    List<String>? tags,
    List<int>? years,
    double? minRating,
    bool? isFavorite,
    bool? isUnplayed,
    ItemSortBy? sortBy,
    SortOrder? sortOrder,
  }) {
    return SearchFilters(
      searchTerm: searchTerm ?? this.searchTerm,
      itemTypes: itemTypes ?? this.itemTypes,
      genres: genres ?? this.genres,
      studios: studios ?? this.studios,
      tags: tags ?? this.tags,
      years: years ?? this.years,
      minRating: minRating ?? this.minRating,
      isFavorite: isFavorite ?? this.isFavorite,
      isUnplayed: isUnplayed ?? this.isUnplayed,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Réinitialise tous les filtres
  SearchFilters clear() {
    return const SearchFilters();
  }

  /// Vérifie si des filtres sont actifs
  bool get hasActiveFilters {
    return (searchTerm?.isNotEmpty ?? false) ||
        (itemTypes?.isNotEmpty ?? false) ||
        (genres?.isNotEmpty ?? false) ||
        (studios?.isNotEmpty ?? false) ||
        (tags?.isNotEmpty ?? false) ||
        (years?.isNotEmpty ?? false) ||
        minRating != null ||
        isFavorite != null ||
        isUnplayed != null;
  }

  /// Compte le nombre de filtres actifs
  int get activeFiltersCount {
    int count = 0;
    if (searchTerm?.isNotEmpty ?? false) count++;
    if (itemTypes?.isNotEmpty ?? false) count++;
    if (genres?.isNotEmpty ?? false) count++;
    if (studios?.isNotEmpty ?? false) count++;
    if (tags?.isNotEmpty ?? false) count++;
    if (years?.isNotEmpty ?? false) count++;
    if (minRating != null) count++;
    if (isFavorite != null) count++;
    if (isUnplayed != null) count++;
    return count;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchFilters &&
        other.searchTerm == searchTerm &&
        _listEquals(other.itemTypes, itemTypes) &&
        _listEquals(other.genres, genres) &&
        _listEquals(other.studios, studios) &&
        _listEquals(other.tags, tags) &&
        _listEquals(other.years, years) &&
        other.minRating == minRating &&
        other.isFavorite == isFavorite &&
        other.isUnplayed == isUnplayed &&
        other.sortBy == sortBy &&
        other.sortOrder == sortOrder;
  }

  @override
  int get hashCode {
    return Object.hash(
      searchTerm,
      Object.hashAll(itemTypes ?? []),
      Object.hashAll(genres ?? []),
      Object.hashAll(studios ?? []),
      Object.hashAll(tags ?? []),
      Object.hashAll(years ?? []),
      minRating,
      isFavorite,
      isUnplayed,
      sortBy,
      sortOrder,
    );
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Options de tri disponibles
class SortOption {
  final String label;
  final ItemSortBy sortBy;
  final SortOrder sortOrder;

  const SortOption({
    required this.label,
    required this.sortBy,
    required this.sortOrder,
  });

  static const List<SortOption> options = [
    SortOption(
      label: 'Nom (A-Z)',
      sortBy: ItemSortBy.sortname,
      sortOrder: SortOrder.ascending,
    ),
    SortOption(
      label: 'Nom (Z-A)',
      sortBy: ItemSortBy.sortname,
      sortOrder: SortOrder.descending,
    ),
    SortOption(
      label: 'Date d\'ajout (récent)',
      sortBy: ItemSortBy.datecreated,
      sortOrder: SortOrder.descending,
    ),
    SortOption(
      label: 'Date d\'ajout (ancien)',
      sortBy: ItemSortBy.datecreated,
      sortOrder: SortOrder.ascending,
    ),
    SortOption(
      label: 'Note (haute)',
      sortBy: ItemSortBy.communityrating,
      sortOrder: SortOrder.descending,
    ),
    SortOption(
      label: 'Note (basse)',
      sortBy: ItemSortBy.communityrating,
      sortOrder: SortOrder.ascending,
    ),
    SortOption(
      label: 'Année (récente)',
      sortBy: ItemSortBy.productionyear,
      sortOrder: SortOrder.descending,
    ),
    SortOption(
      label: 'Année (ancienne)',
      sortBy: ItemSortBy.productionyear,
      sortOrder: SortOrder.ascending,
    ),
  ];
}

