import 'package:dio/dio.dart';
import '../../storage/secure_storage_service.dart';
import '../network_constants.dart';

/// Central authentication interceptor using a [QueuedInterceptor].
///
/// Attaches Bearer token to requests and manages queued token refresh on 401.
class AuthInterceptor extends QueuedInterceptor {
  final SecureStorageService secureStorage;
  final String baseUrl;
  final Dio _refreshDio;

  AuthInterceptor({
    required this.secureStorage,
    required this.baseUrl,
  })  : _refreshDio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: NetworkConstants.connectTimeout,
            receiveTimeout: NetworkConstants.receiveTimeout,
            sendTimeout: NetworkConstants.sendTimeout,
          ),
        );

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await secureStorage.read('auth_token');

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';

    super.onRequest(options, handler);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final path = err.requestOptions.path;
    final isPublicAuth =
        path == '/auth/login' ||
        path == '/auth/register' ||
        path == '/auth/refresh';

    // If request fails with 401 on non-public endpoints, trigger token refresh
    if (err.response?.statusCode == 401 && !isPublicAuth) {
      final currentToken = await secureStorage.read('auth_token');
      final requestToken = err.requestOptions.headers['Authorization']
          ?.toString()
          .replaceAll('Bearer ', '');

      if (requestToken != null &&
          currentToken != null &&
          requestToken != currentToken) {
        try {
          final retryResponse = await _retry(err.requestOptions, currentToken);
          return handler.resolve(retryResponse);
        } catch (_) {
          return super.onError(err, handler);
        }
      }

      final refreshToken = await secureStorage.read('refresh_token');

      if (refreshToken != null) {
        try {
          final response = await _refreshDio.post(
            '/auth/refresh',
            data: {'refresh_token': refreshToken},
          );

          if (response.statusCode == 200) {
            final body = response.data as Map<String, dynamic>;
            final data = body['data'] as Map<String, dynamic>;

            final newAccessToken = data['access_token'] as String;
            final newRefreshToken = data['refresh_token'] as String;

            await secureStorage.write('auth_token', newAccessToken);
            await secureStorage.write('refresh_token', newRefreshToken);

            try {
              final retryResponse = await _retry(
                err.requestOptions,
                newAccessToken,
              );
              return handler.resolve(retryResponse);
            } on DioException catch (e) {
              return handler.next(e);
            }
          }
        } catch (_) {
          // Silent refresh failed
        }
      }
    }

    super.onError(err, handler);
  }

  Future<Response<dynamic>> _retry(
    RequestOptions requestOptions,
    String accessToken,
  ) async {
    requestOptions.headers['Authorization'] = 'Bearer $accessToken';

    final retryDio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: NetworkConstants.connectTimeout,
        receiveTimeout: NetworkConstants.receiveTimeout,
        sendTimeout: NetworkConstants.sendTimeout,
      ),
    );

    return retryDio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: requestOptions.headers,
        responseType: requestOptions.responseType,
        contentType: requestOptions.contentType,
      ),
    );
  }
}
