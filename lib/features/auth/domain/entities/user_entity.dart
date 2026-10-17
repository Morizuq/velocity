import 'package:flutter/foundation.dart';

/// Pure domain entity representing an authenticated user.
@immutable
class UserEntity {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? idToken;
  final bool isAnonymous;

  const UserEntity({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.idToken,
    this.isAnonymous = false,
  });

  /// Derive user initials for avatar fallback.
  String get initials {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      final parts = displayName!.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }
    if (email != null && email!.isNotEmpty) {
      return email![0].toUpperCase();
    }
    return 'U';
  }

  /// Friendly display label.
  String get displayLabel {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!;
    }
    if (email != null && email!.isNotEmpty) {
      return email!;
    }
    return 'Authenticated User';
  }

  UserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? idToken,
    bool? isAnonymous,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      idToken: idToken ?? this.idToken,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'idToken': idToken,
    'isAnonymous': isAnonymous,
  };

  factory UserEntity.fromMap(Map<String, dynamic> map) => UserEntity(
    id: map['id'] as String,
    email: map['email'] as String?,
    displayName: map['displayName'] as String?,
    photoUrl: map['photoUrl'] as String?,
    idToken: map['idToken'] as String?,
    isAnonymous: map['isAnonymous'] as bool? ?? false,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          displayName == other.displayName &&
          photoUrl == other.photoUrl &&
          isAnonymous == other.isAnonymous;

  @override
  int get hashCode =>
      Object.hash(id, email, displayName, photoUrl, isAnonymous);
}
