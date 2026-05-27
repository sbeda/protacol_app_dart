import 'package:dio/dio.dart';
import '../models/diary_entry.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class DiaryService {
  final Dio _dio;
  DiaryService(this._dio);

  Future<List<DiaryEntry>> getAll() async {
    final response = await _dio.get('/diary/get-all');
    var data = response.data;

    if (data is String) {
      data = jsonDecode(data);
    }

    List? list;
    if (data is List) {
      list = data;
    } else if (data is Map<String, dynamic>) {
      final candidate =
          data['data'] ?? data['entries'] ?? data['result'] ?? data['items'];
      if (candidate is List) list = candidate;
    }

    if (list == null) {
      throw Exception('Unexpected diary response shape: $data');
    }

    return list
        .map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> create({required String text, required int mood}) async {
    final trimmed = text.trim();
    final title = trimmed.length > 20 ? trimmed.substring(0, 20) : trimmed;
    await _dio.post(
      '/diary/create',
      data: {'title': title, 'text': trimmed, 'mood': mood.toString()},
    );
  }

  Future<void> delete(int entryId) async {
    await _dio.post('/diary/delete', data: {'diary_entry_id': entryId});
  }
}
