import '../models/day_log.dart';
import 'cycle_math.dart';

class CycleData {
  final int number;
  final DateTime startDate;
  final DateTime? endDate;
  final int? length;
  final DateTime? periodEndDate;
  final int? periodLength;
  final int bleedingDays;
  final bool anomalous;
  final String? anomalousReason;
  final List<DayLog> logs;

  CycleData({
    required this.number,
    required this.startDate,
    this.endDate,
    this.length,
    this.periodEndDate,
    this.periodLength,
    required this.bleedingDays,
    required this.anomalous,
    this.anomalousReason,
    required this.logs,
  });
}

class CycleExtractor {
  static const int normalCycleLengthDays = 28;
  static const int normalPeriodLengthDays = 4;

  static List<CycleData> extractCycles(List<DayLog> allLogs) {
    // allLogs must be sorted chronologically
    final sorted = List<DayLog>.from(allLogs)..sort((a, b) => a.date.compareTo(b.date));
    
    // Find all start logs
    final startLogs = sorted.where((l) => l.periodStarted).toList();
    if (startLogs.isEmpty) return [];

    List<CycleData> cycles = [];
    
    for (int i = 0; i < startLogs.length; i++) {
      final startLog = startLogs[i];
      final startDate = DateTime(startLog.date.year, startLog.date.month, startLog.date.day);
      final nextStartDate = (i + 1 < startLogs.length)
          ? DateTime(startLogs[i + 1].date.year, startLogs[i + 1].date.month, startLogs[i + 1].date.day)
          : null;

      // Cycle end date (day before next start) and cycle length
      final DateTime? cycleEndDate = nextStartDate?.subtract(const Duration(days: 1));
      final int? cycleLength = (nextStartDate != null)
          ? CycleMath.daysBetween(startDate, nextStartDate)
          : null;

      // Find logs belonging to this cycle
      final cycleLogs = sorted.where((l) {
        final d = DateTime(l.date.year, l.date.month, l.date.day);
        if (d.isBefore(startDate)) return false;
        if (nextStartDate != null && (d.isAtSameMomentAs(nextStartDate) || d.isAfter(nextStartDate))) return false;
        return true;
      }).toList();

      // Find first explicit periodEnded for this cycle (on/after startDate and before nextStartDate)
      final endLog = cycleLogs.where((l) => l.periodEnded).firstOrNull;
      final DateTime? periodEndDate = (endLog != null)
          ? DateTime(endLog.date.year, endLog.date.month, endLog.date.day)
          : null;
      
      final int? periodLength = (periodEndDate != null)
          ? (CycleMath.daysBetween(startDate, periodEndDate) + 1)
          : null;

      cycles.add(CycleData(
        number: i + 1,
        startDate: startDate,
        endDate: cycleEndDate,
        length: cycleLength,
        periodEndDate: periodEndDate,
        periodLength: periodLength,
        bleedingDays: _countBleedingDays(startDate, periodEndDate, cycleLogs),
        anomalous: startLog.anomalousCycle,
        anomalousReason: startLog.anomalousReason,
        logs: cycleLogs,
      ));
    }
    
    // Reverse so the newest cycle is first
    return cycles.reversed.toList();
  }

  static int _countBleedingDays(DateTime startDate, DateTime? periodEndDate, List<DayLog> cycleLogs) {
    final Set<String> bleedingDayKeys = {};

    // 1. Add start date
    bleedingDayKeys.add(_dateKey(startDate));

    // 2. If closed span, add all dates from startDate to periodEndDate inclusive
    if (periodEndDate != null && !periodEndDate.isBefore(startDate)) {
      DateTime cur = startDate;
      while (!cur.isAfter(periodEndDate)) {
        bleedingDayKeys.add(_dateKey(cur));
        cur = cur.add(const Duration(days: 1));
      }
    }

    // 3. Add any other logs with explicit flow level or period flags
    for (final log in cycleLogs) {
      if (log.bleedingFlowLevel != null || log.periodStarted || log.periodEnded) {
        bleedingDayKeys.add(_dateKey(log.date));
      }
    }

    return bleedingDayKeys.length;
  }

  static String _dateKey(DateTime d) => "${d.year}-${d.month}-${d.day}";

  /// Calculates predicted cycle length (gap between consecutive period_start dates).
  /// - < 3 cycles logged: returns 28 (default)
  /// - >= 3 cycles logged: returns Median of consecutive period_start gaps
  static int calculatePredictedCycleLength(List<DayLog> allLogs) {
    final startLogs = allLogs.where((l) => l.periodStarted).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Total cycles logged = number of period_starts (complete or not)
    if (startLogs.length < 3) {
      return normalCycleLengthDays;
    }

    final gaps = <int>[];
    for (int i = 0; i < startLogs.length - 1; i++) {
      final gap = CycleMath.daysBetween(startLogs[i].date, startLogs[i + 1].date);
      gaps.add(gap);
    }

    if (gaps.isEmpty) return normalCycleLengthDays;
    return _median(gaps);
  }

  /// Calculates predicted period length (gap between period_start and period_end).
  /// - < 3 cycles logged: returns 4 (default)
  /// - >= 3 cycles logged: returns Median of completed period lengths
  static int calculatePredictedPeriodLength(List<DayLog> allLogs) {
    final chronologicalCycles = extractCycles(allLogs).reversed.toList();

    // Total cycles logged threshold check
    if (chronologicalCycles.length < 3) {
      return normalPeriodLengthDays;
    }

    // Collect period lengths for cycles that have both period_start and period_end
    final periodLengths = <int>[];
    for (final cycle in chronologicalCycles) {
      if (cycle.periodLength != null) {
        periodLengths.add(cycle.periodLength!);
      }
    }

    if (periodLengths.isEmpty) {
      return normalPeriodLengthDays;
    }

    return _median(periodLengths);
  }

  static int _median(List<int> values) {
    if (values.isEmpty) return 0;
    final sorted = List<int>.from(values)..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length % 2 == 1) {
      return sorted[middle];
    } else {
      return ((sorted[middle - 1] + sorted[middle]) / 2).round();
    }
  }
}
