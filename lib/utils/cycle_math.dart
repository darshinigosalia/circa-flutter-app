import '../models/day_log.dart';
import 'package:circa_app/utils/app_clock.dart';

class PhaseInfo {
  final String name;
  final String note;

  PhaseInfo(this.name, this.note);
}

class CycleMath {
  static const int defaultPeriodLength = 5;

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
    final elapsed = daysBetween(lmp, today);
    final cyclesPassed = (elapsed / cycleLengthInDays).floor();
    return lmp.add(Duration(days: (cyclesPassed + 1) * cycleLengthInDays));
  }

  static int getOvulationDay(int cycleLengthInDays) {
    return cycleLengthInDays - 14;
  }

  static PhaseInfo getPhase(int dayInCycle, int cycleLengthInDays) {
    final ovDay = getOvulationDay(cycleLengthInDays);
    
    if (dayInCycle <= defaultPeriodLength) {
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

  static bool isPredictedPeriod(DateTime date, DateTime lmp, int cycleLengthInDays) {
    final today = DateTime(AppClock.now().year, AppClock.now().month, AppClock.now().day);
    final normDate = DateTime(date.year, date.month, date.day);
    
    // Predictions are strictly for the future
    if (normDate.isBefore(today) || normDate.isAtSameMomentAs(today)) {
      return false;
    }

    final dayInCycle = getDayInCycle(lmp, normDate, cycleLengthInDays);
    return dayInCycle >= 1 && dayInCycle <= defaultPeriodLength;
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

    // Second, check if it falls within a completed span [Period started -> Period ended]
    // A span is completed if there's a periodEnded strictly after a periodStarted with no other starts between them.
    // We do this by finding the most recent 'start' or 'end' before/at our date.
    
    DateTime? lastStart;
    DateTime? lastEnd;

    for (final log in allLogs) {
      final logDate = DateTime(log.date.year, log.date.month, log.date.day);
      if (logDate.isAfter(normDate)) break; // logs are sorted chronologically
      
      if (log.periodStarted) {
        lastStart = logDate;
        // If there are multiple starts, we just update to the latest
      }
      if (log.periodEnded) {
        lastEnd = logDate;
      }
    }

    if (lastStart != null && lastEnd != null) {
      // We have both a start and an end prior to or on this date
      // If the end is AFTER the start, it's a closed span.
      if (lastEnd.isAfter(lastStart) || lastEnd.isAtSameMomentAs(lastStart)) {
        // Since both are before/on normDate, normDate could be inside the span ONLY if it is <= lastEnd
        // But since we already broke the loop for logs > normDate, lastEnd is <= normDate.
        // Wait, if lastEnd is < normDate, then normDate is OUTSIDE the closed span.
        if (normDate.isAfter(lastStart) && (normDate.isBefore(lastEnd) || normDate.isAtSameMomentAs(lastEnd))) {
          return true;
        }
      }
    } else if (lastStart != null && lastEnd == null) {
      // Open span. DO NOT AUTO-FILL.
      // "Only the start day (plus any days individually logged) count"
      // Both are already covered by the exactLog check at the top.
      return false;
    }

    // Now consider cases where there's a closed span that encompasses normDate
    // The previous loop only looked at logs BEFORE or ON normDate. 
    // What if the end is AFTER normDate?
    
    lastStart = null;
    lastEnd = null;
    
    // Re-evaluate to find the span that encompasses this date
    for (final log in allLogs) {
      final logDate = DateTime(log.date.year, log.date.month, log.date.day);
      if (log.periodStarted) {
        if (logDate.isBefore(normDate) || logDate.isAtSameMomentAs(normDate)) {
           lastStart = logDate;
        }
      }
    }

    if (lastStart != null) {
      // Find the first end AFTER this start
      for (final log in allLogs) {
        final logDate = DateTime(log.date.year, log.date.month, log.date.day);
        if (log.periodEnded && logDate.isAfter(lastStart)) {
           lastEnd = logDate;
           break;
        }
      }
      
      if (lastEnd != null && (normDate.isBefore(lastEnd) || normDate.isAtSameMomentAs(lastEnd))) {
        // It's inside a closed span!
        return true;
      }
    }

    return false;
  }
}
