import 'package:isar/isar.dart';

part 'prayer_day_entity.g.dart';

/// Isar entity for storing daily prayer completion data
@collection
class PrayerDayEntity {
  /// Unique ID for the prayer day record
  Id id = Isar.autoIncrement;

  /// Date in yyyy-MM-dd format
  @Index(unique: true)
  late String date;

  /// Fajr prayer completed status
  @Index()
  late bool fajr;

  /// Dhuhr prayer completed status
  @Index()
  late bool dhuhr;

  /// Asr prayer completed status
  @Index()
  late bool asr;

  /// Maghrib prayer completed status
  @Index()
  late bool maghrib;

  /// Isha prayer completed status
  @Index()
  late bool isha;

  /// Indicates if all 5 prayers are completed for this day
  @Index()
  late bool isCompleted;

  /// Timestamp when the record was created
  late DateTime createdAt;

  /// Timestamp when the record was last updated
  late DateTime updatedAt;

  /// Constructor with default values
  PrayerDayEntity({
    this.id = Isar.autoIncrement,
    required this.date,
    this.fajr = false,
    this.dhuhr = false,
    this.asr = false,
    this.maghrib = false,
    this.isha = false,
    this.isCompleted = false,
  }) : createdAt = DateTime.now(),
       updatedAt = DateTime.now();

  /// Check if all prayers are completed and update isCompleted status
  void updateCompletionStatus() {
    isCompleted = fajr && dhuhr && asr && maghrib && isha;
    updatedAt = DateTime.now();
  }

  /// Get total number of prayers completed
  int get completedCount {
    int count = 0;
    if (fajr) count++;
    if (dhuhr) count++;
    if (asr) count++;
    if (maghrib) count++;
    if (isha) count++;
    return count;
  }
}
