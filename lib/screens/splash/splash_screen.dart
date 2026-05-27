import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await ref.read(authProvider.notifier).checkAuth();
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final authState = ref.read(authProvider);
    if (authState == AuthState.authenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text.rich(
          TextSpan(
            children: const [
              TextSpan(text: 'prot'),
              TextSpan(
                text: 'a',
                style: TextStyle(color: AppColors.accent),
              ),
              TextSpan(text: 'col'),
            ],
          ),
          style: AppTextStyles.display60,
        ),
      ),
    );
  }
}
