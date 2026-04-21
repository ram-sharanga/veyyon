import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_user_model.dart';

/// Keys for SharedPreferences storage.
/// Defined as constants to prevent typo bugs.
/// If you change a key name, every read and write updates together.
class _Keys {
  static const String cachedUser = 'cached_auth_user';
  _Keys._();
}

/// Handles local caching of user profile data.
///
/// Why cache at all? Supabase Flutter SDK persists the session token
/// (so users stay logged in across app restarts) but it doesn't cache
/// your custom profile data (fullName, avatarUrl, isOnboarded).
///
/// Without a local cache, every app launch would require a network call
/// to fetch the profile before showing any user-specific UI.
/// With a cache, you show stale data instantly and refresh in background.
///
/// What we store here:
/// - AuthUserModel as JSON → SharedPreferences (non-sensitive profile data)
///
/// What we do NOT store here:
/// - Auth tokens → Supabase SDK handles this internally
/// - Sensitive user data → use flutter_secure_storage for that
///
/// SharedPreferences is appropriate here because this data is not
/// sensitive — it's display data (name, avatar URL, onboarding status).
class LocalAuthDataSource {
  final SharedPreferences _prefs;

  const LocalAuthDataSource({required this._prefs});

  /// Saves the user model to local cache.
  /// Called after every successful sign-in and profile update.
  Future<void> cacheUser(AuthUserModel user) async {
    await _prefs.setString(_Keys.cachedUser, jsonEncode(user.toJson()));
  }

  /// Retrieves the cached user model.
  /// Returns null if no user has been cached (first launch, or after clear).
  AuthUserModel? getCachedUser() {
    final jsonString = _prefs.getString(_Keys.cachedUser);
    if (jsonString == null) return null;

    try {
      return AuthUserModel.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );
    } catch (_) {
      // If the cached data is corrupted or schema has changed,
      // return null and let the app fetch fresh data.
      // Clear the corrupted cache entry.
      _prefs.remove(_Keys.cachedUser);
      return null;
    }
  }

  /// Clears all cached user data.
  /// Called on sign-out to ensure no stale data remains.
  Future<void> clearCache() async {
    await _prefs.remove(_Keys.cachedUser);
  }
}
