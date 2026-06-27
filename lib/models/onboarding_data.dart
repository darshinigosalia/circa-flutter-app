class OnboardingData {
  final String? track;
  final bool? pregnant;
  final DateTime? lastPeriod;
  final bool? fertile;
  final List<String>? hormones;
  final Map<String, dynamic>? anchor;
  final List<String>? symptomsToTrack;
  final bool? trackMeds;

  const OnboardingData({
    this.track,
    this.pregnant,
    this.lastPeriod,
    this.fertile,
    this.hormones,
    this.anchor,
    this.symptomsToTrack,
    this.trackMeds,
  });

  OnboardingData copyWith({
    String? track,
    bool? pregnant,
    DateTime? lastPeriod,
    bool? fertile,
    List<String>? hormones,
    Map<String, dynamic>? anchor,
    List<String>? symptomsToTrack,
    bool? trackMeds,
  }) {
    return OnboardingData(
      track: track ?? this.track,
      pregnant: pregnant ?? this.pregnant,
      lastPeriod: lastPeriod ?? this.lastPeriod,
      fertile: fertile ?? this.fertile,
      hormones: hormones ?? this.hormones,
      anchor: anchor ?? this.anchor,
      symptomsToTrack: symptomsToTrack ?? this.symptomsToTrack,
      trackMeds: trackMeds ?? this.trackMeds,
    );
  }
}
