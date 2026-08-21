import 'package:flutter_test/flutter_test.dart';
import 'package:circa_app/models/day_log.dart';
import 'package:circa_app/models/user_profile.dart';
import 'package:circa_app/models/cycle_type.dart';
import 'package:circa_app/services/storage_service.dart';
import 'package:circa_app/utils/cycle_math.dart';
import 'package:circa_app/utils/cycle_extractor.dart';
import 'package:hive/hive.dart';
import 'dart:io';

void main() {
  group('1. Core Definitions - Inclusive Period Days', () {
    test('All dates from period_start (x) to period_end (y) inclusive are period days', () {
      final now = DateTime(2026, 1, 1);
      final logs = [
        DayLog(date: DateTime(2026, 1, 1), loggedAt: now, periodStarted: true),
        DayLog(date: DateTime(2026, 1, 5), loggedAt: now, periodEnded: true),
      ];

      // Days 1 to 5 should all be marked as recorded period days
      for (int day = 1; day <= 5; day++) {
        expect(
          CycleMath.isRecordedPeriodDay(DateTime(2026, 1, day), logs),
          isTrue,
          reason: 'Day $day should be recorded period day',
        );
      }

      // Day 6 is not a period day
      expect(
        CycleMath.isRecordedPeriodDay(DateTime(2026, 1, 6), logs),
        isFalse,
      );
    });
  });

  group('2. Logging Rules', () {
    test('Only period_start (x) logged, no period_end -> only day x is treated as period day', () {
      final now = DateTime(2026, 1, 1);
      final logs = [
        DayLog(date: DateTime(2026, 1, 1), loggedAt: now, periodStarted: true),
      ];

      expect(CycleMath.isRecordedPeriodDay(DateTime(2026, 1, 1), logs), isTrue);
      expect(CycleMath.isRecordedPeriodDay(DateTime(2026, 1, 2), logs), isFalse);
      expect(CycleMath.isRecordedPeriodDay(DateTime(2026, 1, 3), logs), isFalse);
    });

    test('period_start (x) logged, no end, new period_start (y) logged later -> day x remains 1-day period, day y starts new period', () {
      final now = DateTime(2026, 1, 1);
      final logs = [
        DayLog(date: DateTime(2026, 1, 1), loggedAt: now, periodStarted: true),
        DayLog(date: DateTime(2026, 1, 29), loggedAt: now, periodStarted: true),
        DayLog(date: DateTime(2026, 2, 3), loggedAt: now, periodEnded: true), // Cycle 2 ended on Feb 3 (34th day from Jan 1)
      ];

      // Day 1 is true
      expect(CycleMath.isRecordedPeriodDay(DateTime(2026, 1, 1), logs), isTrue);
      // Days 2 to 28 are false (no backfilling for Cycle 1)
      for (int day = 2; day <= 28; day++) {
        expect(
          CycleMath.isRecordedPeriodDay(DateTime(2026, 1, day), logs),
          isFalse,
          reason: 'Jan $day should not be a period day',
        );
      }

      // Cycle 2: Jan 29 to Feb 3 inclusive should be true
      expect(CycleMath.isRecordedPeriodDay(DateTime(2026, 1, 29), logs), isTrue);
      expect(CycleMath.isRecordedPeriodDay(DateTime(2026, 1, 30), logs), isTrue);
      expect(CycleMath.isRecordedPeriodDay(DateTime(2026, 2, 3), logs), isTrue);
      expect(CycleMath.isRecordedPeriodDay(DateTime(2026, 2, 4), logs), isFalse);
    });
  });

  group('3. Cycle Lengths & Period Lengths Extraction (Section 4)', () {
    test('Extracts exact cycle lengths (28, 29) and period lengths (5, 6, 6) from Section 4 example', () {
      final now = DateTime(2026, 1, 1);
      // Cycle 1: Day 1 to Day 5
      // Cycle 2: Day 29 to Day 34
      // Cycle 3: Day 58 to Day 63
      final base = DateTime(2026, 1, 1);
      final logs = [
        DayLog(date: base, loggedAt: now, periodStarted: true), // Day 1
        DayLog(date: base.add(const Duration(days: 4)), loggedAt: now, periodEnded: true), // Day 5
        DayLog(date: base.add(const Duration(days: 28)), loggedAt: now, periodStarted: true), // Day 29
        DayLog(date: base.add(const Duration(days: 33)), loggedAt: now, periodEnded: true), // Day 34
        DayLog(date: base.add(const Duration(days: 57)), loggedAt: now, periodStarted: true), // Day 58
        DayLog(date: base.add(const Duration(days: 62)), loggedAt: now, periodEnded: true), // Day 63
      ];

      final cycles = CycleExtractor.extractCycles(logs); // newest first
      expect(cycles.length, 3);

      final chronological = cycles.reversed.toList();

      // Cycle 1
      expect(chronological[0].number, 1);
      expect(chronological[0].length, 28); // 29 - 1
      expect(chronological[0].periodLength, 5); // Day 1 to 5 inclusive

      // Cycle 2
      expect(chronological[1].number, 2);
      expect(chronological[1].length, 29); // 58 - 29
      expect(chronological[1].periodLength, 6); // Day 29 to 34 inclusive

      // Cycle 3 (in progress / latest)
      expect(chronological[2].number, 3);
      expect(chronological[2].length, isNull); // current cycle, not ended by next cycle start yet
      expect(chronological[2].periodLength, 6); // Day 58 to 63 inclusive
    });
  });

  group('4. Predictions & Estimation Logic (Section 5)', () {
    test('< 3 cycles logged -> uses fixed defaults: cycle length = 28, period length = 4', () {
      final now = DateTime(2026, 1, 1);
      final base = DateTime(2026, 1, 1);
      
      // 1 cycle
      final logs1 = [
        DayLog(date: base, loggedAt: now, periodStarted: true),
        DayLog(date: base.add(const Duration(days: 6)), loggedAt: now, periodEnded: true),
      ];
      expect(CycleExtractor.calculatePredictedCycleLength(logs1), 28);
      expect(CycleExtractor.calculatePredictedPeriodLength(logs1), 4);

      // 2 cycles
      final logs2 = [
        ...logs1,
        DayLog(date: base.add(const Duration(days: 35)), loggedAt: now, periodStarted: true),
        DayLog(date: base.add(const Duration(days: 42)), loggedAt: now, periodEnded: true),
      ];
      expect(CycleExtractor.calculatePredictedCycleLength(logs2), 28);
      expect(CycleExtractor.calculatePredictedPeriodLength(logs2), 4);
    });

    test('>= 3 cycles logged -> uses Medians', () {
      final now = DateTime(2026, 1, 1);
      final base = DateTime(2026, 1, 1);
      final logs = [
        // Cycle 1: start day 1, end day 5 (period length 5, cycle gap 28)
        DayLog(date: base, loggedAt: now, periodStarted: true),
        DayLog(date: base.add(const Duration(days: 4)), loggedAt: now, periodEnded: true),
        // Cycle 2: start day 29, end day 34 (period length 6, cycle gap 29)
        DayLog(date: base.add(const Duration(days: 28)), loggedAt: now, periodStarted: true),
        DayLog(date: base.add(const Duration(days: 33)), loggedAt: now, periodEnded: true),
        // Cycle 3: start day 58, end day 63 (period length 6)
        DayLog(date: base.add(const Duration(days: 57)), loggedAt: now, periodStarted: true),
        DayLog(date: base.add(const Duration(days: 62)), loggedAt: now, periodEnded: true),
      ];

      // 3 cycles logged
      // Cycle length gaps: [28, 29] -> Median = 29
      expect(CycleExtractor.calculatePredictedCycleLength(logs), 29);
      // Period lengths: [5, 6, 6] -> Median = 6
      expect(CycleExtractor.calculatePredictedPeriodLength(logs), 6);
    });

    test('Incomplete 3rd cycle counts towards the 3-cycle threshold', () {
      final now = DateTime(2026, 1, 1);
      final base = DateTime(2026, 1, 1);
      final logs = [
        // Cycle 1: complete (start day 1, end day 5, gap 28)
        DayLog(date: base, loggedAt: now, periodStarted: true),
        DayLog(date: base.add(const Duration(days: 4)), loggedAt: now, periodEnded: true),
        // Cycle 2: complete (start day 29, end day 34, gap 30)
        DayLog(date: base.add(const Duration(days: 28)), loggedAt: now, periodStarted: true),
        DayLog(date: base.add(const Duration(days: 33)), loggedAt: now, periodEnded: true),
        // Cycle 3: incomplete (only start day 59, no end date)
        DayLog(date: base.add(const Duration(days: 58)), loggedAt: now, periodStarted: true),
      ];

      // 3 starts logged -> triggers >= 3 cycles median calculations
      // Cycle gaps: [28, 30] -> Median = 29
      expect(CycleExtractor.calculatePredictedCycleLength(logs), 29);
      // Period lengths from completed cycles: [5, 6] -> Median = 6
      expect(CycleExtractor.calculatePredictedPeriodLength(logs), 6);
    });

    test('Outliers are not filtered out and naturally absorbed by median', () {
      final now = DateTime(2026, 1, 1);
      final base = DateTime(2026, 1, 1);
      final logs = [
        // Cycle 1: start 1
        DayLog(date: base, loggedAt: now, periodStarted: true),
        DayLog(date: base.add(const Duration(days: 4)), loggedAt: now, periodEnded: true),
        // Cycle 2: start 29 (gap 28)
        DayLog(date: base.add(const Duration(days: 28)), loggedAt: now, periodStarted: true, anomalousCycle: true, anomalousReason: 'Stress'),
        DayLog(date: base.add(const Duration(days: 33)), loggedAt: now, periodEnded: true),
        // Cycle 3: start 58 (gap 29)
        DayLog(date: base.add(const Duration(days: 57)), loggedAt: now, periodStarted: true),
        DayLog(date: base.add(const Duration(days: 62)), loggedAt: now, periodEnded: true),
        // Cycle 4: start 138 (outlier gap 80 days)
        DayLog(date: base.add(const Duration(days: 137)), loggedAt: now, periodStarted: true),
        DayLog(date: base.add(const Duration(days: 142)), loggedAt: now, periodEnded: true),
      ];

      // Gaps: [28, 29, 80] -> Median is 29 (not filtered)
      expect(CycleExtractor.calculatePredictedCycleLength(logs), 29);
    });
  });

  group('5. Storage & Onboarding Seeding', () {
    late Directory tempDir;
    late StorageService storage;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('circa_test_seed_');
      Hive.init(tempDir.path);
      storage = StorageService(boxSuffix: '_spec_test');
      await storage.init();
      await storage.clearAllData();
    });

    tearDown(() async {
      Hive.resetAdapters();
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    test('seedFromOnboarding seeds exactly 1 DayLog with periodStarted = true and no extra bleeding days', () async {
      final date = DateTime(2026, 5, 10);
      final profile = UserProfile(
        cycleType: CycleType.periods,
        lastPeriod: date,
        showFertility: false,
      );

      await storage.seedFromOnboarding(profile);

      final allLogs = storage.getAllLogs();
      expect(allLogs.length, 1);
      expect(allLogs.first.date, date);
      expect(allLogs.first.periodStarted, isTrue);
      expect(allLogs.first.periodEnded, isFalse);
      expect(allLogs.first.bleedingFlowLevel, isNull);
    });
  });
}
