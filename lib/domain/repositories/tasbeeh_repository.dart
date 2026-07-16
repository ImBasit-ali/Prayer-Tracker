import '../models/tasbeeh.dart';

/// Abstract repository interface for tasbeeh operations
abstract class TasbeehRepository {
  /// Get tasbeeh count for a specific date
  Future<Tasbeeh?> getTasbeehByDate(String date);

  /// Get today's tasbeeh count (creates if not exists)
  Future<Tasbeeh> getTodayTasbeeh();

  /// Increment tasbeeh count for today
  Future<Tasbeeh> incrementTasbeeh(String date);

  /// Reset tasbeeh count for a specific date
  Future<Tasbeeh> resetTasbeeh(String date);

  /// Get tasbeeh history (last N days)
  Future<List<Tasbeeh>> getTasbeehHistory({int limit = 30});

  /// Delete tasbeeh record for a specific date
  Future<void> deleteTasbeehByDate(String date);
}
