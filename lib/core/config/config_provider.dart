import 'app_config.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod provider delivering the application's runtime [AppConfig].
final configProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

