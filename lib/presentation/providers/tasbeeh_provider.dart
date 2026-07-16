import 'package:signals_flutter/signals_flutter.dart';
import 'package:intl/intl.dart';
import '../../domain/repositories/tasbeeh_repository.dart';
import '../../domain/models/tasbeeh.dart';
import '../../core/logging/logger.dart';

/// Tasbeeh state provider using signals_flutter
class TasbeehProvider {
  final TasbeehRepository _repository;

  TasbeehProvider(this._repository);

  /// Signal for current tasbeeh count
  final currentCount = signal<int>(0);

  /// Signal for tasbeeh history
  final history = signal<List<Tasbeeh>>([]);

  /// Signal for loading state
  final isLoading = signal<bool>(false);

  /// Signal for error message
  final errorMessage = signal<String?>(null);

  /// Signal for current date (yyyy-MM-dd)
  final currentDate = signal<String>('');

  /// Initialize and load today's tasbeeh
  Future<void> initialize() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final today = _formatDate(DateTime.now());
      currentDate.value = today;

      final tasbeeh = await _repository.getTodayTasbeeh();
      currentCount.value = tasbeeh.count;

      // Load history
      await loadHistory();

      logger.info('Tasbeeh provider initialized for date: $today');
    } catch (e, stackTrace) {
      logger.error(
        'Failed to initialize tasbeeh provider',
        error: e,
        stackTrace: stackTrace,
      );
      errorMessage.value = 'Failed to load tasbeeh data';
    } finally {
      isLoading.value = false;
    }
  }

  /// Increment tasbeeh count
  Future<void> increment() async {
    try {
      errorMessage.value = null;

      final today = _formatDate(DateTime.now());
      final updated = await _repository.incrementTasbeeh(today);

      currentCount.value = updated.count;

      logger.debug('Incremented tasbeeh. New count: ${updated.count}');
    } catch (e, stackTrace) {
      logger.error(
        'Failed to increment tasbeeh',
        error: e,
        stackTrace: stackTrace,
      );
      errorMessage.value = 'Failed to increment count';
    }
  }

  /// Reset tasbeeh counter display (does not update database/history)
  Future<void> reset() async {
    try {
      // Only reset the display counter, don't update database
      currentCount.value = 0;

      logger.info('Reset tasbeeh counter display (history unchanged)');
    } catch (e) {
      logger.error('Failed to reset counter', error: e);
      errorMessage.value = 'Failed to reset counter';
    }
  }

  /// Load tasbeeh history
  Future<void> loadHistory() async {
    try {
      final historyList = await _repository.getTasbeehHistory(limit: 30);
      history.value = historyList;

      logger.debug('Loaded ${historyList.length} tasbeeh history records');
    } catch (e, stackTrace) {
      logger.error(
        'Failed to load tasbeeh history',
        error: e,
        stackTrace: stackTrace,
      );
    }
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
}
