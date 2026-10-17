import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SharedPrefsStorage implements StorageService {
  final SharedPreferences _prefs;

  const SharedPrefsStorage(this._prefs);

  @override
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  @override
  String? getString(String key) {
    return _prefs.getString(key);
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  @override
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  @override
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  @override
  Future<bool> clear() async {
    return await _prefs.clear();
  }
}


// Pre-initialize SharedPreferences in main.dart and override this provider in the ProviderScope:
//
// final sharedPrefs = await SharedPreferences.getInstance();
// ProviderScope(
//   overrides: [
//     sharedPreferencesProvider.overrideWithValue(sharedPrefs),
//   ],
//   child: const MyApp(),
// )
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override sharedPreferencesProvider in ProviderScope');
});

final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SharedPrefsStorage(prefs);
});

