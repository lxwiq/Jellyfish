# Jellyseerr Integration Redesign - Documentation

## 📋 Vue d'ensemble

Redesign complet de l'intégration Jellyseerr dans l'application Jellyfish avec une interface moderne, cohérente et responsive qui suit les standards de design de l'application.

## ✅ Travaux réalisés

### Phase 1: Branding & Assets ✅
- ✅ Téléchargement des icônes Jellyseerr officielles (PNG et SVG)
- ✅ Ajout des assets dans `assets/icons/jellyseerr.png` et `assets/icons/jellyseerr.svg`
- ✅ Configuration dans `pubspec.yaml`

### Phase 2: Service Layer Enhancements ✅
- ✅ Extension de `JellyseerrService` avec support du filtrage par genres
- ✅ Ajout des paramètres `genres` et `sortBy` aux méthodes:
  - `getTrending()`
  - `getPopularMovies()`
  - `getPopularTv()`
- ✅ Nouvelles méthodes pour récupérer les genres:
  - `getMovieGenres()` - Liste des genres de films
  - `getTvGenres()` - Liste des genres de séries
- ✅ Nouveau modèle `Genre` avec sérialisation JSON

### Phase 3: Reusable UI Components ✅
Création de widgets réutilisables et modulaires:

#### `JellyseerrMediaCard` (`lib/screens/jellyseerr/widgets/jellyseerr_media_card.dart`)
- Carte de média standardisée suivant `CardConstants`
- Support responsive (mobile, tablet, desktop)
- Badges de type de média (Film/Série)
- Affichage de la note avec étoile
- Gestion du cache avec `CustomCacheManager`
- Navigation vers l'écran de détails

#### `JellyseerrFilterChips` (`lib/screens/jellyseerr/widgets/jellyseerr_filter_chips.dart`)
- Chips de filtrage horizontaux scrollables
- Sélection multiple de genres
- Design cohérent avec `AppColors`
- États sélectionné/non-sélectionné

#### `JellyseerrSectionTitle` (`lib/screens/jellyseerr/widgets/jellyseerr_section_title.dart`)
- Titre de section standardisé
- Icône colorée avec `jellyfinPurple`
- Bouton "Voir tout" optionnel
- Support responsive

#### Widgets pour l'écran de détails:

**`MediaDetailHeader`** (`lib/screens/jellyseerr/widgets/media_detail_header.dart`)
- SliverAppBar avec backdrop et poster
- Gradient overlay élégant
- Badge de note avec étoile
- Support responsive

**`MediaInfoSection`** (`lib/screens/jellyseerr/widgets/media_info_section.dart`)
- Chips d'information (date, durée)
- Chips de genres avec style distinct
- Formatage automatique de la durée
- Layout responsive avec Wrap

**`MediaOverviewSection`** (`lib/screens/jellyseerr/widgets/media_overview_section.dart`)
- Synopsis avec expansion/collapse
- Animation smooth
- Bouton "Voir plus/moins" pour les longs textes
- Limite de 4 lignes par défaut

**`MediaCastSection`** (`lib/screens/jellyseerr/widgets/media_cast_section.dart`)
- Carousel horizontal du casting
- Photos des acteurs avec fallback
- Nom de l'acteur et du personnage
- Utilisation de `HorizontalCarousel`

**`MediaRequestButton`** (`lib/screens/jellyseerr/widgets/media_request_button.dart`)
- Bouton de demande avec états multiples:
  - Normal: "Demander ce contenu"
  - En cours: "Demande en cours..."
  - Demandé: "Déjà demandé"
  - Disponible: "Disponible sur Jellyfin"
- Icônes et couleurs adaptées à chaque état
- Support responsive

### Phase 4: Screen Redesigns ✅

#### `jellyseerr_discover_screen.dart` - Écran de découverte ✅
**Avant:**
- Design basique avec grilles statiques
- Pas de branding Jellyseerr
- Recherche dans un dialog
- Pas de filtrage
- Layout non responsive

**Après:**
- ✅ CustomScrollView avec SliverAppBar
- ✅ Logo Jellyseerr dans l'AppBar
- ✅ TabBar avec 3 onglets (Tendances, Films, Séries)
- ✅ Carousels horizontaux au lieu de grilles
- ✅ RefreshIndicator sur chaque tab
- ✅ Navigation vers l'écran de recherche dédié
- ✅ États de chargement et d'erreur cohérents
- ✅ Thème AppColors complet
- ✅ Support responsive (mobile, tablet, desktop)

