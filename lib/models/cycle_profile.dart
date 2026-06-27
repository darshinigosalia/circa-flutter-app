import 'tracking_track.dart';

class CycleProfile {
  final TrackingTrack track;
  final DateTime? lastPeriod;
  final int cycleLengthInDays;
  final bool isFertile;
  final bool isPregnant;
  
  // Non-pregnant / no-periods fields
  final List<String> hormones;
  final Map<String, dynamic>? anchor;
  final List<String> symptomsToTrack;
  final bool trackMeds;
  final String? mode;

  CycleProfile({
    required this.track,
    this.lastPeriod,
    this.cycleLengthInDays = 28,
    required this.isFertile,
    this.isPregnant = false,
    this.hormones = const [],
    this.anchor,
    this.symptomsToTrack = const [],
    this.trackMeds = false,
    this.mode,
  });

  Map<String, dynamic> toJson() {
    return {
      'track': track.name,
      'lastPeriod': lastPeriod?.toIso8601String(),
      'cycleLength': cycleLengthInDays,
      'fertile': isFertile,
      'pregnant': isPregnant,
      'hormones': hormones,
      'anchor': anchor,
      'symptomsToTrack': symptomsToTrack,
      'trackMeds': trackMeds,
      'mode': mode,
    };
  }

  factory CycleProfile.fromJson(Map<String, dynamic> json) {
    return CycleProfile(
      track: TrackingTrack.values.firstWhere(
        (e) => e.name == json['track'],
        orElse: () => TrackingTrack.periods,
      ),
      lastPeriod: json['lastPeriod'] != null ? DateTime.parse(json['lastPeriod']) : null,
      cycleLengthInDays: json['cycleLength'] ?? 28,
      isFertile: json['fertile'] ?? false,
      isPregnant: json['pregnant'] ?? false,
      hormones: List<String>.from(json['hormones'] ?? []),
      anchor: json['anchor'] as Map<String, dynamic>?,
      symptomsToTrack: List<String>.from(json['symptomsToTrack'] ?? []),
      trackMeds: json['trackMeds'] ?? false,
      mode: json['mode'],
    );
  }

  CycleProfile copyWith({
    TrackingTrack? track,
    DateTime? lastPeriod,
    int? cycleLengthInDays,
    bool? isFertile,
    bool? isPregnant,
    List<String>? hormones,
    Map<String, dynamic>? anchor,
    List<String>? symptomsToTrack,
    bool? trackMeds,
    String? mode,
  }) {
    return CycleProfile(
      track: track ?? this.track,
      lastPeriod: lastPeriod ?? this.lastPeriod,
      cycleLengthInDays: cycleLengthInDays ?? this.cycleLengthInDays,
      isFertile: isFertile ?? this.isFertile,
      isPregnant: isPregnant ?? this.isPregnant,
      hormones: hormones ?? this.hormones,
      anchor: anchor ?? this.anchor,
      symptomsToTrack: symptomsToTrack ?? this.symptomsToTrack,
      trackMeds: trackMeds ?? this.trackMeds,
      mode: mode ?? this.mode,
    );
  }
}
