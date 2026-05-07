// lib/core/api/api_client.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_service.dart';
import '../utils/app_constants.dart';

class ApiClient {
  late final Dio dio;

  ApiClient(AuthService authService) {
    dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: AppConstants.connectionTimeoutSeconds),
      receiveTimeout: const Duration(seconds: AppConstants.connectionTimeoutSeconds),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(_AuthInterceptor(authService, dio));
  }
}

class _AuthInterceptor extends Interceptor {
  final AuthService _authService;
  final Dio _dio;
  bool _isRefreshing = false;

  _AuthInterceptor(this._authService, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _authService.getValidAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      print('[API] ${options.method} ${options.uri} — token присутній');
    } else {
      print('[API] ${options.method} ${options.uri} — ⚠️ токен відсутній!');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('[API] RESPONSE ${response.statusCode} ${response.requestOptions.uri}');
    print('[API] RESPONSE body: ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    print('[API] ERROR ${err.response?.statusCode} ${err.requestOptions.uri}');
    print('[API] ERROR body: ${err.response?.data}');
    print('[API] ERROR headers: ${err.response?.headers}');

    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final tokens = await _authService.getSavedTokens();
        if (tokens != null) {
          final newTokens = await _authService.refreshTokens(tokens.refreshToken);
          err.requestOptions.headers['Authorization'] =
              'Bearer ${newTokens.accessToken}';
          final retry = await _dio.fetch(err.requestOptions);
          handler.resolve(retry);
          return;
        }
      } catch (_) {
      } finally {
        _isRefreshing = false;
      }
    }
    handler.next(err);
  }
}

// ─── Provider (ручний) ────────────────────────────────────────────────────────

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.read(authServiceProvider));
});
