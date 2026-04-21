import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper around flutter_secure_storage with correct configuration.
///
/// Use this for:
/// - Any data that would be damaging if leaked
/// - Anything that should survive app reinstall (if desired)
/// - Data that should not appear in backups
///
/// Do NOT use for:
/// - Non-sensitive display data (use SharedPreferences)
/// - Large data (Keychain/Keystore have size limits)
/// - Data that changes frequently (secure storage has write overhead)
///
/// For auth specifically:
/// - Supabase session tokens: managed by Supabase SDK (SharedPreferences)
/// - Additional sensitive user data: use this service
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService()
    : _storage = const FlutterSecureStorage(
        // iOS options
        iOptions: IOSOptions(
          // accessibility: when is the data accessible?
          // unlocked: only when device is unlocked (most secure)
          // This is the correct setting — you don't need to access
          // auth data when the app is backgrounded without the screen on.
          accessibility: KeychainAccessibility.first_unlock,
          // synchronizable: should this sync to iCloud Keychain?
          // false: keep data local to this device
          // For auth tokens: always false (device-specific)
          synchronizable: false,
        ),
        // Android options
        aOptions: AndroidOptions(
          // encryptedSharedPreferences: use EncryptedSharedPreferences
          // which uses Android Keystore for key management.
          // This is the correct setting for Android.
          encryptedSharedPreferences: true,
        ),
      );

  /// Store a value securely.
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  /// Read a stored value. Returns null if not found.
  Future<String?> read({required String key}) async {
    return _storage.read(key: key);
  }

  /// Delete a stored value.
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  /// Delete all stored values.
  /// Call this on sign-out to ensure no sensitive data remains.
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Check if a key exists.
  Future<bool> containsKey({required String key}) async {
    return _storage.containsKey(key: key);
  }
}

/// Keys for secure storage — centralized to prevent typos.
abstract class SecureStorageKeys {
  /// The Apple user identifier (stable ID from Apple).
  /// Needed for credential state checking (Step 33).
  /// Apple returns this as the 'sub' claim in their identity token.
  static const String appleUserIdentifier = 'apple_user_identifier';

  SecureStorageKeys._();
}
