import 'analytics_event.dart';

abstract class AnalyticsService {
  Future<void> logEvent(AnalyticsEvent event);
  Future<void> setCurrentScreen(String screenName);
  Future<void> setUserId(String userId);
  Future<void> setUserProperty(String name, String value);
  Future<void> clearUser();
}
