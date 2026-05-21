import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/secure_storage.dart';
import '../services/auth_service.dart';

enum AuthState { initial, authenticated, unauthenticated }

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState.initial);

  Future<void> checkAuth() async {
    final token = await SecureStorage.getToken();
    state = token != null ? AuthState.authenticated : AuthState.unauthenticated;
  }

  Future<String> login(String login, String password) async {
    final token = await _authService.login(login, password);
    await SecureStorage.saveToken(token);
    state = AuthState.authenticated;
    return token;
  }

  Future<void> logout() async {
    await SecureStorage.deleteToken();
    state = AuthState.unauthenticated;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});
