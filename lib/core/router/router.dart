import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_page.dart';
import '../../features/clearance/presentation/clearance_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/expenses/presentation/expenses_page.dart';
import '../../features/milestones/presentation/milestones_page.dart';
import '../../features/receivables/presentation/receivables_page.dart';
import '../navigation/app_navigation_shell.dart';
import 'routes.dart';

/// Top-level application routing table configured with a stateful navigation shell.
final router = GoRouter(
  initialLocation: Routes.home,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppNavigationShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.home,
              builder: (context, state) => const DashboardPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.clearance,
              builder: (context, state) => const ClearancePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.receivables,
              builder: (context, state) => const ReceivablesPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.milestones,
              builder: (context, state) => const MilestonesPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.expenses,
              builder: (context, state) => const ExpensesPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: Routes.auth,
      builder: (context, state) => const AuthPage(),
    ),
  ],
);
