import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:circa_app/models/day_log.dart';
import 'package:circa_app/services/storage_service.dart';
import 'package:circa_app/utils/app_clock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late StorageService storage;
  const boxSuffix = '_past_dates_test';

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_past_dates_test_');
    Hive.init(tempDir.path);
    storage = StorageService(boxSuffix: boxSuffix);
    await storage.init();
  });

  tearDown(() async {
    Hive.resetAdapters();
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  test('Save and retrieve symptoms for past dates in StorageService & Hive DB', () async {
    final pastDate1 = DateTime(2026, 7, 15);
    final pastDate2 = DateTime(2026, 8, 1);

    final log1 = DayLog(
      date: pastDate1,
      loggedAt: AppClock.now(),
      bleedingFlowLevel: 'Medium',
      dischargeAmount: 'Creamy',
      symptoms: {'Cramps': 'Severe', 'Mood changes': 'Irritable'},
      customSymptoms: [CustomSymptom(name: 'Lower back ache', detail: 'Constant')],
      notes: 'Logged symptoms for July 15',
      basalBodyTemperature: 97.8,
    );

    final log2 = DayLog(
      date: pastDate2,
      loggedAt: AppClock.now(),
      bleedingFlowLevel: 'Light',
      symptoms: {'Headaches': 'Mild', 'Fatigue': 'Moderate'},
      periodStarted: true,
      notes: 'Start of August period',
    );

    // Save logs for past dates
    await storage.saveLog(log1);
    await storage.saveLog(log2);

    // 1. Verify in-memory retrieval
    final retrieved1 = storage.getLogForDate(pastDate1);
    expect(retrieved1, isNotNull);
    expect(retrieved1!.bleedingFlowLevel, 'Medium');
    expect(retrieved1.dischargeAmount, 'Creamy');
    expect(retrieved1.symptoms['Cramps'], 'Severe');
    expect(retrieved1.symptoms['Mood changes'], 'Irritable');
    expect(retrieved1.customSymptoms.first.name, 'Lower back ache');
    expect(retrieved1.basalBodyTemperature, 97.8);
    expect(retrieved1.notes, 'Logged symptoms for July 15');

    final retrieved2 = storage.getLogForDate(pastDate2);
    expect(retrieved2, isNotNull);
    expect(retrieved2!.periodStarted, isTrue);
    expect(retrieved2.symptoms['Headaches'], 'Mild');

    // 2. Verify physical Hive box contents directly
    final logsBox = Hive.box<String>('logs$boxSuffix');
    final key1 = StorageService.dateKey(pastDate1);
    final key2 = StorageService.dateKey(pastDate2);

    final rawJson1 = logsBox.get(key1);
    expect(rawJson1, isNotNull);
    final decoded1 = jsonDecode(rawJson1!);
    expect(decoded1['bleedingFlowLevel'], 'Medium');
    expect(decoded1['notes'], 'Logged symptoms for July 15');

    final rawJson2 = logsBox.get(key2);
    expect(rawJson2, isNotNull);
    final decoded2 = jsonDecode(rawJson2!);
    expect(decoded2['periodStarted'], isTrue);

    // 3. Verify persistence across fresh StorageService instance re-initialization
    final freshStorage = StorageService(boxSuffix: boxSuffix);
    await freshStorage.init();

    final reloaded1 = freshStorage.getLogForDate(pastDate1);
    expect(reloaded1, isNotNull);
    expect(reloaded1!.bleedingFlowLevel, 'Medium');
    expect(reloaded1.symptoms['Cramps'], 'Severe');
    expect(reloaded1.customSymptoms.first.detail, 'Constant');
    expect(reloaded1.basalBodyTemperature, 97.8);

    final reloaded2 = freshStorage.getLogForDate(pastDate2);
    expect(reloaded2, isNotNull);
    expect(reloaded2!.periodStarted, isTrue);
    expect(reloaded2.symptoms['Fatigue'], 'Moderate');
  });
}
