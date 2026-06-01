class DiaryEntry {
  final int id;
  final String text;
  final int mood;
  final DateTime? createdAt;

  const DiaryEntry({
    required this.id,
    required this.text,
    required this.mood,
    required this.createdAt,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: (json['diary_entry_id'] as num).toInt(),
      text: json['text'] as String? ?? '',
      mood: int.tryParse(json['mood'].toString()) ?? 1,
      createdAt: _parseGoTime(json['created_at']),
    );
  }

  static DateTime? _parseGoTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) return DateTime.tryParse(raw);
    if (raw is Map && raw['Time'] is String) {
      return DateTime.tryParse(raw['Time'] as String);
    }
    return null;
  }

  String get emoji {
    switch (mood) {
      case 1:
        return '😊';
      case 2:
        return '😢';
      case 3:
        return '😠';
      case 4:
        return '🧘';
      case 5:
        return '😴';
      default:
        return '😴';
    }
  }

  String get formattedDate {
    final d = createdAt;
    if (d == null) return '';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }
}
