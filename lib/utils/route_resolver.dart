import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/cycle_type.dart';
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

import '../models/pregnancy_outcome.dart';

Widget resolveHome(UserProfile? profile) {
  if (profile == null) {
    return const IntroScreen();
  }

  if (profile.pregnancyOutcome == PregnancyOutcome.postpartum) {
    return PostpartumHomeScreen(storage: storageService);
  }
  
  if (profile.pregnancyOutcome == PregnancyOutcome.recovery) {
    return RecoveryHomeScreen(storage: storageService);
  }

  if (profile.isPregnant) {
    if (profile.lastPeriod != null) {
      return PregnancyHomeScreen(storage: storageService);
    } else {
      return GestationDateScreen(data: OnboardingData(
        cycleType: profile.cycleType,
        isPregnant: profile.isPregnant,
        isFertile: profile.isFertile,
      ));
    }
  }

  if (profile.cycleType == CycleType.periods) {
    if (profile.lastPeriod != null) {
      return CycleHomeScreen(
        storage: storageService,
        data: OnboardingData(
          cycleType: profile.cycleType,
          lastPeriod: profile.lastPeriod,
          isFertile: profile.isFertile,
        ),
      );
    } else {
      return DateEntryScreen(data: OnboardingData(
        cycleType: profile.cycleType,
        isFertile: profile.isFertile,
      ));
    }
  }

  if (profile.cycleType == CycleType.noPeriods) {
    return HomeTrackingScreen(storage: storageService);
  }

  return const IntroScreen();
}
