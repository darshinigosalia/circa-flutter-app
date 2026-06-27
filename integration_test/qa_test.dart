import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:circa_app/main.dart' as app;
import 'package:circa_app/services/storage_service.dart';
import 'package:circa_app/utils/app_clock.dart';
import 'package:circa_app/models/cycle_profile.dart';
import 'package:circa_app/models/tracking_track.dart';
import 'package:circa_app/models/day_log.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    AppClock.reset();
  });

  Future<void> clearAndInitHive() async {
    await Hive.initFlutter();
    // Close any open boxes first to avoid conflicts
    if (Hive.isBoxOpen('logs')) await Hive.box<String>('logs').clear();
    if (Hive.isBoxOpen('profile')) await Hive.box<String>('profile').clear();
    if (Hive.isBoxOpen('medications')) await Hive.box<String>('medications').clear();
    if (Hive.isBoxOpen('appointments')) await Hive.box<String>('appointments').clear();
    if (Hive.isBoxOpen('settings')) await Hive.box<dynamic>('settings').clear();

    // Ensure boxes are open
    if (!Hive.isBoxOpen('logs')) await Hive.openBox<String>('logs');
    if (!Hive.isBoxOpen('profile')) await Hive.openBox<String>('profile');
    if (!Hive.isBoxOpen('medications')) await Hive.openBox<String>('medications');
    if (!Hive.isBoxOpen('appointments')) await Hive.openBox<String>('appointments');
    if (!Hive.isBoxOpen('settings')) await Hive.openBox<dynamic>('settings');
    await storageService.init();
  }

  testWidgets('QA Pass Section 1', (WidgetTester tester) async {
    // --- Case 1.1: Local midnight defines "today" ---
    await clearAndInitHive();
    final day1 = DateTime(2024, 5, 10, 23, 58); // 11:58 PM
    AppClock.setFixedTime(day1);

    // Use track: TrackingTrack.periods to match route_resolver.dart
    await storageService.saveProfile(CycleProfile(
      track: TrackingTrack.periods,
      isFertile: true,
      lastPeriod: DateTime(2024, 5, 10),
    ));
    await storageService.saveLog(DayLog(
      date: DateTime(2024, 5, 10),
      loggedAt: day1,
      symptoms: const {'Cramps': 'Mild'},
    ));

    await tester.pumpWidget(const app.CircaApp());
    await tester.pumpAndSettle();

    // Change clock to 12:02 AM next day
    AppClock.setFixedTime(DateTime(2024, 5, 11, 0, 2));
    await tester.pumpWidget(const app.CircaApp());
    await tester.pumpAndSettle();

    print('SCREENSHOT_READY: 1.1_midnight_rollover');
    await Future.delayed(const Duration(seconds: 3));

    // --- Case 1.4: Manual clock rewind ---
    await clearAndInitHive();
    final baseDay = DateTime(2024, 6, 1);
    AppClock.setFixedTime(baseDay);
    await storageService.saveProfile(CycleProfile(
      track: TrackingTrack.periods,
      isFertile: true,
      lastPeriod: baseDay,
    ));

    // Log something 10 days in the future
    final futureDay = baseDay.add(const Duration(days: 10));
    AppClock.setFixedTime(futureDay);
    await storageService.saveLog(DayLog(
      date: futureDay,
      loggedAt: futureDay,
      symptoms: const {'Headache': 'Mild'},
    ));

    // Rewind clock back to baseDay
    AppClock.setFixedTime(baseDay);
    await tester.pumpWidget(const app.CircaApp());
    await tester.pumpAndSettle();

    print('SCREENSHOT_READY: 1.4_clock_rewind');
    await Future.delayed(const Duration(seconds: 3));

    // --- Case 1.5: Cycle-day & predictions when "today" > cycleLength from LMP ---
    await clearAndInitHive();
    final lmp5 = DateTime(2024, 1, 1);
    // 60 days past LMP with a 28-day cycle → should show cycle day (60 % 28) + 1 = 5
    AppClock.setFixedTime(DateTime(2024, 3, 1));
    await storageService.saveProfile(CycleProfile(
      track: TrackingTrack.periods,
      isFertile: true,
      lastPeriod: lmp5,
      cycleLengthInDays: 28,
    ));
    await tester.pumpWidget(const app.CircaApp());
    await tester.pumpAndSettle();

    print('SCREENSHOT_READY: 1.5_cycle_wrap');
    await Future.delayed(const Duration(seconds: 3));

    // --- Case 1.6: Cycle-day wrap (modulo) sanity ---
    await clearAndInitHive();
    final lmp6 = DateTime(2024, 1, 1);
    AppClock.setFixedTime(lmp6.add(const Duration(days: 60)));
    await storageService.saveProfile(CycleProfile(
      track: TrackingTrack.periods,
      isFertile: true,
      lastPeriod: lmp6,
      cycleLengthInDays: 28,
    ));
    await tester.pumpWidget(const app.CircaApp());
    await tester.pumpAndSettle();

    print('SCREENSHOT_READY: 1.6_modulo_wrap');
    await Future.delayed(const Duration(seconds: 3));

    // --- Case 1.8: Pregnancy due date across a leap year ---
    await clearAndInitHive();
    final conceptionDate = DateTime(2024, 1, 1);
    AppClock.setFixedTime(conceptionDate);
    await storageService.saveProfile(CycleProfile(
      track: TrackingTrack.noperiods,
      isFertile: false,
      isPregnant: true,
      lastPeriod: conceptionDate,
    ));
    await tester.pumpWidget(const app.CircaApp());
    await tester.pumpAndSettle();

    print('SCREENSHOT_READY: 1.8_leap_year');
    await Future.delayed(const Duration(seconds: 3));

    // --- Case 1.9: Future date entry is blocked ---
    // This is validated by the calendar grid: future dates have onTap: null
    // Visual: future dates should appear faded (opacity 0.55)
    await clearAndInitHive();
    AppClock.setFixedTime(DateTime(2024, 6, 15));
    await storageService.saveProfile(CycleProfile(
      track: TrackingTrack.periods,
      isFertile: true,
      lastPeriod: DateTime(2024, 6, 1),
      cycleLengthInDays: 28,
    ));
    await tester.pumpWidget(const app.CircaApp());
    await tester.pumpAndSettle();

    print('SCREENSHOT_READY: 1.9_future_blocked');
    await Future.delayed(const Duration(seconds: 3));

    // --- Case 1.11: 5-day bleed seed across month boundary ---
    await clearAndInitHive();
    final boundaryDate = DateTime(2024, 2, 27);
    AppClock.setFixedTime(boundaryDate);
    await storageService.seedFromOnboarding(CycleProfile(
      track: TrackingTrack.periods,
      lastPeriod: boundaryDate,
      cycleLengthInDays: 28,
      isFertile: true,
    ));
    await tester.pumpWidget(const app.CircaApp());
    await tester.pumpAndSettle();

    print('SCREENSHOT_READY: 1.11_seed_boundary');
    await Future.delayed(const Duration(seconds: 3));

    // --- Case 1.12: Month/year navigation repaints correctly ---
    // Navigate forward one month from current view
    final chevronRight = find.byIcon(Icons.chevron_right);
    if (chevronRight.evaluate().isNotEmpty) {
      await tester.tap(chevronRight.first);
      await tester.pumpAndSettle();
    }

    print('SCREENSHOT_READY: 1.12_month_nav');
    await Future.delayed(const Duration(seconds: 3));

    // --- Case 1.13: Far-future paints predictions only ---
    // Navigate forward one more month
    if (chevronRight.evaluate().isNotEmpty) {
      await tester.tap(chevronRight.first);
      await tester.pumpAndSettle();
    }

    print('SCREENSHOT_READY: 1.13_future_predictions');
    await Future.delayed(const Duration(seconds: 3));

    // --- Case 1.14: Backdated log lands on chosen day ---
    // Go back to Feb to see the seed boundary
    final chevronLeft = find.byIcon(Icons.chevron_left);
    if (chevronLeft.evaluate().isNotEmpty) {
      // Navigate back several months to February
      for (int i = 0; i < 3; i++) {
        await tester.tap(chevronLeft.first);
        await tester.pumpAndSettle();
      }
    }

    print('SCREENSHOT_READY: 1.14_backdate_nav');
    await Future.delayed(const Duration(seconds: 3));

    print('ALL_DONE');
  });
}
