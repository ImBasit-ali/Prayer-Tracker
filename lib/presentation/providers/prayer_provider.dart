import 'package:signals_flutter/signals_flutter.dart';
import 'package:intl/intl.dart';
import '../../domain/repositories/prayer_repository.dart';
import '../../domain/models/prayer_day.dart';
import '../../core/logging/logger.dart';
import '../../core/constants/prayer_names.dart';

/// Prayer state provider using signals_flutter
class PrayerProvider {
  final PrayerRepository _repository;

  PrayerProvider(this._repository);

  /// Signal for current prayer day
  final currentPrayerDay = signal<PrayerDay?>(null);

  /// Signal for loading state
  final isLoading = signal<bool>(false);

  /// Signal for error message
  final errorMessage = signal<String?>(null);

  /// Signal for current date (yyyy-MM-dd)
  final currentDate = signal<String>('');

  /// Initialize and load today's prayers
  Future<void> initialize() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final today = _formatDate(DateTime.now());
      currentDate.value = today;

      final prayerDay = await _repository.getTodayPrayer();
      currentPrayerDay.value = prayerDay;

      logger.info('Prayer provider initialized for date: $today');
    } catch (e, stackTrace) {
      logger.error(
        'Failed to initialize prayer provider',
        error: e,
        stackTrace: stackTrace,
      );
      errorMessage.value = 'Failed to load prayer data';
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggle prayer completion status
  Future<void> togglePrayer(PrayerName prayer) async {
    try {
      final current = currentPrayerDay.value;
      if (current == null) {
        logger.warning('Cannot toggle prayer: current prayer day is null');
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;

      // Get current status
      final currentStatus = _getPrayerStatus(current, prayer);

      // Update in repository
      final updated = await _repository.updatePrayerStatus(
        date: current.date,
        prayerName: prayer.key,
        isCompleted: !currentStatus,
      );

      // Update signal
      currentPrayerDay.value = updated;

      logger.info('Toggled ${prayer.displayName}: ${!currentStatus}');
    } catch (e, stackTrace) {
      logger.error('Failed to toggle prayer', error: e, stackTrace: stackTrace);
      errorMessage.value = 'Failed to update prayer';
    } finally {
      isLoading.value = false;
    }
  }

  /// Get prayer status from prayer day
  bool _getPrayerStatus(PrayerDay prayerDay, PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:
        return prayerDay.fajr;
      case PrayerName.dhuhr:
        return prayerDay.dhuhr;
      case PrayerName.asr:
        return prayerDay.asr;
      case PrayerName.maghrib:
        return prayerDay.maghrib;
      case PrayerName.isha:
        return prayerDay.isha;
    }
  }

  /// Check if a specific prayer is completed
  bool isPrayerCompleted(PrayerName prayer) {
    final current = currentPrayerDay.value;
    if (current == null) return false;
    return _getPrayerStatus(current, prayer);
  }

  /// Check if all prayers are completed for today
  bool get isAllPrayersCompleted {
    return currentPrayerDay.value?.isCompleted ?? false;
  }

  /// Get completion count
  int get completedCount {
    return currentPrayerDay.value?.completedCount ?? 0;
  }

  /// Refresh data (call when date changes)
  Future<void> refresh() async {
    final newDate = _formatDate(DateTime.now());
    if (newDate != currentDate.value) {
      logger.info(
        'Date changed from ${currentDate.value} to $newDate. Refreshing...',
      );
      await initialize();
    }
  }

  /// Format date to yyyy-MM-dd
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Selected/viewing date (for history navigation)
  final selectedDate = signal<DateTime>(DateTime.now());

  /// Check if viewing today
  bool get isViewingToday {
    final today = _formatDate(DateTime.now());
    final viewing = _formatDate(selectedDate.value);
    return today == viewing;
  }

  /// Load prayer data for a specific date
  Future<void> loadDateData(DateTime date) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      selectedDate.value = date;
      final dateStr = _formatDate(date);
      currentDate.value = dateStr;

      var prayerDay = await _repository.getPrayerByDate(dateStr);
      if (prayerDay == null) {
        final now = DateTime.now();
        prayerDay = PrayerDay(
          date: dateStr,
          fajr: false,
          dhuhr: false,
          asr: false,
          maghrib: false,
          isha: false,
          isCompleted: false,
          createdAt: now,
          updatedAt: now,
        );
      }
      currentPrayerDay.value = prayerDay;

      logger.info('Loaded prayer data for date: $dateStr');
    } catch (e, stackTrace) {
      logger.error(
        'Failed to load prayer data for date',
        error: e,
        stackTrace: stackTrace,
      );
      errorMessage.value = 'Failed to load prayer data';
    } finally {
      isLoading.value = false;
    }
  }

  /// Go to previous day
  Future<void> goToPreviousDay() async {
    final previousDay = selectedDate.value.subtract(const Duration(days: 1));
    await loadDateData(previousDay);
  }

  /// Go to next day
  Future<void> goToNextDay() async {
    // Don't allow future dates
    final nextDay = selectedDate.value.add(const Duration(days: 1));
    final today = DateTime.now();

    if (nextDay.isAfter(DateTime(today.year, today.month, today.day, 23, 59))) {
      logger.warning('Cannot navigate to future dates');
      return;
    }

    await loadDateData(nextDay);
  }

  /// Go to today
  Future<void> goToToday() async {
    await loadDateData(DateTime.now());
  }

  /// Go to specific date
  Future<void> goToDate(DateTime date) async {
    // Don't allow future dates
    final today = DateTime.now();
    if (date.isAfter(DateTime(today.year, today.month, today.day, 23, 59))) {
      logger.warning('Cannot select future dates');
      errorMessage.value = 'Cannot select future dates';
      return;
    }

    await loadDateData(date);
  }
}
