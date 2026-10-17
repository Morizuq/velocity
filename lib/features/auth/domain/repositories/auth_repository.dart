import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../entities/user_entity.dart';

/// Contract defining authentication operations.
abstract class AuthRepository {
  /// Stream that emits whenever the authentication state changes.
  Stream<UserEntity?> get authStateChanges;

  /// Returns the currently authenticated user, or null if unauthenticated.
  UserEntity? get currentUser;

  /// Initiates Google Sign-In using Firebase OAuth popup (optimized for Web).
  Future<UserEntity?> signInWithGoogle();

  /// Signs out the currently authenticated user and clears local session tokens.
  Future<void> signOut();

  /// Retrieves the current Firebase ID Token (JWT).
  Future<String?> getIdToken({bool forceRefresh = false});
}

/// Fallback guest repository used when unauthenticated or during isolated tests.
class GuestAuthRepository implements AuthRepository {
  const GuestAuthRepository();

  @override
  Stream<UserEntity?> get authStateChanges => Stream.value(null);

  @override
  UserEntity? get currentUser => null;

  @override
  Future<UserEntity?> signInWithGoogle() async => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async => null;
}

/// Provides the active [AuthRepository], defaulting to [GuestAuthRepository]
/// and overridden at the application composition root ([main.dart]).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return const GuestAuthRepository();
});
