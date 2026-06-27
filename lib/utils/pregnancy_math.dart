import 'dart:math';

class PregnancyMath {
  static int getElapsedDays(DateTime lastPeriod, DateTime today) {
    // Normalize dates to local midnight to avoid time-of-day math errors
    final lmp = DateTime(lastPeriod.year, lastPeriod.month, lastPeriod.day);
    final current = DateTime(today.year, today.month, today.day);
    return max(0, current.difference(lmp).inDays);
  }

  static int getWeeks(int elapsedDays) {
    return elapsedDays ~/ 7;
  }

  static int getDays(int elapsedDays) {
    return elapsedDays % 7;
  }

  static DateTime getDueDate(DateTime lastPeriod) {
    final lmp = DateTime(lastPeriod.year, lastPeriod.month, lastPeriod.day);
    return lmp.add(const Duration(days: 280));
  }

  static int getDaysToDue(DateTime dueDate, DateTime today) {
    final current = DateTime(today.year, today.month, today.day);
    return dueDate.difference(current).inDays;
  }

  static int getMonths(int weeks) {
    return max(1, (weeks / 4.345).round());
  }

  static String getTrimester(int weeks) {
    if (weeks >= 27) return "Third";
    if (weeks >= 13) return "Second";
    return "First";
  }

  static double getLogoAngle(int elapsedDays) {
    return min(359.0, (elapsedDays / 280) * 360.0);
  }
}
