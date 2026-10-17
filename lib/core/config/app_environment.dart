/// Application runtime environment definitions.
enum AppEnvironment {
  /// Local or development environment.
  dev,

  /// Staging / Pre-production testing environment.
  stage,

  /// Production environment serving real users.
  prod;

  /// Parses an environment name from a string (case-insensitive).
  ///
  /// Defaults to [AppEnvironment.dev] if unrecognized or null.
  static AppEnvironment fromString(String? name) {
    switch (name?.toLowerCase().trim()) {
      case 'stage':
      case 'staging':
        return AppEnvironment.stage;
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
      case 'dev':
      case 'development':
      default:
        return AppEnvironment.dev;
    }
  }

  /// Convenience getter for development checks.
  bool get isDev => this == AppEnvironment.dev;

  /// Convenience getter for staging checks.
  bool get isStage => this == AppEnvironment.stage;

  /// Convenience getter for production checks.
  bool get isProd => this == AppEnvironment.prod;
}
