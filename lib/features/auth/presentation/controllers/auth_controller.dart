import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// Provides a reactive stream of the authenticated [UserEntity?].
final authStateChangesProvider = StreamProvider<UserEntity?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

/// Controller managing Google authentication actions and UI state.
class AuthController extends AsyncNotifier<UserEntity?> {
  @override
  UserEntity? build() {
    final repository = ref.watch(authRepositoryProvider);
    ref.listen(authStateChangesProvider, (_, next) {
      if (next.hasValue) {
        state = AsyncValue.data(next.value);
      }
    });
    return repository.currentUser;
  }

  /// Triggers Google Sign-In popup on Web.
  Future<bool> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.signInWithGoogle();
      state = AsyncValue.data(user);
      return user != null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Signs the user out from Firebase and clears session tokens.
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserEntity?>(AuthController.new);
