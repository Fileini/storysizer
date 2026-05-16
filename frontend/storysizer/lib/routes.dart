import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:storysizer/screens/group_detail.dart';
import 'package:storysizer/screens/group_estimation_dashboard.dart';
import 'package:storysizer/screens/group_estimation_vote.dart';
import 'package:storysizer/screens/groups.dart';
import 'package:storysizer/screens/login.dart';
import 'package:storysizer/screens/menu.dart';
import 'package:storysizer/screens/history.dart';
import 'package:storysizer/screens/profile.dart';
import 'package:storysizer/screens/quick_sizer_name.dart';
import 'package:storysizer/screens/quick_sizer_questions.dart';
import 'package:storysizer/screens/estimation.dart';
import 'package:storysizer/screens/coming_soon.dart';
import 'package:storysizer/screens/logging_out.dart';
import 'package:storysizer/services/auth_service.dart';

class StszRoutes {
  final GoRouter router;

  StszRoutes()
      : router = GoRouter(
          refreshListenable: AuthService.instance.loginInfo,
          redirect: (context, state) {
            final loginInfo = AuthService.instance.loginInfo;
            if (!loginInfo.isInitialized) return null;
            final loc = state.matchedLocation;
            // Don't interfere while the user is being logged out or visiting
            // public informational routes.
            if (loc == '/logging-out') return null;
            if (loc.startsWith('/coming-soon')) return null;
            final loggedIn = loginInfo.isLoggedIn;
            final isLoggingIn = loc == '/';
            if (!loggedIn && !isLoggingIn) return '/';
            if (loggedIn && isLoggingIn) return '/home';
            return null;
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
              routes: [
                GoRoute(
                  path: ':groupId',
                  pageBuilder: (context, state) => _animatedPage(
                    state: state,
                    child: MenuScreen(
                      view: GroupDetailView(
                        groupId: state.pathParameters['groupId']!,
                      ),
                    ),
                  ),
                  routes: [
                    GoRoute(
                      path: 'estimation/:estimationId/vote',
                      pageBuilder: (context, state) => _animatedPage(
                        state: state,
                        child: MenuScreen(
                          view: GroupEstimationVoteView(
                            groupId: state.pathParameters['groupId']!,
                            estimationId: state.pathParameters['estimationId']!,
                          ),
                        ),
                      ),
                    ),
                    GoRoute(
                      path: 'estimation/:estimationId/dashboard',
                      pageBuilder: (context, state) => _animatedPage(
                        state: state,
                        child: MenuScreen(
                          view: GroupEstimationDashboardView(
                            groupId: state.pathParameters['groupId']!,
                            estimationId: state.pathParameters['estimationId']!,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: '/join-group',
              pageBuilder: (context, state) => _animatedPage(
                state: state,
                child: JoinGroupScreen(
                  token: state.uri.queryParameters['token'] ?? '',
                ),
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
              builder: (context, state) => MenuScreen(view: Builder(
                builder: (context) {
                  return NameInputScreen();
                }
              )),
              routes: [
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
                        name: state.pathParameters['name']!
                      )
                    ),
                  ),
                ),
                GoRoute(
                  path: 'estimation/:id',
                  pageBuilder: (context, state) => _animatedPage(
                    state: state,
                    child: MenuScreen(
                      view: EstimationView(id: state.pathParameters['id']!),
                    ),
                  ),
                ),
              ],
            ),
            GoRoute(
              name: 'coming-soon',
              path: '/coming-soon/:feature',
              builder: (context, state) => ComingSoonScreen(
                feature: state.pathParameters['feature'] ?? 'This',
              ),
            ),
            GoRoute(
              name: 'logging-out',
              path: '/logging-out',
              builder: (context, state) => const LoggingOutScreen(),
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
