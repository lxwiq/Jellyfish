import 'package:flutter/material.dart';

/// Extension pour ajouter des helpers de localisation sur BuildContext
extension LocalizationHelper on BuildContext {
  /// Retourne un objet contenant toutes les chaînes localisées
  LocalizedStrings get localized => LocalizedStrings();
}

/// Classe contenant toutes les chaînes de texte localisées
/// Pour l'instant, tout est en anglais/français
class LocalizedStrings {
  // Metadata Refresh
  String get metadataRefreshDefault => 'Default Refresh';
  String get metadataRefreshValidation => 'Validation Only';
  String get metadataRefreshFull => 'Full Refresh';

  // Image Refresh
  String get imageRefreshDefault => 'Default';
  String get imageRefreshValidation => 'Validation Only';
  String get imageRefreshFull => 'Full Refresh';

  // Repeat Mode
  String get repeatModeNone => 'No Repeat';
  String get repeatModeAll => 'Repeat All';
  String get repeatModeOne => 'Repeat One';

  // Sort Order
  String get sortOrderAscending => 'Ascending';
  String get sortOrderDescending => 'Descending';

  // Item Fields
  String get itemFieldAirTime => 'Air Time';
  String get itemFieldCanDelete => 'Can Delete';
  String get itemFieldCanDownload => 'Can Download';
  String get itemFieldChannelInfo => 'Channel Info';
  String get itemFieldChapters => 'Chapters';
  String get itemFieldChildCount => 'Child Count';
  String get itemFieldCumulativeRunTimeTicks => 'Cumulative Run Time';
  String get itemFieldCustomRating => 'Custom Rating';
  String get itemFieldDateCreated => 'Date Created';
  String get itemFieldDateLastMediaAdded => 'Date Last Media Added';
  String get itemFieldDisplayPreferencesId => 'Display Preferences ID';
  String get itemFieldEtag => 'ETag';
  String get itemFieldExternalUrls => 'External URLs';
  String get itemFieldGenres => 'Genres';
  String get itemFieldHomePageUrl => 'Home Page URL';
  String get itemFieldItemCounts => 'Item Counts';
  String get itemFieldMediaSourceCount => 'Media Source Count';
  String get itemFieldMediaSources => 'Media Sources';
  String get itemFieldOriginalTitle => 'Original Title';
  String get itemFieldOverview => 'Overview';
  String get itemFieldParentId => 'Parent ID';
  String get itemFieldPath => 'Path';
  String get itemFieldPeople => 'People';
  String get itemFieldPlayAccess => 'Play Access';
  String get itemFieldProductionLocations => 'Production Locations';
  String get itemFieldProviderIds => 'Provider IDs';
  String get itemFieldPrimaryImageAspectRatio => 'Primary Image Aspect Ratio';
  String get itemFieldRecursiveItemCount => 'Recursive Item Count';
  String get itemFieldSettings => 'Settings';
  String get itemFieldScreenshotImageTags => 'Screenshot Image Tags';
  String get itemFieldSeriesPrimaryImage => 'Series Primary Image';
  String get itemFieldSeriesStudio => 'Series Studio';
  String get itemFieldSortName => 'Sort Name';
  String get itemFieldSpecialEpisodeNumbers => 'Special Episode Numbers';
  String get itemFieldStudios => 'Studios';
  String get itemFieldBasicSyncInfo => 'Basic Sync Info';
  String get itemFieldSyncInfo => 'Sync Info';
  String get itemFieldTaglines => 'Taglines';
  String get itemFieldTags => 'Tags';
  String get itemFieldRemoteTrailers => 'Remote Trailers';
  String get itemFieldMediaStreams => 'Media Streams';
  String get itemFieldSeasonUserData => 'Season User Data';
  String get itemFieldServiceName => 'Service Name';
  String get itemFieldThemeSongIds => 'Theme Song IDs';
  String get itemFieldThemeVideoIds => 'Theme Video IDs';
  String get itemFieldExternalEtag => 'External ETag';
  String get itemFieldPresentationUniqueKey => 'Presentation Unique Key';
  String get itemFieldInheritedParentalRatingValue => 'Inherited Parental Rating Value';
  String get itemFieldExternalSeriesId => 'External Series ID';
  String get itemFieldSeriesPresentationUniqueKey => 'Series Presentation Unique Key';
  String get itemFieldDateLastRefreshed => 'Date Last Refreshed';
  String get itemFieldDateLastSaved => 'Date Last Saved';
  String get itemFieldRefreshState => 'Refresh State';
  String get itemFieldChannelImage => 'Channel Image';
  String get itemFieldEnableMediaSourceDisplay => 'Enable Media Source Display';
  String get itemFieldWidth => 'Width';
  String get itemFieldHeight => 'Height';
  String get itemFieldExtraIds => 'Extra IDs';
  String get itemFieldLocalTrailerCount => 'Local Trailer Count';
  String get itemFieldIsHD => 'Is HD';
  String get itemFieldSpecialFeatureCount => 'Special Feature Count';
}