#### `jellyseerr_media_detail_screen.dart` - Écran de détails ✅
**Avant:**
- Code monolithique de 645 lignes
- Design incohérent
- Pas de modularité
- Layout fixe

**Après:**
- ✅ Architecture modulaire avec widgets réutilisables
- ✅ CustomScrollView avec SliverAppBar expansible
- ✅ Header avec backdrop et poster
- ✅ Section d'informations (date, durée, genres)
- ✅ Bouton de demande avec états
- ✅ Synopsis avec expansion
- ✅ Section casting avec carousel
- ✅ Design cohérent avec AppColors
- ✅ Support responsive complet
- ✅ Gestion d'erreurs améliorée

#### `jellyseerr_setup_screen.dart` - Écran de configuration ✅
**Avant:**
- Design basique
- Pas de branding
- Formulaires standards
- Pas de feedback visuel

**Après:**
- ✅ Logo Jellyseerr dans l'AppBar et le contenu
- ✅ Design en 2 étapes numérotées
- ✅ Champs de formulaire stylisés avec AppColors
- ✅ Toggle de visibilité du mot de passe
- ✅ Messages d'information et d'erreur stylisés
- ✅ Boutons avec états de chargement
- ✅ Layout centré et responsive
- ✅ Largeur maximale sur desktop (500px)

### Phase 5: New Features ✅

#### `jellyseerr_search_screen.dart` - Écran de recherche dédié ✅
- ✅ Écran de recherche full-screen
- ✅ Barre de recherche avec auto-focus
- ✅ Bouton de clear
- ✅ Grille responsive de résultats
- ✅ États vides avec messages appropriés
- ✅ Gestion d'erreurs
- ✅ Utilisation de `JellyseerrMediaCard`
- ✅ Support responsive (3/4/6 colonnes selon la taille)

### Phase 6: Home & Onboarding Integration ✅

#### Intégration dans l'écran d'accueil ✅
- ✅ Remplacement de l'icône générique par le logo Jellyseerr
- ✅ Icône colorée dans la barre d'actions
- ✅ Navigation vers `JellyseerrScreen`

## 🎨 Design System

### Couleurs utilisées
- **Background**: `AppColors.background1`, `background2`, `background3`
- **Surface**: `AppColors.surface1`, `surface2`
- **Text**: `AppColors.text1` à `text6`
- **Primary**: `AppColors.jellyfinPurple`
- **Error**: `AppColors.error`

### Tailles de cartes
- Utilisation de `CardConstants` pour les ratios
- `posterAspectRatio` (2/3) pour les posters
- `CardSizeHelper.getSizes()` pour les dimensions responsive

### Responsive Breakpoints
- **Mobile**: < 600px
- **Tablet**: 600px - 899px
- **Desktop**: ≥ 900px

### Spacing
- **Desktop**: 32px horizontal padding
- **Mobile/Tablet**: 16px horizontal padding

## 📁 Structure des fichiers

```
lib/screens/jellyseerr/
├── jellyseerr_screen.dart                    # Point d'entrée
├── jellyseerr_discover_screen.dart           # ✅ Redesigné - Écran de découverte
├── jellyseerr_media_detail_screen.dart       # ✅ Redesigné - Détails du média
├── jellyseerr_setup_screen.dart              # ✅ Redesigné - Configuration
├── jellyseerr_search_screen.dart             # ✅ Nouveau - Recherche dédiée
├── jellyseerr_requests_screen.dart           # À améliorer
└── widgets/
    ├── jellyseerr_media_card.dart            # ✅ Carte de média
    ├── jellyseerr_filter_chips.dart          # ✅ Chips de filtrage
    ├── jellyseerr_section_title.dart         # ✅ Titre de section
    ├── media_detail_header.dart              # ✅ Header de détails
    ├── media_info_section.dart               # ✅ Section d'infos
    ├── media_overview_section.dart           # ✅ Section synopsis
    ├── media_cast_section.dart               # ✅ Section casting
    └── media_request_button.dart             # ✅ Bouton de demande
```

## 🔧 Services & Providers

