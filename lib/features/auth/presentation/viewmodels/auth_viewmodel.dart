// lib/features/auth/presentation/viewmodels/auth_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/mock/mock_data.dart';

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
    this.userId, this.role, this.email, this.fullName, this.errorMessage,
  });

  AuthState copyWith({AuthStatus? status, String? userId, String? role,
    String? email, String? fullName, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      errorMessage: errorMessage,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthViewModel extends StateNotifier<AuthState> {
  AuthViewModel() : super(const AuthState());

  /// Мок-логін для розробки UI (без сервера)
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

  Future<void> checkAuthStatus() async {
    // TODO: реальна перевірка токенів (після підключення Keycloak)
    state = state.copyWith(status: AuthStatus.unauthenticated);
  }

  Future<void> login() async {
    // TODO: реальний Keycloak PKCE login
    mockLogin('INSTRUCTOR');
  }

  Future<void> logout() async {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) => AuthViewModel());
