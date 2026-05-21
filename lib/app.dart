import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/api/api_interceptor.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

class ProtacolApp extends StatelessWidget {
  ProtacolApp({super.key});

  final GoRouter _router = GoRouter(
    navigatorKey: ApiInterceptor.navigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Protacol',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(),
      routerConfig: _router,
    );
  }
}
