// lib/core/api/api_client.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
      headers: {
        'Content-Type': 'application/json',
        'CF-Access-Client-Id': '3041217c4cb0104098b18aaa97a5b476.access',
        'CF-Access-Client-Secret': 'fcd30b8531a9a0c1099e04ed8a3d0b3bc00be9fed51066d49e414d5afc749aa9',
      },
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
      if (kDebugMode) print('[API] ${options.method} ${options.uri} — token присутній');
    } else {
      if (kDebugMode) print('[API] ${options.method} ${options.uri} — токен відсутній');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) print('[API] RESPONSE ${response.statusCode} ${response.requestOptions.uri}');
    final body = response.data;
    if (body is String && body.contains('Cloudflare Access')) {
      handler.reject(DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: 'CloudflareAccessBlocked',
      ));
      return;
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (kDebugMode) print('[API] ERROR ${err.response?.statusCode} ${err.requestOptions.uri}');

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
