import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'package:veyyon/features/auth/domain/entities/auth_user.dart';

class AuthUserModel {
  final String id;
  final String email;
  final String name;
  final bool isOnboarded;

  const AuthUserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.isOnboarded,
  });

  factory AuthUserModel.fromSupabase({
    required User user,
    required Map<String, dynamic> profileData,
  }) {
    return AuthUserModel(
      id: user.id,
      email: user.email ?? '',
      name:
          user.userMetadata?['full_name'] as String? ??
          user.userMetadata?['name'] as String? ??
          profileData['full_name'] as String? ??
          '',
      isOnboarded: profileData['is_onboarded'] as bool? ?? false,
    );
  }

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      name: json['full_name'] as String? ?? '',
      isOnboarded: json['is_onboarded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': name,
      'is_onboarded': isOnboarded,
    };
  }

  AuthUser toEntity() {
    return AuthUser(id: id, email: email, name: name, isOnboarded: isOnboarded);
  }
}
