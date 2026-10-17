import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import 'network_constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/config_provider.dart';

/// Riverpod provider supplying the configured [Dio] HTTP client.
final dioProvider = Provider<Dio>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final config = ref.watch(configProvider);
  return createDio(config: config, secureStorage: secureStorage);
});


/// Core factory that builds and configures a production-ready [Dio] HTTP client.
Dio createDio({
  required AppConfig config,
  required SecureStorageService secureStorage,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: NetworkConstants.connectTimeout,
      receiveTimeout: NetworkConstants.receiveTimeout,
      sendTimeout: NetworkConstants.sendTimeout,
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      secureStorage: secureStorage,
      baseUrl: config.apiBaseUrl,
    ),
  );

  if (config.enableLogging) {
    dio.interceptors.add(AppLoggingInterceptor());
  }

  return dio;
}
