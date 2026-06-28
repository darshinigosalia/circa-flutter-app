import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/day_log.dart';
import '../models/user_profile.dart';
import '../models/medication.dart';
import '../models/appointment.dart';
import '../utils/cycle_extractor.dart';
import 'package:circa_app/utils/app_clock.dart';

final storageService = StorageService();

class StorageService extends ChangeNotifier {
  final String boxSuffix;

  StorageService({this.boxSuffix = ''});

  String get _boxLogs => 'logs$boxSuffix';
  String get _boxProfile => 'profile$boxSuffix';
  String get _boxMedications => 'medications$boxSuffix';
  String get _boxAppointments => 'appointments$boxSuffix';
  String get _boxSettings => 'settings$boxSuffix';
  static const String _profileKey = 'cycle_profile';
  
  final Map<String, DayLog> _logs = {}; // Keyed by YYYY-MM-DD
  UserProfile? _profile;
  
  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    // Open all required Hive boxes (idempotent — safe to call if already open)
    await Hive.openBox<String>(_boxLogs);
    await Hive.openBox<String>(_boxProfile);
    await Hive.openBox<String>(_boxMedications);
    await Hive.openBox<String>(_boxAppointments);
    await Hive.openBox(_boxSettings);

    final logsBox = Hive.box<String>(_boxLogs);
    final profileBox = Hive.box<String>(_boxProfile);
    
    // Load logs
    _logs.clear();
    for (var key in logsBox.keys) {
      final jsonStr = logsBox.get(key);
      if (jsonStr != null) {
        _logs[key.toString()] = DayLog.fromJson(jsonDecode(jsonStr));
      }
    }
    
    // Load profile
    final profileJson = profileBox.get(_profileKey);
    if (profileJson != null) {
      _profile = UserProfile.fromJson(jsonDecode(profileJson));
    }
    
    _initialized = true;
    notifyListeners();
  }

  UserProfile? get profile => _profile;
  DateTime? get mostRecentPeriodStart => _profile?.lastPeriod;

  Future<void> saveProfile(UserProfile profile) async {
    _profile = profile;
    final profileBox = Hive.box<String>(_boxProfile);
    await profileBox.put(_profileKey, jsonEncode(profile.toJson()));
    notifyListeners();
  }

  Future<void> seedFromOnboarding(UserProfile profile) async {
    await saveProfile(profile);
    
    if (profile.lastPeriod != null) {
      final logsBox = Hive.box<String>(_boxLogs);
      final now = AppClock.now();

      for (int i = 0; i < 5; i++) {
        final d = profile.lastPeriod!.add(Duration(days: i));
        final normalizedDate = DateTime(d.year, d.month, d.day);
        final key = dateKey(normalizedDate);
        
        final seedLog = DayLog(
          date: normalizedDate,
          loggedAt: now,
          periodStarted: i == 0,
          bleedingFlowLevel: 'Medium',
        );
        
        _logs[key] = seedLog;
        await logsBox.put(key, jsonEncode(seedLog.toJson()));
      }
    }
    
    notifyListeners();
  }

  DayLog? getLogForDate(DateTime date) {
    return _logs[dateKey(date)];
  }

  List<DayLog> getAllLogs() {
    return _logs.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> saveLog(DayLog log) async {
    final normalizedDate = DateTime(log.date.year, log.date.month, log.date.day);
    final key = dateKey(normalizedDate);
    
    _logs[key] = log;
    final logsBox = Hive.box<String>(_boxLogs);
    await logsBox.put(key, jsonEncode(log.toJson()));
    
    // Check if we need to update the profile's prediction anchor or cycle length
    if (_profile != null) {
      final newLength = CycleExtractor.calculatePredictedCycleLength(getAllLogs());
      
      if (log.periodStarted && (_profile!.lastPeriod == null || normalizedDate.isAfter(_profile!.lastPeriod!))) {
        await saveProfile(_profile!.copyWith(
          lastPeriod: normalizedDate,
          cycleLengthInDays: newLength,
        ));
      } else if (newLength != _profile!.cycleLengthInDays) {
        await saveProfile(_profile!.copyWith(cycleLengthInDays: newLength));
      }
    }
    
    notifyListeners();
  }

  static String dateKey(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Medications
  List<Medication> getAllMedications() {
    final box = Hive.box<String>(_boxMedications);
    final meds = <Medication>[];
    for (var key in box.keys) {
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        meds.add(Medication.fromJson(jsonDecode(jsonStr)));
      }
    }
    return meds;
  }

  Future<void> saveMedication(Medication med) async {
    final box = Hive.box<String>(_boxMedications);
    await box.put(med.id, jsonEncode(med.toJson()));
    notifyListeners();
  }

  Future<void> deleteMedication(String id) async {
    final box = Hive.box<String>(_boxMedications);
    await box.delete(id);
    notifyListeners();
  }

  bool get appLockEnabled => Hive.box(_boxSettings).get('app_lock_enabled', defaultValue: false);
  Future<void> setAppLockEnabled(bool value) async {
    await Hive.box(_boxSettings).put('app_lock_enabled', value);
    notifyListeners();
  }

  String? get discreetIconName => Hive.box(_boxSettings).get('discreet_icon_name');
  Future<void> setDiscreetIconName(String? value) async {
    if (value == null) {
      await Hive.box(_boxSettings).delete('discreet_icon_name');
    } else {
      await Hive.box(_boxSettings).put('discreet_icon_name', value);
    }
    notifyListeners();
  }

  // Appointments
  List<Appointment> getAllAppointments() {
    final box = Hive.box<String>(_boxAppointments);
    final appts = <Appointment>[];
    for (var key in box.keys) {
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        appts.add(Appointment.fromJson(jsonDecode(jsonStr)));
      }
    }
    appts.sort((a, b) => a.date.compareTo(b.date));
    return appts;
  }

  Future<void> saveAppointment(Appointment appt) async {
    final box = Hive.box<String>(_boxAppointments);
    await box.put(appt.id, jsonEncode(appt.toJson()));
    notifyListeners();
  }

  Future<void> deleteAppointment(String id) async {
    final box = Hive.box<String>(_boxAppointments);
    await box.delete(id);
    notifyListeners();
  }

  // Settings
  dynamic getSetting(String key, {dynamic defaultValue}) {
    final box = Hive.box<dynamic>(_boxSettings);
    return box.get(key, defaultValue: defaultValue);
  }

  Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box<dynamic>(_boxSettings);
    await box.put(key, value);
    notifyListeners();
  }

  // Deletion
  Future<void> clearAllData() async {
    _logs.clear();
    _profile = null;
    await Hive.box<String>(_boxLogs).clear();
    await Hive.box<String>(_boxProfile).clear();
    await Hive.box<String>(_boxMedications).clear();
    await Hive.box<String>(_boxAppointments).clear();
    await Hive.box<dynamic>(_boxSettings).clear();
    notifyListeners();
  }
}
