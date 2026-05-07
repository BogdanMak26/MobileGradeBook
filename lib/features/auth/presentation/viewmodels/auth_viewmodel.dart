// lib/features/auth/presentation/viewmodels/auth_viewmodel.dart

import 'dart:convert';
import 'dart:math';
import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/api/repositories.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/utils/app_constants.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? role;
  final String? email;
  final String? fullName;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.userId,
    this.role,
    this.email,
    this.fullName,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? role,
    String? email,
    String? fullName,
    String? errorMessage,
  }) =>
      AuthState(
        status: status ?? this.status,
        userId: userId ?? this.userId,
        role: role ?? this.role,
        email: email ?? this.email,
        fullName: fullName ?? this.fullName,
        errorMessage: errorMessage,
      );

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthService _authService;
  final UserRepository _userRepo;
  String? _codeVerifier;
  bool _processingCallback = false;

  AuthViewModel(this._authService, this._userRepo)
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

  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final hasSession = await _authService.hasValidSession();
      if (hasSession) {
        final accessToken = await _authService.getValidAccessToken();
        if (accessToken != null) {
          final userData = await _userRepo.getMe();
          _setUserFromData(userData);
          return;
        }
      }
      state = state.copyWith(status: AuthStatus.unauthenticated);
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
      } catch (e) {
        print('[AUTH] getMe() failed: $e');
        state = AuthState(
          status: AuthStatus.authenticated,
          userId: 'unknown',
          role: UserRole.instructor,
          email: '',
          fullName: 'Користувач',
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
    final roles = (data['roles'] as List<dynamic>?)
            ?.map((r) => r.toString())
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
    role ??= data['role'] as String? ?? UserRole.instructor;

    final firstName = data['firstName'] as String? ?? '';
    final lastName = data['lastName'] as String? ?? '';
    final fullName = data['fullName'] as String? ??
        '$lastName $firstName'.trim();

    state = AuthState(
      status: AuthStatus.authenticated,
      userId: data['id']?.toString(),
      role: role,
      email: data['email'] as String?,
      fullName: fullName.isEmpty ? data['email'] as String? : fullName,
    );
  }

  Future<void> logout() async {
    // Зберігаємо токен до очищення
    String? refreshToken;
    try {
      final tokens = await _authService.getSavedTokens();
      refreshToken = tokens?.refreshToken;
    } catch (_) {}

    // Одразу очищаємо локальний стан — екран переходить на /login без затримки
    await _authService.clearTokens();
    state = const AuthState(status: AuthStatus.unauthenticated);

    // Серверний logout у фоні (не блокуємо UI)
    if (refreshToken != null) {
      _authService.logout(refreshToken).ignore();
    }
  }

  // Вхід після успішної біометричної аутентифікації
  Future<bool> loginWithBiometric({String? savedRole}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      // Спочатку перевіряємо реальну сесію (refresh token)
      final hasSession = await _authService.hasValidSession();
      if (hasSession) {
        await checkAuthStatus();
        if (state.isAuthenticated) return true;
      }
      // Fallback: mock-вхід за збереженою роллю (dev режим)
      if (savedRole != null) {
        mockLogin(savedRole);
        return true;
      }
    } catch (_) {}
    state = state.copyWith(status: AuthStatus.unauthenticated);
    return false;
  }

  void updateProfile({String? fullName}) {
    if (fullName != null) {
      state = state.copyWith(fullName: fullName);
    }
  }

  void mockLogin(String role) {
    final user = role == 'CADET'
        ? MockDataProvider.cadetUser
        : MockDataProvider.currentUser;
    state = AuthState(
      status: AuthStatus.authenticated,
      userId: user.id,
      role: role,
      email: user.email,
      fullName: user.fullName,
    );
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
  );
});
