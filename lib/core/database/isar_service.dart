import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/prayer_day_entity.dart';
import '../../data/models/tasbeeh_entity.dart';
import '../logging/logger.dart';

/// Service for managing Isar database instance
class IsarService {
  static IsarService? _instance;
  static Isar? _isar;

  IsarService._();

  /// Get singleton instance of IsarService
  static IsarService get instance {
    _instance ??= IsarService._();
    return _instance!;
  }

  /// Get Isar database instance
  Future<Isar> get database async {
    if (_isar != null) {
      return _isar!;
    }
    await _init();
    return _isar!;
  }

  /// Initialize Isar database
  Future<void> _init() async {
    try {
      logger.info('Initializing Isar database...');

      final dir = await getApplicationDocumentsDirectory();

      _isar = await Isar.open(
        [PrayerDayEntitySchema, TasbeehEntitySchema],
        directory: dir.path,
        name: 'muslim_prayer_tracker',
        inspector: true, // Enable Isar Inspector for debugging
      );

      logger.info('Isar database initialized successfully at: ${dir.path}');
    } catch (e, stackTrace) {
      logger.error(
        'Failed to initialize Isar database',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Close the database
  Future<void> close() async {
    if (_isar != null) {
      await _isar!.close();
      _isar = null;
      logger.info('Isar database closed');
    }
  }

  /// Clear all data from database (for testing purposes)
  Future<void> clearAll() async {
    try {
      final db = await database;
      await db.writeTxn(() async {
        await db.clear();
      });
      logger.info('All database data cleared');
    } catch (e, stackTrace) {
      logger.error(
        'Failed to clear database',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
