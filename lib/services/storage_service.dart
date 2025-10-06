import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';

/// Service de stockage pour la persistance des données
/// Utilise shared_preferences pour les données non sensibles
/// et flutter_secure_storage pour les tokens
class StorageService {
  static const String _keyServerUrl = 'server_url';
  static const String _keyUser = 'user';
  static const String _keyToken = 'auth_token';
  static const String _keyDeviceId = 'device_id';

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;
  final Uuid _uuid = const Uuid();

  StorageService(this._prefs, this._secureStorage);

  /// Sauvegarde l'URL du serveur
  Future<void> saveServerUrl(String serverUrl) async {
    await _prefs.setString(_keyServerUrl, serverUrl);
  }

  /// Récupère l'URL du serveur
  String? getServerUrl() {
    return _prefs.getString(_keyServerUrl);
  }

  /// Sauvegarde les données utilisateur
  Future<void> saveUser(User user) async {
    final userJson = jsonEncode(user.toJson());
    await _prefs.setString(_keyUser, userJson);
  }

  /// Récupère les données utilisateur
  User? getUser() {
    final userJson = _prefs.getString(_keyUser);
    if (userJson == null) return null;
    
    try {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return User.fromJson(userMap);
    } catch (e) {
      return null;
    }
  }

  /// Sauvegarde le token d'authentification de manière sécurisée
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _keyToken, value: token);
  }

  /// Récupère le token d'authentification
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _keyToken);
  }

  /// Efface toutes les données (logout)
  Future<void> clearAll() async {
    await _prefs.remove(_keyServerUrl);
    await _prefs.remove(_keyUser);
    await _secureStorage.delete(key: _keyToken);
  }

  /// Vérifie si l'utilisateur est connecté (a un token)
  Future<bool> hasValidSession() async {
    final token = await getToken();
    final serverUrl = getServerUrl();
    return token != null && token.isNotEmpty && serverUrl != null && serverUrl.isNotEmpty;
  }

  /// Récupère ou génère un DeviceId unique pour cet appareil
  /// Le DeviceId est généré une seule fois et réutilisé pour toutes les sessions
  String getOrCreateDeviceId() {
    String? deviceId = _prefs.getString(_keyDeviceId);

    if (deviceId == null || deviceId.isEmpty) {
      // Générer un nouveau DeviceId unique
      deviceId = _uuid.v4();
      _prefs.setString(_keyDeviceId, deviceId);
      print('🆔 Nouveau DeviceId généré: $deviceId');
    } else {
      print('🆔 DeviceId existant: $deviceId');
    }

    return deviceId;
  }
}

