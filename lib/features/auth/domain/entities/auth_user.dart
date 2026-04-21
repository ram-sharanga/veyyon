/// lib\features\auth\domain\entities\auth_user.dart
///
/// Represents a signed-in user in the domain layer.
/// This is the single source of truth for user data across the entire app.
/// The presentation layer displays this. The data layer maps to this.
/// Nothing in the app imports Supabase's User class except the data layer.
class AuthUser {
  final String id;
  final String email;
  final String name;
  final bool isOnboarded;

  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.isOnboarded,
  });

  AuthUser copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    bool? isOnboarded,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      isOnboarded: isOnboarded ?? this.isOnboarded,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthUser &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.isOnboarded == isOnboarded;
  }

  @override
  int get hashCode {
    return Object.hash(id, email, name, isOnboarded);
  }

  @override
  String toString() {
    // Never include email in toString - it's PII.
    // Never include tokens - they're security-sensitive.
    // Only include non-sensitive identifiers.
    return 'AuthUser(id: $id, isOnboarded: $isOnboarded)';
  }
}
