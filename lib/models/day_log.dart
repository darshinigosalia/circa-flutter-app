class CustomSymptom {
  final String name;
  final String detail;

  CustomSymptom({required this.name, required this.detail});

  Map<String, dynamic> toJson() => {
    'name': name,
    'detail': detail,
  };

  factory CustomSymptom.fromJson(Map<String, dynamic> json) {
    return CustomSymptom(
      name: json['name'],
      detail: json['detail'],
    );
  }
}

class DayLog {
  final DateTime date;           // Midnight-normalized
  final DateTime loggedAt;       // Timestamp of save
  final bool periodStarted;
  final bool periodEnded;
  final String? bleedingFlowLevel;
  final String? bleedingFlowColour;
  final String? dischargeAmount;
  final String? dischargeColour;
  final Map<String, String> symptoms; 
  final List<CustomSymptom> customSymptoms;
  final String notes;
  final bool? intercourseProtected;
  final String? contraceptionType;
  final bool anomalousCycle;
  final String? anomalousReason;
  final double? basalBodyTemperature;

  DayLog({
    required this.date,
    required this.loggedAt,
    this.periodStarted = false,
    this.periodEnded = false,
    this.bleedingFlowLevel,
    this.bleedingFlowColour,
    this.dischargeAmount,
    this.dischargeColour,
    this.symptoms = const {},
    this.customSymptoms = const [],
    this.notes = '',
    this.intercourseProtected,
    this.contraceptionType,
    this.anomalousCycle = false,
    this.anomalousReason,
    this.basalBodyTemperature,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'loggedAt': loggedAt.toIso8601String(),
      'periodStarted': periodStarted,
      'periodEnded': periodEnded,
      'bleedingFlowLevel': bleedingFlowLevel,
      'bleedingFlowColour': bleedingFlowColour,
      'dischargeAmount': dischargeAmount,
      'dischargeColour': dischargeColour,
      'symptoms': symptoms,
      'customSymptoms': customSymptoms.map((e) => e.toJson()).toList(),
      'notes': notes,
      'intercourseProtected': intercourseProtected,
      'contraceptionType': contraceptionType,
      'anomalousCycle': anomalousCycle,
      'anomalousReason': anomalousReason,
      'basalBodyTemperature': basalBodyTemperature,
    };
  }

  factory DayLog.fromJson(Map<String, dynamic> json) {
    return DayLog(
      date: DateTime.parse(json['date']),
      loggedAt: DateTime.parse(json['loggedAt']),
      periodStarted: json['periodStarted'] ?? false,
      periodEnded: json['periodEnded'] ?? false,
      bleedingFlowLevel: json['bleedingFlowLevel'],
      bleedingFlowColour: json['bleedingFlowColour'],
      dischargeAmount: json['dischargeAmount'],
      dischargeColour: json['dischargeColour'],
      symptoms: Map<String, String>.from(json['symptoms'] ?? {}),
      customSymptoms: (json['customSymptoms'] as List<dynamic>?)
          ?.map((e) => CustomSymptom.fromJson(e))
          .toList() ?? [],
      notes: json['notes'] ?? '',
      intercourseProtected: json['intercourseProtected'],
      contraceptionType: json['contraceptionType'],
      anomalousCycle: json['anomalousCycle'] ?? false,
      anomalousReason: json['anomalousReason'],
      basalBodyTemperature: json['basalBodyTemperature']?.toDouble(),
    );
  }

  DayLog copyWith({
    DateTime? date,
    DateTime? loggedAt,
    bool? periodStarted,
    bool? periodEnded,
    String? bleedingFlowLevel,
    String? bleedingFlowColour,
    String? dischargeAmount,
    String? dischargeColour,
    Map<String, String>? symptoms,
    List<CustomSymptom>? customSymptoms,
    String? notes,
    bool? intercourseProtected,
    String? contraceptionType,
    bool? anomalousCycle,
    String? anomalousReason,
    double? basalBodyTemperature,
  }) {
    return DayLog(
      date: date ?? this.date,
      loggedAt: loggedAt ?? this.loggedAt,
      periodStarted: periodStarted ?? this.periodStarted,
      periodEnded: periodEnded ?? this.periodEnded,
      bleedingFlowLevel: bleedingFlowLevel ?? this.bleedingFlowLevel,
      bleedingFlowColour: bleedingFlowColour ?? this.bleedingFlowColour,
      dischargeAmount: dischargeAmount ?? this.dischargeAmount,
      dischargeColour: dischargeColour ?? this.dischargeColour,
      symptoms: symptoms ?? this.symptoms,
      customSymptoms: customSymptoms ?? this.customSymptoms,
      notes: notes ?? this.notes,
      intercourseProtected: intercourseProtected ?? this.intercourseProtected,
      contraceptionType: contraceptionType ?? this.contraceptionType,
      anomalousCycle: anomalousCycle ?? this.anomalousCycle,
      anomalousReason: anomalousReason ?? this.anomalousReason,
      basalBodyTemperature: basalBodyTemperature ?? this.basalBodyTemperature,
    );
  }
}
