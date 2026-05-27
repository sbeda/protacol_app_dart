import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:protacol_app/screens/goals/goals_screen.dart';
import 'core/api/api_interceptor.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/habits/habits_screen.dart';
import 'widgets/app_shell.dart';
import 'theme/app_theme.dart';
import 'screens/diary/diary_screen.dart';

class ProtacolApp extends StatelessWidget {
  ProtacolApp({super.key});

  final GoRouter _router = GoRouter(
    navigatorKey: ApiInterceptor.navigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/home',
        pageBuilder: (_, state) => NoTransitionPage(
          child: AppShell(
            currentIndex: 0,
            title: 'Protacol',
            child: const HomeScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/habits',
        pageBuilder: (_, state) => NoTransitionPage(
          child: AppShell(
            currentIndex: 1,
            title: 'Привычки',
            child: const HabitsScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/goals',
        pageBuilder: (_, state) => NoTransitionPage(
          child: AppShell(
            currentIndex: 2,
            title: 'Цели',
            child: const GoalsScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/diary',
        pageBuilder: (_, state) => NoTransitionPage(
          child: AppShell(
            currentIndex: 3,
            title: 'Дневник',
            child: const DiaryScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/tasks',
        pageBuilder: (_, state) => NoTransitionPage(
          child: AppShell(
            currentIndex: 4,
            title: 'Задачи',
            child: const _PlaceholderScreen(title: 'Задачи'),
          ),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Protacol',
      theme: AppTheme.dark,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('$title — в разработке'));
  }
}
