import '../models/day_log.dart';

class CycleData {
  final int number;
  final DateTime startDate;
  final DateTime? endDate;
  final int? length;
  final int bleedingDays;
  final bool anomalous;
  final String? anomalousReason;
  final List<DayLog> logs;

  CycleData({
    required this.number,
    required this.startDate,
    this.endDate,
    this.length,
    required this.bleedingDays,
    required this.anomalous,
    this.anomalousReason,
    required this.logs,
  });
}

class CycleExtractor {
  static List<CycleData> extractCycles(List<DayLog> allLogs) {
    // allLogs must be sorted chronologically
    final sorted = List<DayLog>.from(allLogs)..sort((a, b) => a.date.compareTo(b.date));
    
    List<CycleData> cycles = [];
    int cycleNumber = 1;
    
    DayLog? currentStartLog;
    List<DayLog> currentCycleLogs = [];
    
    for (int i = 0; i < sorted.length; i++) {
      final log = sorted[i];
      
      if (log.periodStarted) {
        if (currentStartLog != null) {
          // Close previous cycle
          final endDate = log.date.subtract(const Duration(days: 1));
          final length = endDate.difference(currentStartLog.date).inDays + 1;
          
          cycles.add(CycleData(
            number: cycleNumber++,
            startDate: currentStartLog.date,
            endDate: endDate,
            length: length,
            bleedingDays: _countBleedingDays(currentCycleLogs),
            anomalous: currentStartLog.anomalousCycle,
            anomalousReason: currentStartLog.anomalousReason,
            logs: currentCycleLogs,
          ));
        }
        
        currentStartLog = log;
        currentCycleLogs = [log];
      } else {
        if (currentStartLog != null) {
          currentCycleLogs.add(log);
        }
      }
    }
    
    // Add the final incomplete cycle
    if (currentStartLog != null) {
      cycles.add(CycleData(
        number: cycleNumber,
        startDate: currentStartLog.date,
        endDate: null,
        length: null,
        bleedingDays: _countBleedingDays(currentCycleLogs),
        anomalous: currentStartLog.anomalousCycle,
        anomalousReason: currentStartLog.anomalousReason,
        logs: currentCycleLogs,
      ));
    }
    
    // Reverse so the newest cycle is first
    return cycles.reversed.toList();
  }

  static int _countBleedingDays(List<DayLog> logs) {
    int count = 0;
    bool inSpan = false;
    for (final log in logs) {
      if (log.periodStarted) inSpan = true;
      if (log.periodEnded) inSpan = false;
      
      if (log.bleedingFlowLevel != null || inSpan) {
        count++;
      }
    }
    return count;
  }

  static int calculatePredictedCycleLength(List<DayLog> allLogs) {
    final cycles = extractCycles(allLogs);
    final completedCycles = cycles.where((c) => c.length != null).toList();
    final nonAnomalous = completedCycles.where((c) => !c.anomalous).toList();
    
    if (nonAnomalous.isEmpty) return 28; // fallback
    
    if (nonAnomalous.length >= 3) {
      // Use Median
      final lengths = nonAnomalous.map((c) => c.length!).toList()..sort();
      final middle = lengths.length ~/ 2;
      if (lengths.length % 2 == 1) {
        return lengths[middle];
      } else {
        return ((lengths[middle - 1] + lengths[middle]) / 2).round();
      }
    } else {
      // Use Average
      final sum = nonAnomalous.map((c) => c.length!).reduce((a, b) => a + b);
      return (sum / nonAnomalous.length).round();
    }
  }
}
