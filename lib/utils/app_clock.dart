class AppClock {
  static DateTime? _fixedTime;

  /// Returns the current time, or a fixed time if set.
  static DateTime now() {
    return _fixedTime ?? DateTime.now();
  }

  /// Sets a fixed time for testing.
  static void setFixedTime(DateTime time) {
    _fixedTime = time;
  }

  /// Resets the clock to real time.
  static void reset() {
    _fixedTime = null;
  }
}
