import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  // ── Change this to your computer's local IP address ──
  // Find it by running `ipconfig` on Windows — look for IPv4 Address
  // Example: 192.168.1.105
  static String get baseUrl {
  if (kIsWeb) return 'http://127.0.0.1:8000';
  if (kReleaseMode) return 'https://jibu-kenya-app.onrender.com';
  return 'http://192.168.1.88:8000';
}

  // Use this for Chrome web testing
  // static const String baseUrl = 'http://127.0.0.1:8000';

  // Use this for production
  // static const String baseUrl = 'https://your-app.up.railway.app';

  // Auth
  static const String register = '/api/users/register/';
  static const String login = '/api/users/login/';
  static const String tokenRefresh = '/api/users/token/refresh/';
  static const String profile = '/api/users/profile/';
  static const String allUsers = '/api/users/all/';

  // Reports
  static const String reports = '/api/reports/';
  static String reportDetail(int id) => '/api/reports/$id/';
  static const String reportStatus = '/api/reports/status/';
  static const String duplicates = '/api/reports/duplicates/';

  // Departments
  static const String departments = '/api/departments/';
  static String departmentDetail(int id) => '/api/departments/$id/';

  // Audit
  static const String audit = '/api/audit/';

  // Secure storage keys
  static const String accessTokenKey = 'jibu_access_token';
  static const String refreshTokenKey = 'jibu_refresh_token';
  static const String userRoleKey = 'jibu_user_role';
  static const String userIdKey = 'jibu_user_id';
  static const String userCountyKey = 'jibu_user_county';
}