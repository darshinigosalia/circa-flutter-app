import 'cycle_type.dart';

class OnboardingData {
  final CycleType? cycleType;
  final bool? isPregnant;
  final DateTime? lastPeriod;
  final bool? isFertile;
  final List<String>? hormones;
  final Map<String, dynamic>? anchor;
  final List<String>? symptomsToTrack;
  final bool? trackMeds;

  const OnboardingData({
    this.cycleType,
    this.isPregnant,
    this.lastPeriod,
    this.isFertile,
    this.hormones,
    this.anchor,
    this.symptomsToTrack,
    this.trackMeds,
  });

  OnboardingData copyWith({
    CycleType? cycleType,
    bool? isPregnant,
    DateTime? lastPeriod,
    bool? isFertile,
    List<String>? hormones,
    Map<String, dynamic>? anchor,
    List<String>? symptomsToTrack,
    bool? trackMeds,
  }) {
    return OnboardingData(
      cycleType: cycleType ?? this.cycleType,
      isPregnant: isPregnant ?? this.isPregnant,
      lastPeriod: lastPeriod ?? this.lastPeriod,
      isFertile: isFertile ?? this.isFertile,
      hormones: hormones ?? this.hormones,
      anchor: anchor ?? this.anchor,
      symptomsToTrack: symptomsToTrack ?? this.symptomsToTrack,
      trackMeds: trackMeds ?? this.trackMeds,
    );
  }
}
