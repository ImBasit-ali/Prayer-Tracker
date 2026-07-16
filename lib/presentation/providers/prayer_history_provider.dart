import 'package:signals_flutter/signals_flutter.dart';
import 'package:intl/intl.dart';
import '../../domain/repositories/prayer_repository.dart';
import '../../domain/models/prayer_day.dart';
import '../../domain/models/prayer_statistics.dart';
import '../../core/logging/logger.dart';

/// Provider for managing prayer history and statistics
class PrayerHistoryProvider {
  final PrayerRepository _repository;

  PrayerHistoryProvider(this._repository);

  /// Signal for overall statistics
  final overallStatistics = signal<PrayerStatistics?>(null);

  /// Signal for current year statistics
  final yearStatistics = signal<PrayerStatistics?>(null);

  /// Signal for current month statistics
  final monthStatistics = signal<PrayerStatistics?>(null);

  /// Signal for monthly prayer history list
  final monthHistory = signal<List<PrayerDay>>([]);

  /// Signal for yearly prayer history list
  final yearHistory = signal<List<PrayerDay>>([]);

  /// Signal for backward compatibility
  final prayerHistory = signal<List<PrayerDay>>([]);

  /// Signal for loading state
  final isLoading = signal<bool>(false);

  /// Signal for error message
  final errorMessage = signal<String?>(null);

  /// Signal for selected year
  final selectedYear = signal<int>(DateTime.now().year);

  /// Signal for selected month
  final selectedMonth = signal<int>(DateTime.now().month);

  /// Initialize and load overall statistics
  Future<void> initialize() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final now = DateTime.now();
      selectedYear.value = now.year;
      selectedMonth.value = now.month;

      // Fetch all required data concurrently to optimize performance
      final results = await Future.wait([
        _repository.getStatistics(),
        _repository.getPrayerHistoryByYear(year: now.year),
        _repository.getPrayerHistory(year: now.year, month: now.month),
      ]);

      final overallStats = results[0] as PrayerStatistics;
      final yearHist = results[1] as List<PrayerDay>;
      final monthHist = results[2] as List<PrayerDay>;

      overallStatistics.value = overallStats;
      
      yearHistory.value = yearHist;
      yearStatistics.value = PrayerStatistics.fromPrayerDays(yearHist);

      monthHistory.value = monthHist;
      prayerHistory.value = monthHist; // Sync fallback signal
      monthStatistics.value = PrayerStatistics.fromPrayerDays(monthHist);

