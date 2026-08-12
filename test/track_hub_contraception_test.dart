import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:circa_app/models/day_log.dart';
import 'package:circa_app/screens/track/track_hub_screen.dart';
import 'package:circa_app/services/storage_service.dart';
import 'package:circa_app/models/onboarding_data.dart';
import 'package:circa_app/utils/app_clock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late StorageService storage;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('contraception_test_dir_');
    Hive.init(tempDir.path);
    storage = StorageService(boxSuffix: 'contraception_test_box');
    await storage.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('DayLog copyWith explicitly supports setting contraceptionType and other nullable fields to null', () {
    final now = AppClock.now();
    final log = DayLog(
      date: now,
      loggedAt: now,
      contraceptionType: 'IUD',
      intercourseProtected: true,
      basalBodyTemperature: 98.6,
    );

    expect(log.contraceptionType, equals('IUD'));
    expect(log.intercourseProtected, isTrue);

    final updated = log.copyWith(contraceptionType: null, intercourseProtected: null);
    expect(updated.contraceptionType, isNull);
    expect(updated.intercourseProtected, isNull);
    expect(updated.basalBodyTemperature, equals(98.6));
  });

  testWidgets('Selecting None in Started Contraception sheet clears selected contraception', (WidgetTester tester) async {
    final testDate = DateTime(2026, 8, 12);
    final initialLog = DayLog(
      date: testDate,
      loggedAt: AppClock.now(),
      contraceptionType: 'IUD',
    );
    await storage.saveLog(initialLog);

    await tester.pumpWidget(MaterialApp(
      home: TrackHubScreen(
        date: testDate,
        storage: storage,
        data: const OnboardingData(),
      ),
    ));
    await tester.pumpAndSettle();

    // Verify initial selection displays "IUD"
    expect(find.text('IUD'), findsOneWidget);

    // Tap on Contraception row to open bottom sheet
    await tester.tap(find.text('Started contraception / IUD'));
    await tester.pumpAndSettle();

    // Verify sheet title and options are visible
    expect(find.text('Started contraception / IUD today'), findsOneWidget);

    // Tap "None" button in the bottom sheet
    await tester.tap(find.widgetWithText(ElevatedButton, 'None').last);
    await tester.pumpAndSettle();

    // Verify bottom sheet is dismissed and row displays "None" instead of "IUD"
    expect(find.text('Started contraception / IUD today'), findsNothing);
    expect(find.text('None'), findsOneWidget);
    expect(find.text('IUD'), findsNothing);
  });
}
