// lib/core/auth/auth_service.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_constants.dart';

// ── Модель токенів ────────────────────────────────────────────────────────────

class TokenModel {
  final String accessToken;
  final String refreshToken;
  final String? idToken;
  final DateTime expiresAt;

  const TokenModel({
    required this.accessToken,
    required this.refreshToken,
    this.idToken,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    final expiresIn = json['expires_in'];
    final expiresInInt = expiresIn is int
        ? expiresIn
        : int.tryParse(expiresIn.toString()) ?? 300;

    return TokenModel(
      accessToken: json['access_token'].toString(),
      refreshToken: json['refresh_token'].toString(),
      idToken: json['id_token']?.toString(),
      expiresAt: DateTime.now().add(Duration(seconds: expiresInInt - 30)),
    );
  }

  Map<String, String> toStorageMap() => {
    AppConstants.accessTokenKey: accessToken,
    AppConstants.refreshTokenKey: refreshToken,
    if (idToken != null) AppConstants.idTokenKey: idToken!,
    'expires_at': expiresAt.millisecondsSinceEpoch.toString(),
  };
}

// ── Модель користувача з Keycloak ─────────────────────────────────────────────

class KeycloakUser {
  final String id;
  final String email;
  final String? fullName;
  final String? firstName;
  final String? lastName;
  final List<String> roles;

  const KeycloakUser({
    required this.id,
    required this.email,
    this.fullName,
    this.firstName,
    this.lastName,
    required this.roles,
  });

  String get displayName =>
      fullName ?? '$firstName $lastName'.trim();

  String? get primaryRole {
    for (final r in [
      AppConstants.roleAdmin,
      AppConstants.roleDepartmentHead,
      AppConstants.roleInstructor,
      AppConstants.roleCadet,
    ]) {
      if (roles.contains(r)) return r;
    }
    return roles.isNotEmpty ? roles.first : null;
  }

  factory KeycloakUser.fromUserInfo(Map<String, dynamic> json) {
    // Витягуємо ролі з realm_access або resource_access
    final realmRoles = (json['realm_access']?['roles'] as List<dynamic>?)
            ?.map((r) => r.toString())
            .toList() ??
        [];
    final resourceRoles =
        (json['resource_access']?[AppConstants.keycloakClientId]?['roles']
                as List<dynamic>?)
            ?.map((r) => r.toString())
            .toList() ??
        [];

    final allRoles = {...realmRoles, ...resourceRoles}.toList();

    return KeycloakUser(
      id: json['sub'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['name'] as String?,
      firstName: json['given_name'] as String?,
      lastName: json['family_name'] as String?,
      roles: allRoles,
    );
  }
}

// ── Auth Service ──────────────────────────────────────────────────────────────

class AuthService {
  final FlutterSecureStorage _storage;
  final Dio _dio;

  AuthService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
        ),
        _dio = Dio(BaseOptions(
          connectTimeout:
              const Duration(seconds: AppConstants.connectionTimeoutSeconds),
          receiveTimeout:
              const Duration(seconds: AppConstants.connectionTimeoutSeconds),
        ));

  // ── Отримати токен (з кешу або оновити) ──────────────────────────────────

  Future<String?> getValidAccessToken() async {
    final tokens = await getSavedTokens();
    if (tokens == null) return null;

    if (tokens.isExpired) {
      try {
        final newTokens = await refreshTokens(tokens.refreshToken);
        return newTokens.accessToken;
      } catch (_) {
        await clearTokens();
        return null;
      }
    }
    return tokens.accessToken;
  }

  // ── Зберегти токени ───────────────────────────────────────────────────────

  Future<void> saveTokens(TokenModel tokens) async {
    for (final entry in tokens.toStorageMap().entries) {
      await _storage.write(key: entry.key, value: entry.value);
    }
  }

  // ── Отримати збережені токени ─────────────────────────────────────────────

  Future<TokenModel?> getSavedTokens() async {
    final accessToken = await _storage.read(key: AppConstants.accessTokenKey);
    final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
    final idToken = await _storage.read(key: AppConstants.idTokenKey);
    final expiresAtStr = await _storage.read(key: 'expires_at');

    if (accessToken == null || refreshToken == null) return null;

    final expiresAt = expiresAtStr != null
        ? DateTime.fromMillisecondsSinceEpoch(int.parse(expiresAtStr))
        : DateTime.now().subtract(const Duration(seconds: 1));

    return TokenModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
      idToken: idToken,
      expiresAt: expiresAt,
    );
  }

  // ── Обмін code на токени (PKCE flow) ─────────────────────────────────────

