import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/record_list_screen.dart';
import 'screens/record_form_screen.dart';
import 'screens/tag_manage_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/backup_screen.dart';
import 'widgets/scaffold_with_nav_bar.dart';

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return ScaffoldWithNavBar(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/records',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: RecordListScreen(),
          ),
        ),
        GoRoute(
          path: '/stats',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: StatsScreen(),
          ),
        ),
        GoRoute(
          path: '/favorites',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: FavoritesScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/records/new',
      builder: (context, state) => RecordFormScreen(
        initialShopName: state.uri.queryParameters['shop'],
        initialDishName: state.uri.queryParameters['dish'],
      ),
    ),
    GoRoute(
      path: '/records/edit/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return RecordFormScreen(recordId: id);
      },
    ),
    GoRoute(
      path: '/tags',
      builder: (context, state) => const TagManageScreen(),
    ),
    GoRoute(
      path: '/budget',
      builder: (context, state) => const BudgetScreen(),
    ),
    GoRoute(
      path: '/backup',
      builder: (context, state) => const BackupScreen(),
    ),
  ],
);