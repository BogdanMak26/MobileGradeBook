// lib/features/auth/presentation/viewmodels/auth_viewmodel.dart

import 'dart:convert';
import 'dart:math';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/api/repositories.dart';
import '../../../../core/auth/app_pin_service.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/auth/biometric_service.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/notifications/fcm_service.dart';
import '../../../../core/utils/app_constants.dart';

enum AuthStatus { initial, loading, locked, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? role;
  final String? email;
  final String? fullName;
  final String? errorMessage;
  final String? rank;
  final String? position;
  final String? groupName;
  final String? kafedraName;
  final int? kafedraId;
  final int? groupId;
  final String? facultyName;
  // true after fresh OAuth login when device has no security configured
  final bool needsSecurityPrompt;

  const AuthState({
    this.status = AuthStatus.initial,
    this.userId,
    this.role,
    this.email,
    this.fullName,
    this.errorMessage,
    this.rank,
    this.position,
    this.groupName,
    this.kafedraName,
    this.kafedraId,
    this.groupId,
    this.facultyName,
    this.needsSecurityPrompt = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? role,
    String? email,
    String? fullName,
    String? errorMessage,
    String? rank,
    String? position,
    String? groupName,
    String? kafedraName,
    int? kafedraId,
    int? groupId,
    String? facultyName,
    bool? needsSecurityPrompt,
  }) =>
      AuthState(
        status: status ?? this.status,
        userId: userId ?? this.userId,
        role: role ?? this.role,
        email: email ?? this.email,
        fullName: fullName ?? this.fullName,
        errorMessage: errorMessage,
        rank: rank ?? this.rank,
        position: position ?? this.position,
        groupName: groupName ?? this.groupName,
        kafedraName: kafedraName ?? this.kafedraName,
        kafedraId: kafedraId ?? this.kafedraId,
        groupId: groupId ?? this.groupId,
        facultyName: facultyName ?? this.facultyName,
        needsSecurityPrompt: needsSecurityPrompt ?? this.needsSecurityPrompt,
      );

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLocked => status == AuthStatus.locked;
}

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthService _authService;
  final UserRepository _userRepo;
  final FcmService _fcmService;
  final CadetsRepository _cadetsRepo;
  final TeachersRepository _teachersRepo;
  String? _codeVerifier;
  bool _processingCallback = false;

  AuthViewModel(this._authService, this._userRepo, this._fcmService,
      this._cadetsRepo, this._teachersRepo)
      : super(const AuthState()) {
    _initDeepLinks();
    checkAuthStatus();
  }

  void _initDeepLinks() {
    final appLinks = AppLinks();
    appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == 'com.viti.gradebook' &&
          uri.host == 'callback' &&
          !_processingCallback) {
        final code = uri.queryParameters['code'];
        if (code != null && _codeVerifier != null) {
          _handleCallback(code, _codeVerifier!);
        }
      }
    });
  }

  // On app start: checks if a session exists. Sets `locked` (requires device auth)
  // or `unauthenticated`. Does NOT load user data — that happens after device auth.
  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final hasSession = await _authService.hasValidSession();
      state = state.copyWith(
        status: hasSession ? AuthStatus.locked : AuthStatus.unauthenticated,
      );
    } catch (_) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      _codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(_codeVerifier!);

      final authUri = Uri.parse(AppConstants.authorizationEndpoint).replace(
        queryParameters: {
          'response_type': 'code',
          'client_id': AppConstants.keycloakClientId,
          'redirect_uri': AppConstants.keycloakRedirectUri,
          'scope': AppConstants.scopes.join(' '),
          'code_challenge': codeChallenge,
          'code_challenge_method': 'S256',
        },
      );

      if (await canLaunchUrl(authUri)) {
        await launchUrl(authUri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Не вдалося відкрити браузер');
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Помилка авторизації: ${e.toString()}',
      );
    }
  }

  Future<void> _handleCallback(String code, String codeVerifier) async {
    if (_processingCallback) return;
    _processingCallback = true;
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    try {
      await _authService.exchangeCodeForTokens(
        code: code,
        codeVerifier: codeVerifier,
      );
      try {
        final userData = await _userRepo.getMe();
        _setUserFromData(userData);
        // After fresh login — offer to set up device security if nothing is configured
        checkAndPromptSecurity().ignore();
      } catch (e) {
        if (kDebugMode) print('[AUTH] getMe() failed: $e');
        final isCfBlock = e.toString().contains('CloudflareAccessBlocked');
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: isCfBlock
              ? 'Сервер заблоковано Cloudflare Access. Зверніться до адміністратора.'
              : 'Не вдалося завантажити профіль: ${e.toString()}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Помилка входу: ${e.toString()}',
      );
    } finally {
      _processingCallback = false;
      _codeVerifier = null;
    }
  }

  void _setUserFromData(Map<String, dynamic> data) {
    // Normalize API role names (server uses SUPERADMIN, TEACHER, etc.)
    final roles = (data['roles'] as List<dynamic>?)
            ?.map((r) => _normalizeRole(r.toString()))
            .toList() ??
        [];

    String? role;
    for (final r in [
      UserRole.superAdmin,
      UserRole.departmentHead,
      UserRole.instructor,
      UserRole.cadet,
    ]) {
      if (roles.contains(r)) {
        role = r;
        break;
      }
    }
    role ??= _normalizeRole(data['role'] as String? ?? UserRole.instructor);

    final firstName = data['name'] as String? ?? data['firstName'] as String? ?? '';
    final lastName = data['surname'] as String? ?? data['lastName'] as String? ?? '';
    final fullName = data['fullName'] as String? ??
        '$lastName $firstName'.trim();

    final group = data['group'] as Map<String, dynamic>?;
    final kafedra = data['kafedra'] as Map<String, dynamic>?;

    state = AuthState(
      status: AuthStatus.authenticated,
      userId: data['id']?.toString(),
      role: role,
      email: data['email'] as String?,
      fullName: fullName.isEmpty ? data['email'] as String? : fullName,
      rank: data['rank'] as String?,
      position: data['position'] as String?,
      groupName: group?['name'] as String? ?? data['groupName'] as String?,
      kafedraName: kafedra?['name'] as String? ?? data['kafedraName'] as String?,
      kafedraId: kafedra?['id'] as int? ?? data['kafedraId'] as int?,
      groupId: group?['id'] as int? ?? data['groupId'] as int?,
      facultyName: data['facultyName'] as String?,
    );
    _fcmService.subscribeToRoleTopic(role);
    // Зберігаємо профіль для офлайн-входу
    _authService.saveUserProfile(data).ignore();
    // Зберігаємо role/userId для фонових задач workmanager
    SharedPreferences.getInstance().then((p) {
      p.setString(AppConstants.userRoleKey, role ?? '');
      p.setString(AppConstants.userIdKey, data['id']?.toString() ?? '');
      final gId = group?['id'] ?? data['groupId'];
      if (gId != null) p.setString(AppConstants.groupIdKey, gId.toString());
    });
  }

  // Called only after fresh OAuth login — checks if device has any security
  // configured and prompts user to set one up if not.
  // Uses isDeviceSupported() (KeyguardManager.isDeviceSecure) which returns true
  // for ANY configured lock: PIN, pattern, password, or enrolled biometric.
  // This correctly handles tablets where face recognition is not in BiometricManager
  // but a device PIN is configured — canCheckBiometrics would return false there.
  Future<void> checkAndPromptSecurity() async {
    final bio = BiometricService();
    final pin = AppPinService();
    final isSecured = await bio.isDeviceSupported();
    final hasPin = await pin.hasPin();
    if (!isSecured && !hasPin) {
      state = state.copyWith(needsSecurityPrompt: true);
    }
  }

  void dismissSecurityPrompt() {
    state = state.copyWith(needsSecurityPrompt: false);
  }

  Future<void> logout() async {
    _fcmService.unsubscribeFromRoleTopic(state.role);

    // Зберігаємо токен до очищення
    String? refreshToken;
    try {
      final tokens = await _authService.getSavedTokens();
      refreshToken = tokens?.refreshToken;
    } catch (_) {}

    // Одразу очищаємо локальний стан — екран переходить на /login без затримки
    await _authService.clearTokens();
    await _authService.clearUserProfile();
    state = const AuthState(status: AuthStatus.unauthenticated);

    // Серверний logout у фоні (не блокуємо UI)
    if (refreshToken != null) {
      _authService.logout(refreshToken).ignore();
    }
  }

  // Called after device/biometric auth passes. Loads user data and sets authenticated.
  Future<bool> loginWithBiometric({String? savedRole}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final accessToken = await _authService.getValidAccessToken();
      if (accessToken != null) {
        try {
          final userData = await _userRepo.getMe();
          _setUserFromData(userData);
          return true;
        } catch (e) {
          if (_isNetworkError(e)) {
            final cached = await _authService.getCachedUserProfile();
            if (cached != null) {
              _setUserFromData(cached);
              return true;
            }
          }
          rethrow;
        }
      }

      // Токен прострочений і не вдалося оновити (офлайн) — спробуємо кешований профіль
      final cached = await _authService.getCachedUserProfile();
      if (cached != null) {
        _setUserFromData(cached);
        return true;
      }

      // dev fallback: mock login by saved role — тільки в debug-збірці
      if (kDebugMode && savedRole != null) {
        mockLogin(savedRole);
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('[AUTH] loginWithBiometric error: $e');
      final isCfBlock = e.toString().contains('CloudflareAccessBlocked');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: isCfBlock
            ? 'Сервер заблоковано Cloudflare Access.'
            : 'Не вдалося завантажити профіль.',
      );
      return false;
    }
    state = state.copyWith(status: AuthStatus.unauthenticated);
    return false;
  }

  static bool _isNetworkError(Object e) {
    if (e is DioException) {
      return e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout;
    }
    return false;
  }

  Future<String?> updateProfile({
    String? firstName,
    String? lastName,
    String? rank,
    String? position,
  }) async {
    final userId = state.userId;
    if (userId == null) return 'Немає даних користувача';

    final data = <String, dynamic>{};
    if (firstName != null) data['name'] = firstName;
    if (lastName != null) data['surname'] = lastName;
    if (rank != null) data['rank'] = rank;
    if (position != null) data['position'] = position;
    if (data.isEmpty) return null;

    try {
      final id = int.parse(userId);
      if (state.role == UserRole.cadet) {
        await _cadetsRepo.updateCadet(id, data);
      } else {
        await _teachersRepo.updateTeacher(id, data);
      }
      final fresh = await _userRepo.getMe();
      _setUserFromData(fresh);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  void mockLogin(String role) {
    final user = role == UserRole.cadet
        ? MockDataProvider.cadetUser
        : MockDataProvider.currentUser;
    state = AuthState(
      status: AuthStatus.authenticated,
      userId: user.id,
      role: role,
      email: user.email,
      fullName: user.fullName,
      rank: user.rank,
      position: user.position,
      groupName: user.groupName,
      kafedraName: user.kafedraName,
    );
    _fcmService.subscribeToRoleTopic(role);
  }

  static String _normalizeRole(String raw) {
    switch (raw) {
      case 'SUPERADMIN':  return UserRole.superAdmin;
      case 'TEACHER':     return UserRole.instructor;
      default:            return raw;
    }
  }

  String _generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel(
    ref.read(authServiceProvider),
    ref.read(userRepositoryProvider),
    ref.read(fcmServiceProvider),
    ref.read(cadetsRepositoryProvider),
    ref.read(teachersRepositoryProvider),
  );
});
