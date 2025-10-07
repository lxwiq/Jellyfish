import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/storage_service.dart';
import '../services/jellyfin_service.dart';
import '../services/jellyseerr_service.dart';

/// Provider pour SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

/// Provider pour FlutterSecureStorage
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  return secureStorage;
});

/// Provider pour StorageService
final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return StorageService(prefs, secureStorage);
});

/// Provider pour JellyfinService
final jellyfinServiceProvider = Provider<JellyfinService>((ref) {
  return JellyfinService();
});

/// Provider pour JellyseerrService
final jellyseerrServiceProvider = Provider<JellyseerrService>((ref) {
  return JellyseerrService();
});

