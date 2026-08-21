import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:circa_app/models/day_log.dart';
import 'package:circa_app/models/user_profile.dart';
import 'package:circa_app/models/cycle_type.dart';
import 'package:circa_app/screens/track/track_hub_screen.dart';
import 'package:circa_app/services/storage_service.dart';
import 'package:circa_app/models/onboarding_data.dart';
import 'package:circa_app/utils/app_clock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late StorageService storage;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('track_hub_period_toggle_test_');
    Hive.init(tempDir.path);
    storage = StorageService(boxSuffix: 'period_toggle_test_box');
    await storage.init();
  });

  tearDownAll(() async {
    Hive.resetAdapters();
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  setUp(() async {
    await storage.clearAllData();
    await storage.saveProfile(UserProfile(
      cycleType: CycleType.periods,
      showFertility: false,
    ));
  });

  tearDown(() async {
    await storage.clearAllData();
  });

  testWidgets('TrackHubScreen toggles and unlogs Period started button when clicked', (WidgetTester tester) async {
    final testDate = DateTime(2026, 8, 12);

    await tester.pumpWidget(MaterialApp(
      home: TrackHubScreen(
        date: testDate,
        storage: storage,
        data: OnboardingData(),
      ),
    ));
    await tester.pumpAndSettle();

    // Initially neither is logged: two "tap to log" texts should be visible
    expect(find.text('tap to log'), findsNWidgets(2));
    expect(find.text('already logged'), findsNothing);

    // Tap Period started button
    final periodStartedFinder = find.text('Period started');
    expect(periodStartedFinder, findsOneWidget);
    await tester.tap(periodStartedFinder);
    await tester.pumpAndSettle();

    // Now Period started shows "already logged"
    expect(find.text('already logged'), findsOneWidget);
    expect(find.text('tap to log'), findsOneWidget);

    // Tap Period started button again to unlog it
    await tester.tap(periodStartedFinder);
    await tester.pumpAndSettle();

    // Now Period started is unlogged, both buttons show "tap to log"
    expect(find.text('tap to log'), findsNWidgets(2));
    expect(find.text('already logged'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TrackHubScreen toggles and unlogs Period ended button when clicked', (WidgetTester tester) async {
    final testDate = DateTime(2026, 8, 12);

    await tester.pumpWidget(MaterialApp(
      home: TrackHubScreen(
        date: testDate,
        storage: storage,
        data: OnboardingData(),
      ),
    ));
    await tester.pumpAndSettle();

    // Tap Period ended button to log it
    final periodEndedFinder = find.text('Period ended');
    expect(periodEndedFinder, findsOneWidget);
    await tester.tap(periodEndedFinder);
    await tester.pumpAndSettle();

    // Now Period ended shows "already logged"
    expect(find.text('already logged'), findsOneWidget);
    expect(find.text('tap to log'), findsOneWidget);

    // Tap Period ended button again to unlog it
    await tester.tap(periodEndedFinder);
    await tester.pumpAndSettle();

    // Now Period ended is unlogged, both buttons show "tap to log"
    expect(find.text('tap to log'), findsNWidgets(2));
    expect(find.text('already logged'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Initial draft with periodStarted and periodEnded can be unlogged', (WidgetTester tester) async {
    final testDate = DateTime(2026, 8, 12);
    final initialLog = DayLog(
      date: testDate,
      loggedAt: AppClock.now(),
      periodStarted: true,
      periodEnded: true,
    );

    await tester.pumpWidget(MaterialApp(
      home: TrackHubScreen(
        date: testDate,
        storage: storage,
        data: OnboardingData(),
        initialDraft: initialLog,
      ),
    ));
    await tester.pumpAndSettle();

    // Both start and end show "already logged"
    expect(find.text('already logged'), findsNWidgets(2));

    // Tap Period started to unlog
    await tester.tap(find.text('Period started'));
    await tester.pumpAndSettle();

    expect(find.text('already logged'), findsOneWidget);
    expect(find.text('tap to log'), findsOneWidget);

    // Tap Period ended to unlog
    await tester.tap(find.text('Period ended'));
    await tester.pumpAndSettle();

    expect(find.text('tap to log'), findsNWidgets(2));
    expect(find.text('already logged'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  test('Unlogging periodStarted in StorageService updates profile and logs appropriately', () async {
    final profile = UserProfile(
      cycleType: CycleType.periods,
      showFertility: false,
      lastPeriod: DateTime(2026, 8, 10),
    );
    await storage.saveProfile(profile);

    final log = DayLog(
      date: DateTime(2026, 8, 10),
      loggedAt: AppClock.now(),
      periodStarted: true,
    );
    await storage.saveLog(log);
    expect(storage.getLogForDate(DateTime(2026, 8, 10))?.periodStarted, isTrue);
    expect(storage.profile?.lastPeriod, equals(DateTime(2026, 8, 10)));

    // Unlog periodStarted
    final unlogged = log.copyWith(periodStarted: false);
    await storage.saveLog(unlogged);
    expect(storage.getLogForDate(DateTime(2026, 8, 10))?.periodStarted, isFalse);
    expect(storage.profile?.lastPeriod, isNull);
  });
}
