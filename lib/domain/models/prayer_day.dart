import '../../data/models/prayer_day_entity.dart';

/// Domain model representing a prayer day (clean, database-agnostic)
class PrayerDay {
  final String date;
  final bool fajr;
  final bool dhuhr;
  final bool asr;
  final bool maghrib;
  final bool isha;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PrayerDay({
    required this.date,
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert from entity to domain model
  factory PrayerDay.fromEntity(PrayerDayEntity entity) {
    return PrayerDay(
      date: entity.date,
      fajr: entity.fajr,
      dhuhr: entity.dhuhr,
      asr: entity.asr,
      maghrib: entity.maghrib,
      isha: entity.isha,
      isCompleted: entity.isCompleted,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Convert to entity
  PrayerDayEntity toEntity() {
    return PrayerDayEntity(
      date: date,
      fajr: fajr,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: maghrib,
      isha: isha,
      isCompleted: isCompleted,
    );
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

  /// Create a copy with updated values
  PrayerDay copyWith({
    String? date,
    bool? fajr,
    bool? dhuhr,
    bool? asr,
    bool? maghrib,
    bool? isha,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrayerDay(
      date: date ?? this.date,
      fajr: fajr ?? this.fajr,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
