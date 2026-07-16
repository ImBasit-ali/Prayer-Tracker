import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import '../../domain/repositories/prayer_repository.dart';
import '../../domain/models/prayer_day.dart';
import '../../domain/models/prayer_statistics.dart';
import '../models/prayer_day_entity.dart';
import '../../core/database/isar_service.dart';
import '../../core/logging/logger.dart';

/// Implementation of PrayerRepository using Isar database
class PrayerRepositoryImpl implements PrayerRepository {
  final IsarService _isarService;

  PrayerRepositoryImpl(this._isarService);

  /// Get formatted date string (yyyy-MM-dd)
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Future<PrayerDay?> getPrayerByDate(String date) async {
    try {
      final isar = await _isarService.database;
      final entity = await isar.prayerDayEntitys
          .filter()
          .dateEqualTo(date)
          .findFirst();

      if (entity == null) {
        logger.debug('No prayer data found for date: $date');
        return null;
      }

      return PrayerDay.fromEntity(entity);
    } catch (e, stackTrace) {
      logger.error(
        'Error getting prayer by date: $date',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<PrayerDay> getTodayPrayer() async {
    try {
      final today = _formatDate(DateTime.now());
      final existing = await getPrayerByDate(today);

      if (existing != null) {
        return existing;
      }

      // Create new prayer record for today
      logger.info('Creating new prayer record for today: $today');
      final isar = await _isarService.database;
      final entity = PrayerDayEntity(
        date: today,
        fajr: false,
        dhuhr: false,
        asr: false,
        maghrib: false,
        isha: false,
        isCompleted: false,
      );

      await isar.writeTxn(() async {
        await isar.prayerDayEntitys.put(entity);
      });

      return PrayerDay.fromEntity(entity);
    } catch (e, stackTrace) {
      logger.error(
        'Error getting today prayer',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<PrayerDay> updatePrayerStatus({
    required String date,
    required String prayerName,
    required bool isCompleted,
  }) async {
    try {
      final isar = await _isarService.database;

      // Get existing record or create new one
      PrayerDayEntity? entity = await isar.prayerDayEntitys
          .filter()
          .dateEqualTo(date)
          .findFirst();

      if (entity == null) {
        entity = PrayerDayEntity(date: date);
      }

      // Update the specific prayer
      switch (prayerName.toLowerCase()) {
        case 'fajr':
          entity.fajr = isCompleted;
          break;
        case 'dhuhr':
          entity.dhuhr = isCompleted;
          break;
        case 'asr':
          entity.asr = isCompleted;
          break;
        case 'maghrib':
          entity.maghrib = isCompleted;
          break;
        case 'isha':
          entity.isha = isCompleted;
          break;
        default:
          throw ArgumentError('Invalid prayer name: $prayerName');
      }

      // Update completion status
      entity.updateCompletionStatus();

      // Save to database
      await isar.writeTxn(() async {
        await isar.prayerDayEntitys.put(entity!);
      });

      logger.info(
        'Updated $prayerName to $isCompleted for date $date. Day completed: ${entity.isCompleted}',
      );
      return PrayerDay.fromEntity(entity);
    } catch (e, stackTrace) {
      logger.error(
        'Error updating prayer status',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<List<PrayerDay>> getPrayerHistory({
    required int year,
    required int month,
  }) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0); // Last day of month

      final startDateStr = _formatDate(startDate);
      final endDateStr = _formatDate(endDate);

      final isar = await _isarService.database;
      final entities = await isar.prayerDayEntitys
          .filter()
          .dateBetween(startDateStr, endDateStr)
          .sortByDate()
          .findAll();

      logger.debug('Found ${entities.length} prayer records for $year-$month');
      return entities.map((e) => PrayerDay.fromEntity(e)).toList();
    } catch (e, stackTrace) {
      logger.error(
        'Error getting prayer history',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<List<PrayerDay>> getCompletedDays() async {
    try {
      final isar = await _isarService.database;
      final entities = await isar.prayerDayEntitys
          .filter()
          .isCompletedEqualTo(true)
          .sortByDateDesc()
          .findAll();

      logger.debug('Found ${entities.length} completed prayer days');
      return entities.map((e) => PrayerDay.fromEntity(e)).toList();
    } catch (e, stackTrace) {
      logger.error(
        'Error getting completed days',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> deletePrayerByDate(String date) async {
    try {
      final isar = await _isarService.database;
      await isar.writeTxn(() async {
        final entity = await isar.prayerDayEntitys
            .filter()
            .dateEqualTo(date)
            .findFirst();

        if (entity != null) {
          await isar.prayerDayEntitys.delete(entity.id);
          logger.info('Deleted prayer record for date: $date');
        }
      });
    } catch (e, stackTrace) {
      logger.error(
        'Error deleting prayer by date',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<List<PrayerDay>> getPrayerHistoryByYear({required int year}) async {
    try {
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year, 12, 31);

      final startDateStr = _formatDate(startDate);
      final endDateStr = _formatDate(endDate);

      final isar = await _isarService.database;
      final entities = await isar.prayerDayEntitys
          .filter()
          .dateBetween(startDateStr, endDateStr)
          .sortByDate()
          .findAll();

      logger.debug('Found ${entities.length} prayer records for year $year');
      return entities.map((e) => PrayerDay.fromEntity(e)).toList();
    } catch (e, stackTrace) {
      logger.error(
        'Error getting prayer history by year',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<List<PrayerDay>> getDateRangeHistory({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startDateStr = _formatDate(startDate);
      final endDateStr = _formatDate(endDate);

      final isar = await _isarService.database;
      final entities = await isar.prayerDayEntitys
          .filter()
          .dateBetween(startDateStr, endDateStr)
          .sortByDate()
          .findAll();

      logger.debug(
        'Found ${entities.length} prayer records between $startDateStr and $endDateStr',
      );
      return entities.map((e) => PrayerDay.fromEntity(e)).toList();
    } catch (e, stackTrace) {
      logger.error(
        'Error getting date range history',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<PrayerStatistics> getStatistics() async {
    try {
      final isar = await _isarService.database;
      final allEntities = await isar.prayerDayEntitys
          .where()
          .sortByDate()
          .findAll();

      final prayerDays = allEntities
          .map((e) => PrayerDay.fromEntity(e))
          .toList();
      final statistics = PrayerStatistics.fromPrayerDays(prayerDays);

      logger.debug(
        'Calculated overall statistics: ${prayerDays.length} total days',
      );
      return statistics;
    } catch (e, stackTrace) {
      logger.error(
        'Error getting statistics',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<PrayerStatistics> getYearStatistics({required int year}) async {
    try {
      final prayerDays = await getPrayerHistoryByYear(year: year);
      final statistics = PrayerStatistics.fromPrayerDays(prayerDays);

      logger.debug(
        'Calculated year $year statistics: ${prayerDays.length} total days',
      );
      return statistics;
    } catch (e, stackTrace) {
      logger.error(
        'Error getting year statistics',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<PrayerStatistics> getMonthStatistics({
    required int year,
    required int month,
  }) async {
    try {
      final prayerDays = await getPrayerHistory(year: year, month: month);
      final statistics = PrayerStatistics.fromPrayerDays(prayerDays);

      logger.debug(
        'Calculated month $year-$month statistics: ${prayerDays.length} total days',
      );
      return statistics;
    } catch (e, stackTrace) {
      logger.error(
        'Error getting month statistics',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
