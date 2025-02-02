import 'package:go_router/go_router.dart';
import 'package:storysizer/screens/login.dart';
import 'package:storysizer/screens/menu.dart';
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
      ),
    ],
  );
}
