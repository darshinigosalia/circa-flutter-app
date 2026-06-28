import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:circa_app/models/user_profile.dart';
import 'package:circa_app/models/cycle_type.dart';
import 'package:circa_app/models/onboarding_data.dart';
import 'package:circa_app/services/storage_service.dart';
import 'package:circa_app/screens/onboarding/track_fork_screen.dart';

/// Onboarding Questionnaire Flow Scenarios:
///
/// - Menstrual Cycle (cycleType == CycleType.periods)
///   - Date Selected:
///     - Option: Show fertile window predictions ➔ **Scenario A** (menstrual, date selected, isFertile == true)
///     - Option: Do not show fertile window ➔ **Scenario B** (menstrual, date selected, isFertile == false)
///   - Date Not Selected (skipped/forgot) ➔ **Scenario C** (menstrual, date not selected)
///
/// - Cycle Without Periods (cycleType == CycleType.noPeriods)
///   - Option: Track pregnancy ➔ **Scenario D** (isPregnant == true)
///   - Option: Don't track pregnancy ➔ **Scenario E** (isPregnant == false)
void main() {
  late Directory baseTempDir;
  late StorageService testStorage;
  int testCounter = 0;

  setUpAll(() async {
    // Create one base temp directory for this file's execution
    baseTempDir = Directory.systemTemp.createTempSync('circa_hive_base_dir_');
    Hive.init(baseTempDir.path);
  });

  setUp(() async {
    testCounter++;
    final suffix = '_$testCounter';

    // Open boxes using a unique prefix/suffix per test to guarantee 100% isolation
    await Hive.openBox<String>('profile$suffix');
    await Hive.openBox<String>('logs$suffix');
    await Hive.openBox<String>('medications$suffix');
    await Hive.openBox<String>('appointments$suffix');
    await Hive.openBox('settings$suffix');

    testStorage = StorageService(boxSuffix: suffix);
    await testStorage.init();
    await testStorage.clearAllData();
  });

  tearDown(() async {
    // Only reset adapters here — do not call Hive.close() or deleteBoxFromDisk()
    // because the widget tree's active listeners can cause those calls to hang.
    // Each test uses uniquely suffixed box names, so stale boxes are harmless
    // and the base temp directory is cleaned up in tearDownAll.
    Hive.resetAdapters();
  });

  tearDownAll(() async {
    // Clean up the physical directory structure at the very end
    if (baseTempDir.existsSync()) {
      try {
        baseTempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  group('UserProfile - Serialization (Scenario A)', () {
    test('toJson() should produce correct keys and values', () {
      final date = DateTime(2026, 6, 28);
      final profile = UserProfile(
        cycleType: CycleType.periods,
        lastPeriod: date,
        isFertile: true,
      );

      final json = profile.toJson();

      expect(json['cycleType'], 'periods');
      expect(json['lastPeriod'], date.toIso8601String());
      expect(json['cycleLengthInDays'], 28);
      expect(json['isFertile'], true);
      expect(json['isPregnant'], false);
      expect(json['hormones'], <String>[]);
      expect(json['anchor'], null);
      expect(json['symptomsToTrack'], <String>[]);
      expect(json['trackMeds'], false);
      expect(json['pregnancyOutcome'], null);
    });

    test(
      'fromJson() should deserialize map matching the cleaned schema correctly',
      () {
        final jsonMap = <String, dynamic>{
          'cycleType': 'periods',
          'lastPeriod': '2026-06-28T00:00:00.000',
          'cycleLengthInDays': 28,
          'isFertile': true,
          'isPregnant': false,
          'hormones': <String>[],
          'anchor': null,
          'symptomsToTrack': <String>[],
          'trackMeds': false,
          'pregnancyOutcome': null,
        };

        final profile = UserProfile.fromJson(jsonMap);

        expect(profile.cycleType, CycleType.periods);
        expect(profile.lastPeriod, DateTime.parse('2026-06-28T00:00:00.000'));
        expect(profile.cycleLengthInDays, 28);
        expect(profile.isFertile, true);
        expect(profile.isPregnant, false);
        expect(profile.hormones, const <String>[]);
        expect(profile.anchor, null);
        expect(profile.symptomsToTrack, const <String>[]);
        expect(profile.trackMeds, false);
        expect(profile.pregnancyOutcome, null);
      },
    );
  });

  group('Onboarding Flow - User Interaction to Storage', () {
    testWidgets(
      'Should navigate through onboarding steps, complete Scenario A, and populate database correctly',
      (WidgetTester tester) async {
        // Build our onboarding starting screen within a testable app context
        await tester.pumpWidget(
          MaterialApp(
            home: TrackForkScreen(data: OnboardingData(), storage: testStorage),
          ),
        );

        // 1. TrackForkScreen - Tap 'I have a menstrual cycle'
        final menstrualCard = find.text('I have a menstrual cycle');
        expect(menstrualCard, findsOneWidget);
        await tester.tap(menstrualCard);
        await tester.pumpAndSettle();

        // 2. DateEntryScreen - Tap date field to open Picker, tap OK to select today's date
        final selectDateText = find.text('Select a date');
        expect(selectDateText, findsOneWidget);
        await tester.tap(selectDateText);
        await tester.pumpAndSettle();

        final okButton = find.text('OK');
        expect(okButton, findsOneWidget);
        await tester.tap(okButton);
        await tester.pumpAndSettle();

        // Now date should be selected and "Continue" button should be active
        final continueButton = find.text('Continue');
        expect(continueButton, findsOneWidget);
        await tester.tap(continueButton);
        await tester.pumpAndSettle();

        // 3. FertileOptInScreen - Tap 'Yes, show my fertile window'
        final optInCard = find.text('Yes, show my fertile window');
        expect(optInCard, findsOneWidget);
        await tester.tap(optInCard);
        await tester.pumpAndSettle();

        // Onboarding complete! Verify in-memory storage values
        final profile = testStorage.profile;
        expect(profile, isNotNull);
        expect(profile!.cycleType, CycleType.periods);
        expect(profile.isFertile, isTrue);
        expect(profile.isPregnant, isFalse);
        expect(profile.lastPeriod, isNotNull);

        // Verify serialized values stored in Hive database directly
        final suffix = '_$testCounter';
        final profileBox = Hive.box<String>('profile$suffix');
        final savedJsonStr = profileBox.get('cycle_profile');
        expect(savedJsonStr, isNotNull);

        final Map<String, dynamic> savedJson = jsonDecode(savedJsonStr!);
        expect(savedJson['cycleType'], 'periods');
        expect(savedJson['isFertile'], true);
        expect(savedJson['isPregnant'], false);
        expect(savedJson['cycleLengthInDays'], 28);

        // Unmount the widget tree to cleanly release database listeners
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'Should navigate through onboarding steps, complete Scenario B, and populate database correctly',
      (WidgetTester tester) async {
        // Build our onboarding starting screen within a testable app context
        await tester.pumpWidget(
          MaterialApp(
            home: TrackForkScreen(data: OnboardingData(), storage: testStorage),
          ),
        );

        // 1. TrackForkScreen - Tap 'I have a menstrual cycle'
        final menstrualCard = find.text('I have a menstrual cycle');
        expect(menstrualCard, findsOneWidget);
        await tester.tap(menstrualCard);
        await tester.pumpAndSettle();

        // 2. DateEntryScreen - Tap date field to open Picker, tap OK to select today's date
        final selectDateText = find.text('Select a date');
        expect(selectDateText, findsOneWidget);
        await tester.tap(selectDateText);
        await tester.pumpAndSettle();

        final okButton = find.text('OK');
        expect(okButton, findsOneWidget);
        await tester.tap(okButton);
        await tester.pumpAndSettle();

        // Now date should be selected and "Continue" button should be active
        final continueButton = find.text('Continue');
        expect(continueButton, findsOneWidget);
        await tester.tap(continueButton);
        await tester.pumpAndSettle();

        // 3. FertileOptInScreen - Tap 'No, keep it simple'
        final optOutCard = find.text('No, keep it simple');
        expect(optOutCard, findsOneWidget);
        await tester.tap(optOutCard);
        await tester.pumpAndSettle();

        // Onboarding complete! Verify in-memory storage values
        final profile = testStorage.profile;
        expect(profile, isNotNull);
        expect(profile!.cycleType, CycleType.periods);
        expect(profile.isFertile, isFalse);
        expect(profile.isPregnant, isFalse);
        expect(profile.lastPeriod, isNotNull);

        // Verify serialized values stored in Hive database directly
        final suffix = '_$testCounter';
        final profileBox = Hive.box<String>('profile$suffix');
        final savedJsonStr = profileBox.get('cycle_profile');
        expect(savedJsonStr, isNotNull);

        final Map<String, dynamic> savedJson = jsonDecode(savedJsonStr!);
        expect(savedJson['cycleType'], 'periods');
        expect(savedJson['isFertile'], false);
        expect(savedJson['isPregnant'], false);
        expect(savedJson['cycleLengthInDays'], 28);

        // Unmount the widget tree to cleanly release database listeners
        await tester.pumpWidget(const SizedBox());
      },
    );
  });
}
