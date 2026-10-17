
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import 'routes.dart';

final router = GoRouter(
  initialLocation: Routes.home,
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: Routes.auth,
      builder: (context, state) => const AuthPage(),
    ),
  ],
);


