import 'package:flutter/material.dart';
import '../models/cycle_profile.dart';
import '../models/tracking_track.dart';
import '../screens/home/postpartum_home_screen.dart';
import '../screens/home/recovery_home_screen.dart';
import '../screens/home/pregnancy_home_screen.dart';
import '../screens/onboarding/gestation_date_screen.dart';
import '../screens/home/cycle_home_screen.dart';
import '../screens/onboarding/date_entry_screen.dart';
import '../screens/home/home_tracking_screen.dart';
import '../screens/onboarding/intro_screen.dart';
import '../models/onboarding_data.dart';
import '../services/storage_service.dart';

import '../models/cycle_mode.dart';

Widget resolveHome(CycleProfile? profile) {
  if (profile == null) {
    return const IntroScreen();
  }

  if (profile.mode == CycleMode.postpartum) {
    return PostpartumHomeScreen(storage: storageService);
  }
  
  if (profile.mode == CycleMode.recovery) {
    return RecoveryHomeScreen(storage: storageService);
  }

  if (profile.isPregnant) {
    if (profile.lastPeriod != null) {
      return PregnancyHomeScreen(storage: storageService);
    } else {
      return GestationDateScreen(data: OnboardingData(
        track: profile.track,
        isPregnant: profile.isPregnant,
        isFertile: profile.isFertile,
      ));
    }
  }

  if (profile.track == TrackingTrack.periods) {
    if (profile.lastPeriod != null) {
      return CycleHomeScreen(
        storage: storageService,
        data: OnboardingData(
          track: profile.track,
          lastPeriod: profile.lastPeriod,
          isFertile: profile.isFertile,
        ),
      );
    } else {
      return DateEntryScreen(data: OnboardingData(
        track: profile.track,
        isFertile: profile.isFertile,
      ));
    }
  }

  if (profile.track == TrackingTrack.noperiods) {
    return HomeTrackingScreen(storage: storageService);
  }

  return const IntroScreen();
}
