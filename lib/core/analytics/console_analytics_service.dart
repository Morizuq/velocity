import 'dart:developer' as dev;
import 'analytics_event.dart';
import 'analytics_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConsoleAnalyticsService implements AnalyticsService {
  const ConsoleAnalyticsService();

  @override
  Future<void> logEvent(AnalyticsEvent event) async {
    dev.log('ANALYTICS: Log Event: ${event.name} with params: ${event.parameters}');
  }

  @override
  Future<void> setCurrentScreen(String screenName) async {
    dev.log('ANALYTICS: Set Screen: $screenName');
  }

  @override
  Future<void> setUserId(String userId) async {
    dev.log('ANALYTICS: Set User ID: $userId');
  }

  @override
  Future<void> setUserProperty(String name, String value) async {
    dev.log('ANALYTICS: Set User Property: $name = $value');
  }

  @override
  Future<void> clearUser() async {
    dev.log('ANALYTICS: Clear User');
  }
}


final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return const ConsoleAnalyticsService();
});

