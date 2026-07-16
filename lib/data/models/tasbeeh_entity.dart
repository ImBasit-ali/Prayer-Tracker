import 'package:isar/isar.dart';

part 'tasbeeh_entity.g.dart';

/// Isar entity for storing daily tasbeeh (dhikr) counts
@collection
class TasbeehEntity {
  /// Unique ID for the tasbeeh record
  Id id = Isar.autoIncrement;

  /// Date in yyyy-MM-dd format
  @Index(unique: true)
  late String date;

  /// Total tasbeeh count for the day
  late int count;

  /// Timestamp when the record was created
  late DateTime createdAt;

  /// Timestamp when the record was last updated
  late DateTime updatedAt;

  /// Constructor with default values
  TasbeehEntity({
    this.id = Isar.autoIncrement,
    required this.date,
    this.count = 0,
  }) : createdAt = DateTime.now(),
       updatedAt = DateTime.now();

  /// Increment the count and update timestamp
  void increment() {
    count++;
    updatedAt = DateTime.now();
  }

  /// Reset the count to zero
  void reset() {
    count = 0;
    updatedAt = DateTime.now();
  }
}
