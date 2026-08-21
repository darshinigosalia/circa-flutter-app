import '../models/day_log.dart';
import 'package:circa_app/utils/app_clock.dart';

class PhaseInfo {
  final String name;
  final String note;

  PhaseInfo(this.name, this.note);
}

class CycleMath {

  static int daysBetween(DateTime a, DateTime b) {
    final aNormalized = DateTime(a.year, a.month, a.day);
    final bNormalized = DateTime(b.year, b.month, b.day);
    return bNormalized.difference(aNormalized).inDays;
  }

  static int getDayInCycle(DateTime lmp, DateTime today, int cycleLengthInDays) {
    final elapsed = daysBetween(lmp, today);
    return ((elapsed % cycleLengthInDays) + cycleLengthInDays) % cycleLengthInDays + 1;
  }

  static DateTime getNextPeriod(DateTime lmp, DateTime today, int cycleLengthInDays) {
    final lmpNorm = DateTime(lmp.year, lmp.month, lmp.day);
    final todayNorm = DateTime(today.year, today.month, today.day);

    DateTime next = lmpNorm.add(Duration(days: cycleLengthInDays));
    while (!next.isAfter(todayNorm)) {
      next = next.add(Duration(days: cycleLengthInDays));
    }
    return next;
  }

  static int getOvulationDay(int cycleLengthInDays) {
    return cycleLengthInDays - 14;
  }

  static PhaseInfo getPhase(int dayInCycle, int cycleLengthInDays, int periodLengthInDays) {
    final ovDay = getOvulationDay(cycleLengthInDays);
    
    if (dayInCycle <= periodLengthInDays) {
      return PhaseInfo("Menstrual", "Your period; rest and be gentle with yourself.");
    } else if (dayInCycle < ovDay - 2) {
      return PhaseInfo("Follicular", "Energy is building back up.");
    } else if (dayInCycle <= ovDay + 1) {
      return PhaseInfo("Ovulation", "Your fertile window, most likely to conceive.");
    } else {
      return PhaseInfo("Luteal", "Winding down toward your next period.");
    }
  }

  static bool isFertileWindow(DateTime date, DateTime lmp, int cycleLengthInDays) {
    final dayInCycle = getDayInCycle(lmp, date, cycleLengthInDays);
    final ovDay = getOvulationDay(cycleLengthInDays);
    return dayInCycle >= (ovDay - 3) && dayInCycle <= (ovDay + 1);
  }

  static bool isOvulationDay(DateTime date, DateTime lmp, int cycleLengthInDays) {
    final dayInCycle = getDayInCycle(lmp, date, cycleLengthInDays);
    return dayInCycle == getOvulationDay(cycleLengthInDays);
  }

  static bool isPredictedPeriod(DateTime date, DateTime lmp, int cycleLengthInDays, int periodLengthInDays) {
    final today = DateTime(AppClock.now().year, AppClock.now().month, AppClock.now().day);
    final normDate = DateTime(date.year, date.month, date.day);
    
    // Predictions are strictly for the future
    if (normDate.isBefore(today) || normDate.isAtSameMomentAs(today)) {
      return false;
    }

    final lmpNorm = DateTime(lmp.year, lmp.month, lmp.day);
    final daysSinceLmp = daysBetween(lmpNorm, normDate);
    if (daysSinceLmp < cycleLengthInDays) {
      return false;
    }

    final dayInCycle = (daysSinceLmp % cycleLengthInDays) + 1;
    return dayInCycle <= periodLengthInDays;
  }

  static bool isRecordedPeriodDay(DateTime date, List<DayLog> allLogs) {
    final normDate = DateTime(date.year, date.month, date.day);
    
    // First, check direct manual logs for this day
    final exactLog = allLogs.where((l) {
      final ld = DateTime(l.date.year, l.date.month, l.date.day);
      return ld.isAtSameMomentAs(normDate);
    }).firstOrNull;

    if (exactLog != null) {
      if (exactLog.bleedingFlowLevel != null || exactLog.periodStarted || exactLog.periodEnded) {
        return true;
      }
    }

    // Second, check if it falls within any closed span [periodStarted -> periodEnded]
    final sortedStarts = allLogs
        .where((l) => l.periodStarted)
        .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
        .toSet()
        .toList()
      ..sort();

    final sortedEnds = allLogs
        .where((l) => l.periodEnded)
        .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
        .toSet()
        .toList()
      ..sort();

    for (int i = 0; i < sortedStarts.length; i++) {
      final start = sortedStarts[i];
      final nextStart = (i + 1 < sortedStarts.length) ? sortedStarts[i + 1] : null;

      // Find the first periodEnded on or after this start (and before nextStart if any)
      final end = sortedEnds.where((e) {
        if (e.isBefore(start)) return false;
        if (nextStart != null && (e.isAfter(nextStart) || e.isAtSameMomentAs(nextStart))) return false;
        return true;
      }).firstOrNull;

      if (end != null) {
        // Closed span from start to end inclusive
        if ((normDate.isAtSameMomentAs(start) || normDate.isAfter(start)) &&
            (normDate.isAtSameMomentAs(end) || normDate.isBefore(end))) {
          return true;
        }
      }
    }

    return false;
  }
}
