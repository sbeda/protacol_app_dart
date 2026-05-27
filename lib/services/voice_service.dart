import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/dio_client.dart';
import '../models/voice_action.dart';

class TranscribeResult {
  final int? id;
  final String text;
  const TranscribeResult({required this.id, required this.text});
}

class AnalyzeResult {
  final List<VoiceAction> actions;
  final int mood;
  const AnalyzeResult({required this.actions, required this.mood});
}

class VoiceService {
  final Dio _dio;
  VoiceService(this._dio);

  Future<TranscribeResult> transcribe(File audioFile) async {
    final form = FormData.fromMap({
      'audio': await MultipartFile.fromFile(
        audioFile.path,
        filename: 'recording.m4a',
      ),
    });
    final response = await _dio.post(
      '/transcription/transcribe',
      data: form,
      options: Options(
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 5),
      ),
    );
    var data = response.data;
    if (data is String) data = jsonDecode(data);
    return TranscribeResult(
      id: (data['id'] as num?)?.toInt(),
      text: data['transcription_text'] as String? ?? '',
    );
  }

  Future<AnalyzeResult> analyze(String text) async {
    final response = await _dio.post(
      '/voice/analyze',
      data: {'text': text},
      options: Options(receiveTimeout: const Duration(minutes: 3)),
    );
    var data = response.data;
    if (data is String) data = jsonDecode(data);
    final actions = (data['actions'] as List? ?? [])
        .map((e) => VoiceAction.fromJson(e as Map<String, dynamic>))
        .toList();
    final mood = (data['mood']?['value'] as num?)?.toInt() ?? 4;
    return AnalyzeResult(actions: actions, mood: mood);
  }

  Future<void> execute({
    String? diaryText,
    required int mood,
    required List<dynamic> habits,
    required List<dynamic> goals,
  }) async {
    final response = await _dio.post(
      '/voice/execute',
      data: {
        'diary_text': diaryText,
        'mood': mood,
        'habits': habits,
        'goals': goals,
      },
      options: Options(receiveTimeout: const Duration(minutes: 2)),
    );
    var data = response.data;
    if (data is String) data = jsonDecode(data);
    if (data is Map && data['success'] != true) {
      throw Exception(data['error']?.toString() ?? 'Execute failed');
    }
  }
}

final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService(ref.read(dioProvider));
});
