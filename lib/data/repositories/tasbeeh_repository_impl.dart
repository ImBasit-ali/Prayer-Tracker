import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import '../../domain/repositories/tasbeeh_repository.dart';
import '../../domain/models/tasbeeh.dart';
import '../models/tasbeeh_entity.dart';
import '../../core/database/isar_service.dart';
import '../../core/logging/logger.dart';

/// Implementation of TasbeehRepository using Isar database
class TasbeehRepositoryImpl implements TasbeehRepository {
  final IsarService _isarService;

  TasbeehRepositoryImpl(this._isarService);

  /// Get formatted date string (yyyy-MM-dd)
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Future<Tasbeeh?> getTasbeehByDate(String date) async {
    try {
      final isar = await _isarService.database;
      final entity = await isar.tasbeehEntitys
          .filter()
          .dateEqualTo(date)
          .findFirst();

      if (entity == null) {
        logger.debug('No tasbeeh data found for date: $date');
        return null;
      }

      return Tasbeeh.fromEntity(entity);
    } catch (e, stackTrace) {
      logger.error(
        'Error getting tasbeeh by date: $date',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<Tasbeeh> getTodayTasbeeh() async {
    try {
      final today = _formatDate(DateTime.now());
      final existing = await getTasbeehByDate(today);

      if (existing != null) {
        return existing;
      }

      // Create new tasbeeh record for today
      logger.info('Creating new tasbeeh record for today: $today');
      final isar = await _isarService.database;
      final entity = TasbeehEntity(date: today, count: 0);

      await isar.writeTxn(() async {
        await isar.tasbeehEntitys.put(entity);
      });

      return Tasbeeh.fromEntity(entity);
    } catch (e, stackTrace) {
      logger.error(
        'Error getting today tasbeeh',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<Tasbeeh> incrementTasbeeh(String date) async {
    try {
      final isar = await _isarService.database;

      // Get existing record or create new one
      TasbeehEntity? entity = await isar.tasbeehEntitys
          .filter()
          .dateEqualTo(date)
          .findFirst();

      if (entity == null) {
        entity = TasbeehEntity(date: date, count: 0);
      }

      // Increment count
      entity.increment();

      // Save to database
      await isar.writeTxn(() async {
        await isar.tasbeehEntitys.put(entity!);
      });

      logger.debug('Incremented tasbeeh for $date. New count: ${entity.count}');
      return Tasbeeh.fromEntity(entity);
    } catch (e, stackTrace) {
      logger.error(
        'Error incrementing tasbeeh',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<Tasbeeh> resetTasbeeh(String date) async {
    try {
      final isar = await _isarService.database;

      // Get existing record or create new one
      TasbeehEntity? entity = await isar.tasbeehEntitys
          .filter()
          .dateEqualTo(date)
          .findFirst();

      if (entity == null) {
        entity = TasbeehEntity(date: date, count: 0);
      } else {
        entity.reset();
      }

      // Save to database
      await isar.writeTxn(() async {
        await isar.tasbeehEntitys.put(entity!);
      });

      logger.info('Reset tasbeeh for $date');
      return Tasbeeh.fromEntity(entity);
    } catch (e, stackTrace) {
      logger.error('Error resetting tasbeeh', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Tasbeeh>> getTasbeehHistory({int limit = 30}) async {
    try {
      final isar = await _isarService.database;
      final entities = await isar.tasbeehEntitys
          .where()
          .sortByDateDesc()
          .limit(limit)
          .findAll();

      logger.debug('Found ${entities.length} tasbeeh records');
      return entities.map((e) => Tasbeeh.fromEntity(e)).toList();
    } catch (e, stackTrace) {
      logger.error(
        'Error getting tasbeeh history',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteTasbeehByDate(String date) async {
    try {
      final isar = await _isarService.database;
      await isar.writeTxn(() async {
        final entity = await isar.tasbeehEntitys
            .filter()
            .dateEqualTo(date)
            .findFirst();

        if (entity != null) {
          await isar.tasbeehEntitys.delete(entity.id);
          logger.info('Deleted tasbeeh record for date: $date');
        }
      });
    } catch (e, stackTrace) {
      logger.error(
        'Error deleting tasbeeh by date',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
