// lib/core/utils/app_constants.dart

class AppConstants {
  AppConstants._();

  // Server
  static const String baseUrl = 'https://gradebook.viti.edu.ua/api';
  static const String authUrl = 'https://auth.viti.edu.ua';
  static const String keycloakRealm = 'grade-book';
  static const String keycloakClientId = 'grade-book-mobile';
  static const String keycloakRedirectUri = 'com.viti.gradebook://callback';

  // Keycloak OIDC endpoints
  static const String issuerUrl = '$authUrl/realms/$keycloakRealm';
  static const String authorizationEndpoint =
      '$authUrl/realms/$keycloakRealm/protocol/openid-connect/auth';
  static const String tokenEndpoint =
      '$authUrl/realms/$keycloakRealm/protocol/openid-connect/token';
  static const String userInfoEndpoint =
      '$authUrl/realms/$keycloakRealm/protocol/openid-connect/userinfo';
  static const String endSessionEndpoint =
      '$authUrl/realms/$keycloakRealm/protocol/openid-connect/logout';

  // Scopes
  static const List<String> scopes = ['openid', 'profile', 'email', 'roles'];

  // Sync
  static const int syncIntervalMinutes = 15;
  static const int maxRetryAttempts = 3;
  static const int connectionTimeoutSeconds = 30;

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String idTokenKey = 'id_token';
  static const String userRoleKey = 'user_role';
  static const String userIdKey = 'user_id';
}

class UserRole {
  static const String cadet = 'CADET';
  static const String instructor = 'INSTRUCTOR';
  static const String departmentHead = 'DEPARTMENT_HEAD';
  static const String facultyEducation = 'FACULTY_EDUCATION_OFFICE';
  static const String instituteEducation = 'INSTITUTE_EDUCATION_OFFICE';
  static const String superAdmin = 'SUPER_ADMIN';

  static String displayName(String role) {
    switch (role) {
      case cadet:
        return 'Курсант';
      case instructor:
        return 'Викладач';
      case departmentHead:
        return 'Начальник кафедри';
      case facultyEducation:
        return 'Навч. відділ факультету';
      case instituteEducation:
        return 'Навч. відділ інституту';
      case superAdmin:
        return 'Суперадмін';
      default:
        return role;
    }
  }
}
