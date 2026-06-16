import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/reports/presentation/screens/home_screen.dart';
import '../../features/reports/presentation/screens/submit_report_screen.dart';
import '../../features/reports/presentation/screens/confirmation_screen.dart';
import '../../features/reports/presentation/screens/report_detail_screen.dart';
import '../../features/reports/presentation/screens/map_screen.dart';
import '../../features/reports/presentation/screens/all_reports_screen.dart';
import '../../features/reports/presentation/screens/profile_screen.dart';
import '../../features/reports/presentation/screens/edit_profile_screen.dart';
import '../../features/reports/data/models/report_model.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String submitReport = '/submit-report';
  static const String reportDetail = '/report/:id';
  static const String confirmation = '/confirmation';
  static const String map = '/map';
  static const String allReports = '/reports';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String editProfile = '/edit-profile';
}

/// Bridges Riverpod state changes to GoRouter without rebuilding
/// the GoRouter instance itself. Calling notifyListeners() tells
/// GoRouter to re-run `redirect` for the CURRENT location only —
/// it does NOT reset the navigation stack or recreate the router.
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      // Only refresh when something relevant to routing changed
      if (previous?.isAuthenticated != next.isAuthenticated ||
          previous?.isLoading != next.isLoading) {
        notifyListeners();
      }
    });
  }
}

/// IMPORTANT: this provider does NOT call ref.watch(authProvider).
/// It is created exactly once. Auth changes are propagated via
/// GoRouterRefreshNotifier instead, so the GoRouter instance —
/// and its navigation stack — never gets reset.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup ||
          state.matchedLocation == AppRoutes.forgotPassword ||
          state.matchedLocation == AppRoutes.splash;

      if (isLoading) return null;
      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;
      if (isLoggedIn &&
          isAuthRoute &&
          state.matchedLocation != AppRoutes.splash) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.submitReport,
        builder: (context, state) => const SubmitReportScreen(),
      ),
      GoRoute(
        path: AppRoutes.confirmation,
        builder: (context, state) {
          final report = state.extra as ReportModel?;
          return ConfirmationScreen(report: report);
        },
      ),
      GoRoute(
        path: AppRoutes.reportDetail,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          final report = state.extra as ReportModel?;
          return ReportDetailScreen(reportId: id, preloadedReport: report);
        },
      ),
      GoRoute(
        path: AppRoutes.map,
        builder: (context, state) => const MapScreen(),
      ),
      GoRoute(
        path: AppRoutes.allReports,
        builder: (context, state) => const AllReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});