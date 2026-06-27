class CycleProfile {
  final String track;
  final DateTime? lastPeriod;
  final int cycleLength;
  final bool fertile;
  final bool pregnant;
  
  // Non-pregnant / no-periods fields
  final List<String> hormones;
  final Map<String, dynamic>? anchor;
  final List<String> symptomsToTrack;
  final bool trackMeds;
  final String? mode;

  CycleProfile({
    required this.track,
    this.lastPeriod,
    this.cycleLength = 28,
    required this.fertile,
    this.pregnant = false,
    this.hormones = const [],
    this.anchor,
    this.symptomsToTrack = const [],
    this.trackMeds = false,
    this.mode,
  });

  Map<String, dynamic> toJson() {
    return {
      'track': track,
      'lastPeriod': lastPeriod?.toIso8601String(),
      'cycleLength': cycleLength,
      'fertile': fertile,
      'pregnant': pregnant,
      'hormones': hormones,
      'anchor': anchor,
      'symptomsToTrack': symptomsToTrack,
      'trackMeds': trackMeds,
      'mode': mode,
    };
  }

  factory CycleProfile.fromJson(Map<String, dynamic> json) {
    return CycleProfile(
      track: json['track'],
      lastPeriod: json['lastPeriod'] != null ? DateTime.parse(json['lastPeriod']) : null,
      cycleLength: json['cycleLength'] ?? 28,
      fertile: json['fertile'] ?? false,
      pregnant: json['pregnant'] ?? false,
      hormones: List<String>.from(json['hormones'] ?? []),
      anchor: json['anchor'] as Map<String, dynamic>?,
      symptomsToTrack: List<String>.from(json['symptomsToTrack'] ?? []),
      trackMeds: json['trackMeds'] ?? false,
      mode: json['mode'],
    );
  }

  CycleProfile copyWith({
    String? track,
    DateTime? lastPeriod,
    int? cycleLength,
    bool? fertile,
    bool? pregnant,
    List<String>? hormones,
    Map<String, dynamic>? anchor,
    List<String>? symptomsToTrack,
    bool? trackMeds,
    String? mode,
  }) {
    return CycleProfile(
      track: track ?? this.track,
      lastPeriod: lastPeriod ?? this.lastPeriod,
      cycleLength: cycleLength ?? this.cycleLength,
      fertile: fertile ?? this.fertile,
      pregnant: pregnant ?? this.pregnant,
      hormones: hormones ?? this.hormones,
      anchor: anchor ?? this.anchor,
      symptomsToTrack: symptomsToTrack ?? this.symptomsToTrack,
      trackMeds: trackMeds ?? this.trackMeds,
      mode: mode ?? this.mode,
    );
  }
}
