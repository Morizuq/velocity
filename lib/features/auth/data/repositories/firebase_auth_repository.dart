import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// Firebase implementation of [AuthRepository] tailored for Flutter Web Google Authentication.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final SecureStorageService secureStorage;

  static const String _authTokenKey = 'auth_token';

  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    required this.secureStorage,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        return null;
      }
      final token = await user.getIdToken();
      if (token != null) {
        await secureStorage.write(_authTokenKey, token);
      }
      return _mapFirebaseUser(user, token: token);
    });
  }

  @override
  UserEntity? get currentUser {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return _mapFirebaseUser(user);
  }

  @override
  Future<UserEntity?> signInWithGoogle() async {
    try {
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      // Use popup for Flutter Web to ensure smooth OAuth flow and prevent DWDS debug issues
      final UserCredential credential = await _firebaseAuth.signInWithPopup(
        googleProvider,
      );
      final user = credential.user;

      if (user != null) {
        final token = await user.getIdToken();
        if (token != null) {
          await secureStorage.write(_authTokenKey, token);
        }
        return _mapFirebaseUser(user, token: token);
      }
      return null;
    } on FirebaseAuthException catch (_) {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Google Sign-In failed: $e',
      );
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await secureStorage.delete(_authTokenKey);
  }

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    final token = await user.getIdToken(forceRefresh);
    if (token != null) {
      await secureStorage.write(_authTokenKey, token);
    }
    return token;
  }

  UserEntity _mapFirebaseUser(User user, {String? token}) {
    return UserEntity(
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      idToken: token,
      isAnonymous: user.isAnonymous,
    );
  }
}
