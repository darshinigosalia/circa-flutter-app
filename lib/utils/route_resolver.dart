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

Widget resolveHome(UserProfile? profile, [StorageService? storage]) {
  final activeStorage = storage ?? storageService;

  if (profile == null) {
    return IntroScreen(storage: activeStorage);
  }

  if (profile.pregnancyOutcome == PregnancyOutcome.postpartum) {
    return PostpartumHomeScreen(storage: activeStorage);
  }
  
  if (profile.pregnancyOutcome == PregnancyOutcome.recovery) {
    return RecoveryHomeScreen(storage: activeStorage);
  }

  if (profile.isPregnant) {
    if (profile.lastPeriod != null) {
      return PregnancyHomeScreen(storage: activeStorage);
    } else {
      return GestationDateScreen(
        data: OnboardingData(
          cycleType: profile.cycleType,
          isPregnant: profile.isPregnant,
          showFertility: profile.showFertility,
        ),
        storage: activeStorage,
      );
    }
  }

  if (profile.cycleType == CycleType.periods) {
    if (profile.lastPeriod != null) {
      return CycleHomeScreen(
        storage: activeStorage,
        data: OnboardingData(
          cycleType: profile.cycleType,
          lastPeriod: profile.lastPeriod,
          showFertility: profile.showFertility,
        ),
      );
    } else {
      return DateEntryScreen(
        data: OnboardingData(
          cycleType: profile.cycleType,
          showFertility: profile.showFertility,
        ),
        storage: activeStorage,
      );
    }
  }

  if (profile.cycleType == CycleType.noPeriods) {
    return HomeTrackingScreen(storage: activeStorage);
  }

  return IntroScreen(storage: activeStorage);
}
