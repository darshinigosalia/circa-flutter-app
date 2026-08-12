import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:circa_app/screens/track/track_hub_screen.dart';
import 'package:circa_app/services/storage_service.dart';
import 'package:circa_app/models/onboarding_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late StorageService storage;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('track_hub_test_dir_');
    Hive.init(tempDir.path);
    storage = StorageService(boxSuffix: 'track_test_box');
    await storage.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('TrackHubScreen renders horizontal circular date strip and responds to date selection', (WidgetTester tester) async {
    final testDate = DateTime(2026, 8, 12);

    await tester.pumpWidget(MaterialApp(
      home: TrackHubScreen(
        date: testDate,
        storage: storage,
        data: OnboardingData(),
      ),
    ));
    await tester.pumpAndSettle();

    // Verify day number and month text are rendered inside circular date badges
    expect(find.text('12'), findsWidgets);
    expect(find.text('AUG'), findsWidgets);

    // Tap day 11 circle if present
    final day11Finder = find.text('11');
    if (day11Finder.evaluate().isNotEmpty) {
      await tester.tap(day11Finder.first);
      await tester.pumpAndSettle();
      expect(find.text('Logging for Tue, Aug 11'), findsOneWidget);
    }
  });

  testWidgets('TrackHubScreen top right calendar icon opens date picker', (WidgetTester tester) async {
    final testDate = DateTime(2026, 8, 12);

    await tester.pumpWidget(MaterialApp(
      home: TrackHubScreen(
        date: testDate,
        storage: storage,
        data: OnboardingData(),
      ),
    ));
    await tester.pumpAndSettle();

    // Find and tap the calendar icon button on the top right
    final calendarIconFinder = find.byIcon(Icons.calendar_today_outlined);
    expect(calendarIconFinder, findsOneWidget);

    await tester.tap(calendarIconFinder);
    await tester.pumpAndSettle();

    // Verify calendar dialog opens
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });
}
