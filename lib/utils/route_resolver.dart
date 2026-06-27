import 'package:flutter/material.dart';
import '../models/cycle_profile.dart';
import '../screens/coming_soon_screen.dart';
import '../screens/postpartum_home_screen.dart';
import '../screens/recovery_home_screen.dart';
import '../screens/pregnancy_home_screen.dart';
import '../screens/gestation_date_screen.dart';
import '../screens/cycle_home_screen.dart';
import '../screens/date_entry_screen.dart';
import '../screens/home_tracking_screen.dart';
import '../screens/intro_screen.dart';
import '../models/onboarding_data.dart';
import '../services/storage_service.dart';

Widget resolveHome(CycleProfile? profile) {
  if (profile == null) {
    return const IntroScreen();
  }

  if (profile.mode == 'postpartum') {
    return PostpartumHomeScreen(storage: storageService);
  }
  
  if (profile.mode == 'recovery') {
    return RecoveryHomeScreen(storage: storageService);
  }

  if (profile.pregnant) {
    if (profile.lastPeriod != null) {
      return PregnancyHomeScreen(storage: storageService);
    } else {
      return GestationDateScreen(data: OnboardingData(
        track: profile.track,
        pregnant: profile.pregnant,
        fertile: profile.fertile,
      ));
    }
  }

  if (profile.track == 'periods') {
    if (profile.lastPeriod != null) {
      return CycleHomeScreen(
        storage: storageService,
        data: OnboardingData(
          track: profile.track,
          lastPeriod: profile.lastPeriod,
          fertile: profile.fertile,
        ),
      );
    } else {
      return DateEntryScreen(data: OnboardingData(
        track: profile.track,
        fertile: profile.fertile,
      ));
    }
  }

  if (profile.track == 'noperiods') {
    return HomeTrackingScreen(storage: storageService);
  }

  return const IntroScreen();
}
