import '../../data/models/tasbeeh_entity.dart';

/// Domain model representing tasbeeh counter (clean, database-agnostic)
class Tasbeeh {
  final String date;
  final int count;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Tasbeeh({
    required this.date,
    required this.count,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert from entity to domain model
  factory Tasbeeh.fromEntity(TasbeehEntity entity) {
    return Tasbeeh(
      date: entity.date,
      count: entity.count,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Convert to entity
  TasbeehEntity toEntity() {
    return TasbeehEntity(date: date, count: count);
  }

  /// Create a copy with updated values
  Tasbeeh copyWith({
    String? date,
    int? count,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tasbeeh(
      date: date ?? this.date,
      count: count ?? this.count,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
