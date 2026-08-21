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

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('contraception_test_dir_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    Hive.resetAdapters();
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

  test('StorageService persists and clears contraceptionType correctly', () async {
    final storage = StorageService(boxSuffix: '_contraception_storage_test');
    await storage.init();
    await storage.clearAllData();

    final testDate = DateTime(2026, 8, 12);
    final initialLog = DayLog(
      date: testDate,
      loggedAt: AppClock.now(),
      contraceptionType: 'IUD',
    );
    await storage.saveLog(initialLog);

    final saved = storage.getLogForDate(testDate);
    expect(saved, isNotNull);
    expect(saved!.contraceptionType, equals('IUD'));

    final cleared = saved.copyWith(contraceptionType: null);
    await storage.saveLog(cleared);

    final retrieved = storage.getLogForDate(testDate);
    expect(retrieved, isNotNull);
    expect(retrieved!.contraceptionType, isNull);
  });
}
