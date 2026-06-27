class Medication {
  final String id;
  final String name;
  final String frequency; // 'everyday' | 'every_week' | 'specific_days' | 'as_needed'
  final List<int> specificDays; // 1..7 (Mon..Sun)
  final List<String> times; // "HH:mm" strings
  final bool isReminderEnabled;

  Medication({
    required this.id,
    required this.name,
    required this.frequency,
    this.specificDays = const [],
    this.times = const [],
    this.isReminderEnabled = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'frequency': frequency,
      'specificDays': specificDays,
      'times': times,
      'isReminderEnabled': isReminderEnabled,
    };
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String,
      name: json['name'] as String,
      frequency: json['frequency'] as String,
      specificDays: (json['specificDays'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      times: (json['times'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      isReminderEnabled: json['isReminderEnabled'] as bool? ?? false,
    );
  }
}
