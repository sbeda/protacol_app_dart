class VoiceAction {
  final String type;
  final String title;
  final String description;
  bool enabled;
  final dynamic data;

  VoiceAction({
    required this.type,
    required this.title,
    required this.description,
    required this.enabled,
    required this.data,
  });

  factory VoiceAction.fromJson(Map<String, dynamic> json) {
    return VoiceAction(
      type: json['type'] as String? ?? 'diary',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      data: json['data'],
    );
  }
}
