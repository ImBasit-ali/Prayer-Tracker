import 'prayer_day.dart';

/// Statistics model for prayer tracking
class PrayerStatistics {
  /// Total number of days tracked in the database
  final int totalDaysTracked;

  /// Number of days where all 5 prayers were completed
  final int completedDays;

  /// Number of days where at least one prayer was missed
  final int incompleteDays;

  /// Total number of individual prayers completed (across all days)
  final int totalPrayersCompleted;

  /// Total possible prayers (totalDaysTracked * 5)
  final int totalPossiblePrayers;

  /// Current streak of consecutive days with all prayers completed
  final int currentStreak;

  /// Longest streak of consecutive days with all prayers completed
  final int longestStreak;

  /// Completion percentage (0-100)
  final double completionPercentage;

  /// Start date of the tracked period
  final DateTime? startDate;

  /// End date of the tracked period
  final DateTime? endDate;

  const PrayerStatistics({
    required this.totalDaysTracked,
    required this.completedDays,
    required this.incompleteDays,
    required this.totalPrayersCompleted,
    required this.totalPossiblePrayers,
    required this.currentStreak,
    required this.longestStreak,
    required this.completionPercentage,
    this.startDate,
    this.endDate,
  });

  /// Create empty statistics
  factory PrayerStatistics.empty() {
    return const PrayerStatistics(
      totalDaysTracked: 0,
      completedDays: 0,
      incompleteDays: 0,
      totalPrayersCompleted: 0,
      totalPossiblePrayers: 0,
      currentStreak: 0,
      longestStreak: 0,
      completionPercentage: 0.0,
    );
  }

  /// Calculate statistics from a list of prayer days
  factory PrayerStatistics.fromPrayerDays(List<PrayerDay> prayerDays) {
    if (prayerDays.isEmpty) {
      return PrayerStatistics.empty();
    }

    // Sort by date
    final sortedDays = List<PrayerDay>.from(prayerDays)
      ..sort((a, b) => a.date.compareTo(b.date));

    final totalDays = sortedDays.length;
    final completedDays = sortedDays.where((d) => d.isCompleted).length;
    final incompleteDays = totalDays - completedDays;

    // Calculate total prayers completed
    int totalPrayers = 0;
    for (final day in sortedDays) {
      totalPrayers += day.completedCount;
    }

    final totalPossible = totalDays * 5;
    final percentage = totalPossible > 0
        ? (totalPrayers / totalPossible) * 100
        : 0.0;

    // Calculate streaks
    final streaks = _calculateStreaks(sortedDays);

    // Get date range
    final startDate = DateTime.parse(sortedDays.first.date);
    final endDate = DateTime.parse(sortedDays.last.date);

    return PrayerStatistics(
      totalDaysTracked: totalDays,
      completedDays: completedDays,
      incompleteDays: incompleteDays,
      totalPrayersCompleted: totalPrayers,
      totalPossiblePrayers: totalPossible,
      currentStreak: streaks['current']!,
      longestStreak: streaks['longest']!,
      completionPercentage: percentage,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Calculate current and longest streaks
  static Map<String, int> _calculateStreaks(List<PrayerDay> sortedDays) {
    if (sortedDays.isEmpty) {
      return {'current': 0, 'longest': 0};
    }

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    // Parse dates and check for consecutive completed days
    for (int i = 0; i < sortedDays.length; i++) {
      final day = sortedDays[i];

      if (day.isCompleted) {
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else {
        tempStreak = 0;
      }
    }

    // Calculate current streak (from most recent day backwards)
    final today = DateTime.now();
    final todayStr =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    for (int i = sortedDays.length - 1; i >= 0; i--) {
      final day = sortedDays[i];
      final dayDate = DateTime.parse(day.date);
      final expectedDate = today.subtract(Duration(days: currentStreak));

      // Check if this is a recent consecutive completed day
      if (day.isCompleted &&
          dayDate.year == expectedDate.year &&
          dayDate.month == expectedDate.month &&
          dayDate.day == expectedDate.day) {
        currentStreak++;
      } else if (day.date != todayStr) {
        // Only break if it's not today (today might be incomplete but still in progress)
        break;
      }
    }

    return {'current': currentStreak, 'longest': longestStreak};
  }
}
