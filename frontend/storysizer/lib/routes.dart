import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:storysizer/screens/groups.dart';
import 'package:storysizer/screens/login.dart';
import 'package:storysizer/screens/menu.dart';
import 'package:storysizer/screens/mysizings.dart';
import 'package:storysizer/screens/profile.dart';
import 'package:storysizer/screens/quick_sizer_name.dart';
import 'package:storysizer/screens/quick_sizer_questions.dart';
import 'package:storysizer/services/auth_service.dart';

class StszRoutes {
  final GoRouter router;

  StszRoutes()
      : router = GoRouter(
          debugLogDiagnostics: true,
          refreshListenable: AuthService
              .instance.loginInfo, // 🔥 Refresh automatico se cambia stato
          redirect: (context, state) {
            final loggedIn = AuthService.instance.loginInfo.isLoggedIn;
            final isLoggingIn = state.matchedLocation == '/';

            if (loggedIn == null) {
              return null; // 🔹 Non facciamo redirect se lo stato non è ancora determinato
            }

            if (!loggedIn && !isLoggingIn)
              return '/'; // 🔹 Se non loggato e non su '/', vai a login
            if (loggedIn && isLoggingIn)
              return '/home'; // 🔹 Se loggato e su '/', vai a home

            return null; // 🔹 Nessun cambiamento
          },
          routes: [
            GoRoute(
              name: 'login',
              path: '/',
              builder: (context, state) => const LoginScreen(),
            ),
            GoRoute(
                  path: '/history',
                  pageBuilder: (context, state) => _animatedPage(
                    state: state,
                    child: const MenuScreen(view: HistoryView()),
                  ),
                ),
                GoRoute(
                  path: '/groups',
                  pageBuilder: (context, state) => _animatedPage(
                    state: state,
                    child: const MenuScreen(view: GroupsView()),
                  ),
                ),
                GoRoute(
                  path: '/profile',
                  pageBuilder: (context, state) => _animatedPage(
                    state: state,
                    child: const MenuScreen(view: ProfileScreen()),
                  ),
                ),
            GoRoute(
              name: 'home',
              path: '/home',
              builder: (context, state) =>  MenuScreen(view: Builder(
                builder: (context) {
                  return NameInputScreen();
                }
              )),
              routes: [
                // 👇 Aggiungiamo le sotto-route
                GoRoute(
                  path: 'sizer-name',
                  pageBuilder: (context, state) => _animatedPage(
                    state: state,
                    child: MenuScreen(view: NameInputScreen()),
                  ),
                ),
                GoRoute(
                    path: 'sizer-questions/:name',
                    pageBuilder: (context, state) => _animatedPage(
                        state: state,
                        child: MenuScreen(
                            view: QuickSizerQuestionsView(
                                name: state.pathParameters['name']!)))),
              ],
            ),
          ],
          errorBuilder: (context, state) {
            print("🚨 ERRORE NEL ROUTING! URL: ${state.uri}");
            return const ErrorScreen();
          },
        );

  // Funzione per animare la transizione
}

Page<dynamic> _animatedPage(
    {required GoRouterState state, required Widget child}) {
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

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.yellow, // 🔥 Sfondo giallo per gli errori di routing
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              "Oops! Qualcosa è andato storto...",
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                GoRouter.of(context).go('/'); // Torna alla home
              },
              child: const Text("Torna alla schermata principale"),
            ),
          ],
        ),
      ),
    );
  }
}
