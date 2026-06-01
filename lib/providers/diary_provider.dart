import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/diary_entry.dart';
import '../services/diary_service.dart';
import '../core/api/dio_client.dart';

final diaryServiceProvider = Provider<DiaryService>((ref) {
  // adjust to match how Dio is exposed in your project
  final dio = ref.read(dioProvider);
  return DiaryService(dio);
});

final diaryProvider = AsyncNotifierProvider<DiaryNotifier, List<DiaryEntry>>(
  DiaryNotifier.new,
);

class DiaryNotifier extends AsyncNotifier<List<DiaryEntry>> {
  @override
  Future<List<DiaryEntry>> build() async {
    return ref.read(diaryServiceProvider).getAll();
  }

  Future<void> createEntry({required String text, required int mood}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(diaryServiceProvider).create(text: text, mood: mood);
      return ref.read(diaryServiceProvider).getAll();
    });
  }

  Future<void> deleteEntry(int entryId) async {
    final current = state.value ?? [];
    state = AsyncValue.data(current.where((e) => e.id != entryId).toList());
    try {
      await ref.read(diaryServiceProvider).delete(entryId);
    } catch (e, st) {
      state = AsyncValue.data(current);
      state = AsyncValue.error(e, st);
    }
  }
}
