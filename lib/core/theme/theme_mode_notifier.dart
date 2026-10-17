import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/shared_prefs_storage.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

/// Theme mode manager that defaults to sleek dark mode and persists user preference.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _storageKey = 'velocity_theme_mode';

  @override
  ThemeMode build() {
    try {
      final storage = ref.watch(storageServiceProvider);
      final savedMode = storage.getString(_storageKey);
      if (savedMode == 'light') return ThemeMode.light;
      if (savedMode == 'dark') return ThemeMode.dark;
    } catch (_) {
      // Fallback for tests or un-initialized storage
    }
    // Default to sleek dark mode as intended for Velocity
    return ThemeMode.dark;
  }

  void toggleTheme() {
    final nextMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = nextMode;
    try {
      final storage = ref.read(storageServiceProvider);
      storage.setString(_storageKey, nextMode == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    try {
      final storage = ref.read(storageServiceProvider);
      storage.setString(_storageKey, mode == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }
}
