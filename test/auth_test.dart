import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velocity/core/theme/app_theme.dart';
import 'package:velocity/features/auth/domain/entities/user_entity.dart';
import 'package:velocity/features/auth/domain/repositories/auth_repository.dart';
import 'package:velocity/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:velocity/features/auth/presentation/widgets/user_profile_pill.dart';

class MockAuthRepository implements AuthRepository {
  UserEntity? _user;

  @override
  Stream<UserEntity?> get authStateChanges => Stream.value(_user);

  @override
  UserEntity? get currentUser => _user;

  @override
  Future<UserEntity?> signInWithGoogle() async {
    _user = const UserEntity(
      id: 'test_uid_123',
      email: 'alex.vance@example.com',
      displayName: 'Alex Vance',
    );
    return _user;
  }

  @override
  Future<void> signOut() async {
    _user = null;
  }

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return _user != null ? 'mock_jwt_token' : null;
  }
}

void main() {
  group('Auth Domain & Entities', () {
    test(
      'UserEntity calculates initials correctly from display name or email',
      () {
        const userWithFull = UserEntity(
          id: '1',
          displayName: 'Elon Musk',
          email: 'elon@x.com',
        );
        expect(userWithFull.initials, 'EM');
        expect(userWithFull.displayLabel, 'Elon Musk');

        const userWithSingle = UserEntity(
          id: '2',
          displayName: 'Satoshi',
          email: 'satoshi@btc.org',
        );
        expect(userWithSingle.initials, 'S');

        const userWithOnlyEmail = UserEntity(
          id: '3',
          email: 'investor@gmail.com',
        );
        expect(userWithOnlyEmail.initials, 'I');
        expect(userWithOnlyEmail.displayLabel, 'investor@gmail.com');
      },
    );

    test('UserEntity serialization toMap and fromMap works symmetrically', () {
      const original = UserEntity(
        id: 'user_42',
        email: 'exec@velocity.app',
        displayName: 'Chief Executive',
        photoUrl: 'https://avatar.com/p.png',
        idToken: 'mock_jwt',
      );

      final map = original.toMap();
      final restored = UserEntity.fromMap(map);

      expect(restored, equals(original));
      expect(restored.id, 'user_42');
      expect(restored.email, 'exec@velocity.app');
    });
  });

  group('Auth Controller & Presentation Widgets', () {
    testWidgets('GoogleSignInButton triggers sign-in flow', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: Center(child: GoogleSignInButton(isCompact: false)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continue with Google'), findsOneWidget);

      await tester.tap(find.byType(GoogleSignInButton));
      await tester.pumpAndSettle();

      expect(mockRepo.currentUser?.email, 'alex.vance@example.com');
    });

    testWidgets(
      'UserProfilePill shows Sign In when unauthenticated and avatar when authenticated',
      (WidgetTester tester) async {
        final mockRepo = MockAuthRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: const Scaffold(body: Center(child: UserProfilePill())),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sign In'), findsOneWidget);

        // Trigger sign-in
        await tester.tap(find.byType(GoogleSignInButton));
        await tester.pumpAndSettle();

        // Now should show user initials and display name
        expect(find.text('AV'), findsOneWidget);
        expect(find.text('Alex Vance'), findsOneWidget);
      },
    );
  });
}
