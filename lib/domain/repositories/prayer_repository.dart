import '../models/prayer_day.dart';
import '../models/prayer_statistics.dart';

/// Abstract repository interface for prayer operations
abstract class PrayerRepository {
  /// Get prayer data for a specific date
  Future<PrayerDay?> getPrayerByDate(String date);

  /// Get today's prayer data (creates if not exists)
  Future<PrayerDay> getTodayPrayer();

  /// Update prayer status for a specific prayer
  Future<PrayerDay> updatePrayerStatus({
    required String date,
    required String prayerName,
    required bool isCompleted,
  });

  /// Get prayer history for a specific month
  Future<List<PrayerDay>> getPrayerHistory({
    required int year,
    required int month,
  });

  /// Get all completed days
  Future<List<PrayerDay>> getCompletedDays();

  /// Delete prayer record for a specific date
  Future<void> deletePrayerByDate(String date);

  /// Get prayer history for a specific year
  Future<List<PrayerDay>> getPrayerHistoryByYear({required int year});

  /// Get prayer history between two dates (inclusive)
  Future<List<PrayerDay>> getDateRangeHistory({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get overall prayer statistics
  Future<PrayerStatistics> getStatistics();

  /// Get statistics for a specific year
  Future<PrayerStatistics> getYearStatistics({required int year});

  /// Get statistics for a specific month
  Future<PrayerStatistics> getMonthStatistics({
    required int year,
    required int month,
  });
}
