import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/router.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/storage/shared_prefs_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_notifier.dart';
import 'shared/design_system/theme/circular_theme_reveal.dart';
import 'features/auth/data/repositories/firebase_auth_repository.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        authRepositoryProvider.overrideWith((ref) {
          final secureStorage = ref.watch(secureStorageServiceProvider);
          return FirebaseAuthRepository(secureStorage: secureStorage);
        }),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final themeMode = ref.watch(themeModeProvider);

        return MaterialApp.router(
          title: 'Velocity',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          themeAnimationDuration: const Duration(milliseconds: 350),
          themeAnimationCurve: Curves.easeInOutCubic,
          routerConfig: router,
          builder: (context, child) {
            return CircularThemeReveal(child: child ?? const SizedBox.shrink());
          },
        );
      },
    );
  }
}
