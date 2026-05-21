import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/dio_client.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(dio: ref.read(dioProvider));
});

class AuthService {
  final Dio dio;

  AuthService({required this.dio});

  Future<String> login(String login, String password) async {
    try {
      final response = await dio.post(
        '/auth/signin',
        data: {'identifier': login, 'password': password},
      );
      return response.data['token'] as String;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Ошибка сети';
      throw Exception(message);
    }
  }
}
