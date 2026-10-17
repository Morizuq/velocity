import 'package:dio/dio.dart';

class AppFailure {
  final String message;
  final int? statusCode;
  const AppFailure({
    required this.message,
    this.statusCode,
  });
  factory AppFailure.fromDioException(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data.containsKey('message')) {
      return AppFailure(
        message: data['message'] as String,
        statusCode: e.response?.statusCode,
      );
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const AppFailure(
        message: 'Connection timed out. Please check your network.',
      );
    }
    if (e.type == DioExceptionType.connectionError) {
      return const AppFailure(
        message: 'No internet connection. Please try again.',
      );
    }
    return AppFailure(
      message: e.message ?? 'Something went wrong.',
      statusCode: e.response?.statusCode,
    );
  }
}