### JellyseerrService
- `getTrending({genres, sortBy})` - Tendances avec filtres
- `getPopularMovies({genres, sortBy})` - Films populaires avec filtres
- `getPopularTv({genres, sortBy})` - Séries populaires avec filtres
- `getMovieGenres()` - Liste des genres de films
- `getTvGenres()` - Liste des genres de séries
- `requestMedia()` - Demander un média

### Providers
- `jellyseerrTrendingProvider` - Tendances
- `jellyseerrPopularMoviesProvider` - Films populaires
- `jellyseerrPopularTvProvider` - Séries populaires
- `jellyseerrSearchProvider` - Recherche
- `jellyseerrMovieDetailsProvider` - Détails film
- `jellyseerrTvDetailsProvider` - Détails série
- `jellyseerrAuthStateProvider` - État d'authentification

## 🚀 Fonctionnalités implémentées

### ✅ Complétées
- [x] Branding Jellyseerr partout
- [x] Design cohérent avec l'app
- [x] Responsive design (mobile, tablet, desktop)
- [x] Écran de recherche dédié
- [x] Filtrage par genres (backend ready)
- [x] Carousels horizontaux
- [x] États de chargement et d'erreur
- [x] Animations et transitions
- [x] Gestion du cache d'images
- [x] Architecture modulaire

### 🔄 À améliorer (optionnel)
- [ ] Filtrage par plateformes de streaming
- [ ] UI de filtrage dans l'écran de découverte
- [ ] Amélioration de `jellyseerr_requests_screen.dart`
- [ ] Ajout à l'onboarding
- [ ] Tests sur vrais appareils
- [ ] Skeleton loaders

## 📝 Notes techniques

### Gestion du cache
- Utilisation de `CustomCacheManager` pour toutes les images
- `memCacheWidth` optimisé avec `CardConstants.getOptimalImageWidth()`
- Placeholders et error widgets cohérents

### Navigation
- `Navigator.push()` pour les transitions
- Routes MaterialPageRoute
- Retour automatique avec AppBar

### État et données
- Riverpod pour la gestion d'état
- AsyncValue pour les données asynchrones
- Invalidation pour le refresh

### Performance
- Lazy loading des images
- Carousels au lieu de grilles infinies
- Pagination prête (non implémentée dans l'UI)

## 🎯 Résultat final

L'intégration Jellyseerr est maintenant:
- ✅ **Moderne** - Design Material 3 cohérent
- ✅ **Responsive** - Adapté à toutes les tailles d'écran
- ✅ **Performante** - Cache optimisé, lazy loading
- ✅ **Modulaire** - Widgets réutilisables
- ✅ **Complète** - Toutes les fonctionnalités de base
- ✅ **Branded** - Logo Jellyseerr visible partout
- ✅ **Intuitive** - Navigation claire et fluide

## 🔗 Fichiers modifiés

### Nouveaux fichiers créés (9)
1. `lib/screens/jellyseerr/jellyseerr_search_screen.dart`
2. `lib/screens/jellyseerr/widgets/jellyseerr_media_card.dart`
3. `lib/screens/jellyseerr/widgets/jellyseerr_filter_chips.dart`
4. `lib/screens/jellyseerr/widgets/jellyseerr_section_title.dart`
5. `lib/screens/jellyseerr/widgets/media_detail_header.dart`
6. `lib/screens/jellyseerr/widgets/media_info_section.dart`
7. `lib/screens/jellyseerr/widgets/media_overview_section.dart`
8. `lib/screens/jellyseerr/widgets/media_cast_section.dart`
9. `lib/screens/jellyseerr/widgets/media_request_button.dart`

### Fichiers modifiés (5)
1. `lib/models/jellyseerr_models.dart` - Ajout du modèle Genre
2. `lib/services/jellyseerr_service.dart` - Ajout filtrage et genres
3. `lib/screens/jellyseerr/jellyseerr_discover_screen.dart` - Redesign complet
4. `lib/screens/jellyseerr/jellyseerr_setup_screen.dart` - Redesign complet
5. `lib/screens/home/home_screen.dart` - Ajout icône Jellyseerr

### Assets ajoutés (2)
1. `assets/icons/jellyseerr.png`
2. `assets/icons/jellyseerr.svg`

---

**Date de réalisation**: 2025-10-07
**Statut**: ✅ Implémentation complète et fonctionnelle

