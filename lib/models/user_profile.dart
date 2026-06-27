import 'tracking_track.dart';
import 'cycle_mode.dart';

class UserProfile {
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
  final CycleMode? mode;

  UserProfile({
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
      'mode': mode?.name,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
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
      mode: _parseMode(json['mode']),
    );
  }

  static CycleMode? _parseMode(String? val) {
    if (val == null) return null;
    for (final e in CycleMode.values) {
      if (e.name == val) return e;
    }
    return null;
  }

  UserProfile copyWith({
    TrackingTrack? track,
    DateTime? lastPeriod,
    int? cycleLengthInDays,
    bool? isFertile,
    bool? isPregnant,
    List<String>? hormones,
    Map<String, dynamic>? anchor,
    List<String>? symptomsToTrack,
    bool? trackMeds,
    CycleMode? mode,
  }) {
    return UserProfile(
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