  Future<TokenModel> exchangeCodeForTokens({
    required String code,
    required String codeVerifier,
  }) async {
    print('TOKEN REQUEST PKCE:');
    print('code_verifier: $codeVerifier');

    try {
      final response = await _dio.post(
        AppConstants.tokenEndpoint,
        data: {
          'grant_type': 'authorization_code',
          'client_id': AppConstants.keycloakClientId,
          'code': code,
          'redirect_uri': AppConstants.keycloakRedirectUri,
          'code_verifier': codeVerifier,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.json,
        ),
      );

      print('RESPONSE TYPE: ${response.data.runtimeType}');

      final rawData = response.data;
      final Map<String, dynamic> data;
      if (rawData is Map<String, dynamic>) {
        data = rawData;
      } else if (rawData is String) {
        data = jsonDecode(rawData) as Map<String, dynamic>;
      } else {
        data = Map<String, dynamic>.from(rawData as Map);
      }
      print('DATA KEYS: ${data.keys.toList()}');
      print('expires_in type: ${data['expires_in'].runtimeType}');
      print('access_token type: ${data['access_token'].runtimeType}');
      final tokens = TokenModel.fromJson(data);
      await saveTokens(tokens);
      return tokens;
    } on DioException catch (e) {
      print('PKCE ERROR STATUS: ${e.response?.statusCode}');
      print('PKCE ERROR BODY: ${e.response?.data}');
      rethrow;
    }
  }

  // ── Оновлення токенів ────────────────────────────────────────────────────

  Future<TokenModel> refreshTokens(String refreshToken) async {
    final response = await _dio.post(
      AppConstants.tokenEndpoint,
      data: {
        'grant_type': 'refresh_token',
        'client_id': AppConstants.keycloakClientId,
        'refresh_token': refreshToken,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    final data = response.data is String
        ? jsonDecode(response.data as String) as Map<String, dynamic>
        : response.data as Map<String, dynamic>;
    final tokens = TokenModel.fromJson(data);
    await saveTokens(tokens);
    return tokens;
  }

  // ── Отримати інформацію про користувача ──────────────────────────────────

  Future<KeycloakUser?> getUserInfo(String accessToken) async {
    try {
      final response = await _dio.get(
        AppConstants.userInfoEndpoint,
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
          responseType: ResponseType.json,
        ),
      );
      final raw = response.data;
      final Map<String, dynamic> data;
      if (raw is Map<String, dynamic>) {
        data = raw;
      } else if (raw is String) {
        data = jsonDecode(raw) as Map<String, dynamic>;
      } else {
        data = Map<String, dynamic>.from(raw as Map);
      }
      return KeycloakUser.fromUserInfo(data);
    } catch (e) {
      print('getUserInfo error: $e');
      return null;
    }
  }

  // ── Обмін code без PKCE (для confidential clients) ──────────────────────

  Future<TokenModel> exchangeCodeForTokensNoVerifier({
    required String code,
  }) async {
    print('=== TOKEN REQUEST ===');
    print('URL: ${AppConstants.tokenEndpoint}');
    print('client_id: ${AppConstants.keycloakClientId}');
    print('redirect_uri: ${AppConstants.keycloakRedirectUri}');
    print('code: $code');

    try {
      final response = await _dio.post(
        AppConstants.tokenEndpoint,
        data: {
          'grant_type': 'authorization_code',
          'client_id': AppConstants.keycloakClientId,
          'code': code,
          'redirect_uri': AppConstants.keycloakRedirectUri,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.json,
        ),
      );

      print('RESPONSE: ${response.data}');

      final data = response.data is String
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;

      final tokens = TokenModel.fromJson(data);
      await saveTokens(tokens);
      return tokens;
    } on DioException catch (e) {
      print('=== TOKEN ERROR ===');
      print('STATUS: ${e.response?.statusCode}');
      print('BODY: ${e.response?.data}');
      print('REQUEST: ${e.requestOptions.data}');
      rethrow;
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────────

  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post(
        AppConstants.endSessionEndpoint,
        data: {
          'client_id': AppConstants.keycloakClientId,
          'refresh_token': refreshToken,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
    } catch (_) {}
    await clearTokens();
  }

  // ── Очистити токени ──────────────────────────────────────────────────────

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  // ── Перевірити чи є збережена сесія ─────────────────────────────────────

  Future<bool> hasValidSession() async {
    final tokens = await getSavedTokens();
    if (tokens == null) return false;
    if (!tokens.isExpired) return true;
    // Спробуємо оновити токен
    try {
      await refreshTokens(tokens.refreshToken);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
