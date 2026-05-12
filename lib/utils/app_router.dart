import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/user/user_home_screen.dart';
import '../screens/user/user_profile_screen.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/admin/admin_books_screen.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/admin/admin_reports_screen.dart';
import '../utils/app_constants.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppConstants.loginRoute,
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final loc = state.matchedLocation;

      if (isLoading) return null;

      final isAuthRoute = loc == AppConstants.loginRoute ||
          loc == AppConstants.registerRoute;

      if (!isAuth && !isAuthRoute) return AppConstants.loginRoute;
      if (isAuth && isAuthRoute) {
        return authState.isAdmin
            ? AppConstants.adminHomeRoute
            : AppConstants.userHomeRoute;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppConstants.loginRoute,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.registerRoute,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppConstants.userHomeRoute,
        builder: (context, state) => const UserHomeScreen(),
        routes: [
          GoRoute(
            path: 'profile',
            builder: (context, state) => const UserProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppConstants.adminHomeRoute,
        builder: (context, state) => const AdminHomeScreen(),
        routes: [
          GoRoute(
            path: 'books',
            builder: (context, state) => const AdminBooksScreen(),
          ),
          GoRoute(
            path: 'users',
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: 'reports',
            builder: (context, state) => const AdminReportsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
