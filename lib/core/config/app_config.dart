import 'package:flutter/foundation.dart';
import 'app_environment.dart';

/// Immutable application runtime configuration.
///
/// Holds API endpoints, WebSocket hosts, environment identifiers,
/// and telemetry/logging flags loaded at startup via `--dart-define`.
@immutable
class AppConfig {
  /// Base URL for standard REST HTTP requests (e.g. `https://api.example.com`).
  final String apiBaseUrl;

  /// Optional base URL for WebSocket connections (e.g. `wss://api.example.com`).
  final String? wsBaseUrl;

  /// Active application environment.
  final AppEnvironment environment;

  /// Flag indicating whether verbose network/system logging is enabled.
  final bool enableLogging;

  /// Creates a typed [AppConfig] instance.
  const AppConfig({
    required this.apiBaseUrl,
    this.wsBaseUrl,
    required this.environment,
    required this.enableLogging,
  });

  /// Convenience accessor checking if the environment is development.
  bool get isDev => environment.isDev;

  /// Convenience accessor checking if the environment is staging.
  bool get isStage => environment.isStage;

  /// Convenience accessor checking if the environment is production.
  bool get isProd => environment.isProd;

  /// Initializes configuration from compile-time `--dart-define` parameters
  /// with environment-specific fallback defaults.
  ///
  /// Supported `--dart-define` keys:
  /// - `ENVIRONMENT`: dev, stage, prod (default: 'dev')
  /// - `API_BASE_URL`: Overrides the default host URL.
  /// - `WS_BASE_URL`: Overrides the default WebSocket URL.
  /// - `ENABLE_LOGGING`: Overrides default logging behavior.
  factory AppConfig.fromEnvironment() {
    const rawEnv = String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'dev',
    );
    final environment = AppEnvironment.fromString(rawEnv);

    const customApiBaseUrl = String.fromEnvironment('API_BASE_URL');
    const customWsBaseUrl = String.fromEnvironment('WS_BASE_URL');

    final String defaultApiUrl;
    final bool defaultLogging;

    switch (environment) {
      case AppEnvironment.dev:
        defaultApiUrl = 'http://localhost:3000/api';
        defaultLogging = true;
        break;
      case AppEnvironment.stage:
        defaultApiUrl = 'https://staging-api.example.com/api';
        defaultLogging = true;
        break;
      case AppEnvironment.prod:
        defaultApiUrl = 'https://api.example.com/api';
        defaultLogging = false;
        break;
    }

    final String apiBaseUrl =
        customApiBaseUrl.isNotEmpty ? customApiBaseUrl : defaultApiUrl;

    final bool enableLogging = bool.fromEnvironment(
      'ENABLE_LOGGING',
      defaultValue: defaultLogging,
    );

    // Derive WebSocket base URL if not explicitly provided
    final String? wsBaseUrl = customWsBaseUrl.isNotEmpty
        ? customWsBaseUrl
        : (apiBaseUrl.startsWith('https://')
            ? apiBaseUrl.replaceFirst('https://', 'wss://')
            : (apiBaseUrl.startsWith('http://')
                ? apiBaseUrl.replaceFirst('http://', 'ws://')
                : null));

    return AppConfig(
      apiBaseUrl: apiBaseUrl,
      wsBaseUrl: wsBaseUrl,
      environment: environment,
      enableLogging: enableLogging,
    );
  }

  /// Creates a copy of this [AppConfig] with the given fields replaced with new values.
  AppConfig copyWith({
    String? apiBaseUrl,
    String? wsBaseUrl,
    AppEnvironment? environment,
    bool? enableLogging,
  }) {
    return AppConfig(
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      wsBaseUrl: wsBaseUrl ?? this.wsBaseUrl,
      environment: environment ?? this.environment,
      enableLogging: enableLogging ?? this.enableLogging,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppConfig &&
          runtimeType == other.runtimeType &&
          apiBaseUrl == other.apiBaseUrl &&
          wsBaseUrl == other.wsBaseUrl &&
          environment == other.environment &&
          enableLogging == other.enableLogging;

  @override
  int get hashCode => Object.hash(
        apiBaseUrl,
        wsBaseUrl,
        environment,
        enableLogging,
      );

  @override
  String toString() =>
      'AppConfig(env: ${environment.name}, apiBaseUrl: $apiBaseUrl, wsBaseUrl: $wsBaseUrl, logging: $enableLogging)';
}