      logger.info('Prayer history provider initialized successfully (optimized)');
    } catch (e, stackTrace) {
      logger.error(
        'Failed to initialize prayer history provider',
        error: e,
        stackTrace: stackTrace,
      );
      errorMessage.value = 'Failed to load prayer history';
    } finally {
      isLoading.value = false;
    }
  }

  /// Load statistics for a specific year
  Future<void> loadYearStatistics(int year) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      selectedYear.value = year;

      // Load once and compute stats in memory to prevent double queries
      final history = await _repository.getPrayerHistoryByYear(year: year);
      yearHistory.value = history;
      yearStatistics.value = PrayerStatistics.fromPrayerDays(history);

      logger.info('Loaded statistics for year $year (optimized)');
    } catch (e, stackTrace) {
      logger.error(
        'Failed to load year statistics',
        error: e,
        stackTrace: stackTrace,
      );
      errorMessage.value = 'Failed to load year statistics';
    } finally {
      isLoading.value = false;
    }
  }

  /// Load statistics for a specific month
  Future<void> loadMonthStatistics(int year, int month) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      selectedYear.value = year;
      selectedMonth.value = month;

      // Load once and compute stats in memory to prevent double queries
      final history = await _repository.getPrayerHistory(
        year: year,
        month: month,
      );
      monthHistory.value = history;
      prayerHistory.value = history; // Sync fallback signal
      monthStatistics.value = PrayerStatistics.fromPrayerDays(history);

      logger.info('Loaded statistics for $year-$month (optimized)');
    } catch (e, stackTrace) {
      logger.error(
        'Failed to load month statistics',
        error: e,
        stackTrace: stackTrace,
      );
      errorMessage.value = 'Failed to load month statistics';
    } finally {
      isLoading.value = false;
    }
  }

  /// Load prayer history for a date range
  Future<void> loadDateRange(DateTime startDate, DateTime endDate) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final history = await _repository.getDateRangeHistory(
        startDate: startDate,
        endDate: endDate,
      );
      prayerHistory.value = history;

      logger.info('Loaded prayer history from $startDate to $endDate');
    } catch (e, stackTrace) {
      logger.error(
        'Failed to load date range history',
        error: e,
        stackTrace: stackTrace,
      );
      errorMessage.value = 'Failed to load prayer history';
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh all statistics
  Future<void> refresh() async {
    await initialize();
  }

  /// Go to previous year
  Future<void> previousYear() async {
    final startYear = overallStatistics.value?.startDate?.year ?? DateTime.now().year;
    if (selectedYear.value > startYear) {
      await loadYearStatistics(selectedYear.value - 1);
    } else {
      logger.warning('Cannot navigate to years before app start ($startYear)');
    }
  }

  /// Go to next year
  Future<void> nextYear() async {
    final currentYear = DateTime.now().year;
    if (selectedYear.value < currentYear) {
      await loadYearStatistics(selectedYear.value + 1);
    }
  }

  /// Go to previous month
  Future<void> previousMonth() async {
    int newMonth = selectedMonth.value - 1;
    int newYear = selectedYear.value;

    if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    }

    final startYear = overallStatistics.value?.startDate?.year ?? DateTime.now().year;
    final startMonth = overallStatistics.value?.startDate?.month ?? 1;

    if (newYear < startYear || (newYear == startYear && newMonth < startMonth)) {
      logger.warning('Cannot navigate to months before app start ($startYear-$startMonth)');
      return;
    }

    await loadMonthStatistics(newYear, newMonth);
  }

  /// Go to next month
  Future<void> nextMonth() async {
    final now = DateTime.now();
    int newMonth = selectedMonth.value + 1;
    int newYear = selectedYear.value;

    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    }

    // Don't allow future months
    if (newYear > now.year || (newYear == now.year && newMonth > now.month)) {
      logger.warning('Cannot navigate to future months');
      return;
    }

    await loadMonthStatistics(newYear, newMonth);
  }

  /// Toggle prayer completion status for a specific date
  Future<void> togglePrayerStatus({
    required String date,
    required String prayerKey,
    required bool currentStatus,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      // Update in repository
      await _repository.updatePrayerStatus(
        date: date,
        prayerName: prayerKey,
        isCompleted: !currentStatus,
      );

      // Refresh statistics and history lists concurrently
      final results = await Future.wait([
        _repository.getStatistics(),
        _repository.getPrayerHistoryByYear(year: selectedYear.value),
        _repository.getPrayerHistory(year: selectedYear.value, month: selectedMonth.value),
      ]);

      overallStatistics.value = results[0] as PrayerStatistics;
      
      final yearHist = results[1] as List<PrayerDay>;
      yearHistory.value = yearHist;
      yearStatistics.value = PrayerStatistics.fromPrayerDays(yearHist);

      final monthHist = results[2] as List<PrayerDay>;
      monthHistory.value = monthHist;
      prayerHistory.value = monthHist; // Sync fallback signal
      monthStatistics.value = PrayerStatistics.fromPrayerDays(monthHist);

      logger.info('Toggled prayer $prayerKey for date $date (optimized)');
    } catch (e, stackTrace) {
      logger.error('Failed to toggle prayer status', error: e, stackTrace: stackTrace);
      errorMessage.value = 'Failed to update prayer';
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh statistics for year and month concurrently without showing loading spinner
  Future<void> refreshYearAndMonth(int year, int month) async {
    try {
      errorMessage.value = null;

      final results = await Future.wait([
        _repository.getPrayerHistoryByYear(year: year),
        _repository.getPrayerHistory(year: year, month: month),
      ]);

      final yearHist = results[0];
      final monthHist = results[1];

      yearHistory.value = yearHist;
      yearStatistics.value = PrayerStatistics.fromPrayerDays(yearHist);

      monthHistory.value = monthHist;
      prayerHistory.value = monthHist;
      monthStatistics.value = PrayerStatistics.fromPrayerDays(monthHist);
    } catch (e, stackTrace) {
      logger.error('Failed to refresh year and month statistics', error: e, stackTrace: stackTrace);
      errorMessage.value = 'Failed to refresh statistics';
    }
  }

  /// Get formatted month name
  String getMonthName(int month) {
    final date = DateTime(2000, month, 1);
    return DateFormat('MMMM').format(date);
  }
}
