class Appointment {
  final String id;
  final String name;
  final DateTime date;
  final String? time; // "HH:mm" or "hh:mm a"
  final bool isReminderEnabled;

  Appointment({
    required this.id,
    required this.name,
    required this.date,
    this.time,
    this.isReminderEnabled = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'time': time,
      'isReminderEnabled': isReminderEnabled,
    };
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      name: json['name'] as String,
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String?,
      isReminderEnabled: json['isReminderEnabled'] as bool? ?? false,
    );
  }
}
