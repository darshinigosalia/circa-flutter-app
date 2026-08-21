import 'cycle_type.dart';
import 'pregnancy_outcome.dart';

const Object _sentinel = Object();

class UserProfile {
  final CycleType cycleType;
  final DateTime? lastPeriod;
  final int cycleLengthInDays;
  final int periodLengthInDays;
  final bool showFertility;
  final bool isPregnant;
  
  // Non-pregnant / no-periods fields
  final List<String> hormones;
  final Map<String, dynamic>? anchor;
  final List<String> symptomsToTrack;
  final bool trackMeds;
  final PregnancyOutcome? pregnancyOutcome;

  UserProfile({
    required this.cycleType,
    this.lastPeriod,
    this.cycleLengthInDays = 28,
    this.periodLengthInDays = 4,
    required this.showFertility,
    this.isPregnant = false,
    this.hormones = const [],
    this.anchor,
    this.symptomsToTrack = const [],
    this.trackMeds = false,
    this.pregnancyOutcome,
  });

  Map<String, dynamic> toJson() {
    return {
      'cycleType': cycleType.name,
      'lastPeriod': lastPeriod?.toIso8601String(),
      'cycleLengthInDays': cycleLengthInDays,
      'periodLengthInDays': periodLengthInDays,
      'showFertility': showFertility,
      'isPregnant': isPregnant,
      'hormones': hormones,
      'anchor': anchor,
      'symptomsToTrack': symptomsToTrack,
      'trackMeds': trackMeds,
      'pregnancyOutcome': pregnancyOutcome?.name,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      cycleType: CycleType.values.byName(json['cycleType']),
      lastPeriod: json['lastPeriod'] != null ? DateTime.parse(json['lastPeriod']) : null,
      cycleLengthInDays: json['cycleLengthInDays'] ?? 28,
      periodLengthInDays: json['periodLengthInDays'] ?? 4,
      showFertility: json['showFertility'] ?? false,
      isPregnant: json['isPregnant'] ?? false,
      hormones: List<String>.from(json['hormones'] ?? []),
      anchor: json['anchor'] as Map<String, dynamic>?,
      symptomsToTrack: List<String>.from(json['symptomsToTrack'] ?? []),
      trackMeds: json['trackMeds'] ?? false,
      pregnancyOutcome: _parsePregnancyOutcome(json['pregnancyOutcome']),
    );
  }

  static PregnancyOutcome? _parsePregnancyOutcome(String? val) {
    if (val == null) return null;
    for (final e in PregnancyOutcome.values) {
      if (e.name == val) return e;
    }
    return null;
  }

  UserProfile copyWith({
    CycleType? cycleType,
    Object? lastPeriod = _sentinel,
    int? cycleLengthInDays,
    int? periodLengthInDays,
    bool? showFertility,
    bool? isPregnant,
    List<String>? hormones,
    Object? anchor = _sentinel,
    List<String>? symptomsToTrack,
    bool? trackMeds,
    Object? pregnancyOutcome = _sentinel,
  }) {
    return UserProfile(
      cycleType: cycleType ?? this.cycleType,
      lastPeriod: lastPeriod == _sentinel ? this.lastPeriod : (lastPeriod as DateTime?),
      cycleLengthInDays: cycleLengthInDays ?? this.cycleLengthInDays,
      periodLengthInDays: periodLengthInDays ?? this.periodLengthInDays,
      showFertility: showFertility ?? this.showFertility,
      isPregnant: isPregnant ?? this.isPregnant,
      hormones: hormones ?? this.hormones,
      anchor: anchor == _sentinel ? this.anchor : (anchor as Map<String, dynamic>?),
      symptomsToTrack: symptomsToTrack ?? this.symptomsToTrack,
      trackMeds: trackMeds ?? this.trackMeds,
      pregnancyOutcome: pregnancyOutcome == _sentinel ? this.pregnancyOutcome : (pregnancyOutcome as PregnancyOutcome?),
    );
  }
}
