import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/user_profile.dart';

/// Storage per salvare/caricare il profilo utente da SharedPreferences
class ProfileStorage {
  static const String _profileKey = 'user_profile';

  /// Carica il profilo utente da SharedPreferences
  static Future<UserProfile?> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_profileKey);
      if (profileJson == null) {
        return null;
      }
      final Map<String, dynamic> json = jsonDecode(profileJson);
      return UserProfile.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Salva il profilo utente in SharedPreferences
  static Future<bool> saveProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(profile.toJson());
      return await prefs.setString(_profileKey, profileJson);
    } catch (e) {
      return false;
    }
  }

  /// Salva la password (hash) in SharedPreferences
  static Future<bool> savePasswordHash(String passwordHash) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString('user_password_hash', passwordHash);
    } catch (e) {
      return false;
    }
  }

  /// Carica la password (hash) da SharedPreferences
  static Future<String?> loadPasswordHash() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_password_hash');
    } catch (e) {
      return null;
    }
  }

  /// Cancella il profilo utente
  static Future<bool> clearProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileKey);
      await prefs.remove('user_password_hash');
      return true;
    } catch (e) {
      return false;
    }
  }
}
