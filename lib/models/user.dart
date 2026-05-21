class User {
  final int id;
  final String login;
  final String? email;
  final int? subscriptionPlan;
  final DateTime? subscriptionEndDate;
  final String theme;
  final String accentColor;
  final String backgroundType;
  final String backgroundValue;
  final String cardColor;
  final int cardOpacity;
  final bool useDescriptionsInReport;
  final bool useCustomAccent;
  final bool useCustomBackground;
  final bool useCustomCardColor;

  User({
    required this.id,
    required this.login,
    this.email,
    this.subscriptionPlan,
    this.subscriptionEndDate,
    this.theme = 'dark',
    this.accentColor = '#00942c',
    this.backgroundType = 'image',
    this.backgroundValue = '/static/wallpapers/default.jpg',
    this.cardColor = '#13100c',
    this.cardOpacity = 60,
    this.useDescriptionsInReport = false,
    this.useCustomAccent = false,
    this.useCustomBackground = false,
    this.useCustomCardColor = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      login: json['login'] as String,
      email: json['email'] as String?,
      subscriptionPlan: json['subscription_plan'] as int?,
      subscriptionEndDate: json['subscription_end_date'] != null
          ? DateTime.parse(json['subscription_end_date'] as String)
          : null,
      theme: json['theme'] as String? ?? 'dark',
      accentColor: json['accent_color'] as String? ?? '#00942c',
      backgroundType: json['background_type'] as String? ?? 'image',
      backgroundValue: json['background_value'] as String? ?? '',
      cardColor: json['card_color'] as String? ?? '#13100c',
      cardOpacity: json['card_opacity'] as int? ?? 60,
      useDescriptionsInReport:
          json['use_descriptions_in_report'] as bool? ?? false,
      useCustomAccent: json['use_custom_accent'] as bool? ?? false,
      useCustomBackground: json['use_custom_background'] as bool? ?? false,
      useCustomCardColor: json['use_custom_card_color'] as bool? ?? false,
    );
  }

  bool get hasActiveSubscription {
    if (subscriptionEndDate == null) return false;
    return subscriptionEndDate!.isAfter(DateTime.now());
  }
}
