import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'dart:ui';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorText;
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .login(_loginController.text.trim(), _passwordController.text);
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _errorText = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _LoginBackgroundPainter()),
          ),
          SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      _buildLogo(),
                      const SizedBox(height: 12),
                      const Text(
                        'Реализация 100% своего потенциала',
                        style: AppTextStyles.text15Thin,
                      ),
                      const SizedBox(height: 80),
                      _buildField(
                        label: 'Логин',
                        controller: _loginController,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),
                      _buildField(
                        label: 'Пароль',
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _login(),
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorText!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ],
                      const SizedBox(height: 32),
                      _buildLoginButton(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 5,
                  child: _buildBottomLinks(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Text.rich(
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
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: AppTextStyles.text14ExtraLight),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [AppColors.accent, AppColors.borderBlue],
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  textInputAction: textInputAction,
                  onSubmitted: onSubmitted,
                  style: AppTextStyles.text14ExtraLight,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.40),
            blurRadius: 35,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(28)),
              gradient: LinearGradient(
                begin: Alignment.bottomRight,
                end: Alignment.topLeft,
                colors: [AppColors.accent, AppColors.borderBlue],
              ),
            ),
            child: Material(
              color: AppColors.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(26),
              child: InkWell(
                onTap: _isLoading ? null : _login,
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  height: 56,
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('ВОЙТИ', style: AppTextStyles.extrabold),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {},
          child: const Text(
            'Забыли пароль?',
            style: AppTextStyles.text12Regular,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            width: 1,
            height: 12,
            color: AppColors.textPrimary.withOpacity(0.3),
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: const Text('Регистрация', style: AppTextStyles.text12Regular),
        ),
      ],
    );
  }
}

class _LoginBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * -0.02, h * 0.86)
      ..lineTo(w * 0.25, h * 0.73)
      ..lineTo(w * 0.52, h * 0.70)
      ..lineTo(w * 0.74, h * 0.52)
      ..lineTo(w * 0.95, h * 0.49)
      ..lineTo(w * 1.02, h * 0.43);

    final glow = Paint()
      ..color = AppColors.accent.withOpacity(0.45)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final line = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, glow);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(_LoginBackgroundPainter oldDelegate) => false;
}
