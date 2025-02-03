import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:storysizer/screens/groups.dart';
import 'package:storysizer/screens/login.dart';
import 'package:storysizer/screens/menu.dart';
import 'package:storysizer/screens/mysizings.dart';
import 'package:storysizer/screens/profile.dart';
import 'package:storysizer/screens/quick_sizer.dart';
import 'package:storysizer/services/auth_service.dart';

class StszRoutes {
  final GoRouter router;

  StszRoutes() : router = GoRouter(
    debugLogDiagnostics: true,
    refreshListenable: AuthService.instance.loginInfo, // 🔥 Refresh automatico se cambia stato
    redirect: (context, state) {
      final loggedIn = AuthService.instance.loginInfo.isLoggedIn;
      final isLoggingIn = state.matchedLocation == '/';

      if (loggedIn == null) {
        return null; // 🔹 Non facciamo redirect se lo stato non è ancora determinato
      }

      if (!loggedIn && !isLoggingIn) return '/';  // 🔹 Se non loggato e non su '/', vai a login
      if (loggedIn && isLoggingIn) return '/home'; // 🔹 Se loggato e su '/', vai a home

      return null; // 🔹 Nessun cambiamento
    },
    routes: [
      GoRoute(
        name: 'login',
        path: '/',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        name: 'home',
        path: '/home',
        builder: (context, state) => const MenuScreen(),
        routes: [ // 👇 Aggiungiamo le sotto-route
         GoRoute(
            path: 'quick-size',
            pageBuilder: (context, state) => _animatedPage(
              state: state,
              child: const MenuScreen(selectedTab: 0),
            ),
          ),
          GoRoute(
            path: 'history',
            pageBuilder: (context, state) => _animatedPage(
              state: state,
              child: const MenuScreen(selectedTab: 1),
            ),
          ),
          GoRoute(
            path: 'groups',
            pageBuilder: (context, state) => _animatedPage(
              state: state,
              child: const MenuScreen(selectedTab: 2),
            ),
          ),
          GoRoute(
            path: 'profile',
            pageBuilder: (context, state) => _animatedPage(
              state: state,
              child: const MenuScreen(selectedTab: 3),
            ),
          ),
          
        ],
      ),
    ],
  );

  // Funzione per animare la transizione

}

Page<dynamic> _animatedPage({required GoRouterState state, required Widget child}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}