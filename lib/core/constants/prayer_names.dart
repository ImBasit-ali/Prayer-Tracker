/// Prayer names enum and constants
enum PrayerName { fajr, dhuhr, asr, maghrib, isha }

/// Extension methods for PrayerName enum
extension PrayerNameExtension on PrayerName {
  /// Get display name for the prayer
  String get displayName {
    switch (this) {
      case PrayerName.fajr:
        return 'Fajr';
      case PrayerName.dhuhr:
        return 'Dhuhr';
      case PrayerName.asr:
        return 'Asr';
      case PrayerName.maghrib:
        return 'Maghrib';
      case PrayerName.isha:
        return 'Isha';
    }
  }

  /// Get Arabic name for the prayer
  String get arabicName {
    switch (this) {
      case PrayerName.fajr:
        return 'فجر';
      case PrayerName.dhuhr:
        return 'ظهر';
      case PrayerName.asr:
        return 'عصر';
      case PrayerName.maghrib:
        return 'مغرب';
      case PrayerName.isha:
        return 'عشاء';
    }
  }

  /// Get emoji icon for the prayer
  String get emoji {
    switch (this) {
      case PrayerName.fajr:
        return '🌅'; // Sunrise
      case PrayerName.dhuhr:
        return '☀️'; // Sun
      case PrayerName.asr:
        return '🌤️'; // Sun behind cloud
      case PrayerName.maghrib:
        return '🌆'; // Sunset
      case PrayerName.isha:
        return '🌙'; // Moon
    }
  }

  /// Get database key name
  String get key {
    return name;
  }

  /// Get display name based on the day of the week (for Friday Jumu'ah)
  String getDisplayNameForDate(DateTime date) {
    // Check if it's Friday (weekday 5 in Dart)
    if (this == PrayerName.dhuhr && date.weekday == DateTime.friday) {
      return 'Jumu\'ah';
    }
    return displayName;
  }

  /// Get Arabic name based on the day of the week (for Friday Jumu'ah)
  String getArabicNameForDate(DateTime date) {
    // Check if it's Friday (weekday 5 in Dart)
    if (this == PrayerName.dhuhr && date.weekday == DateTime.friday) {
      return 'جمعة'; // Jumu'ah in Arabic
    }
    return arabicName;
  }

  /// Get emoji based on the day of the week (for Friday Jumu'ah)
  String getEmojiForDate(DateTime date) {
    // Check if it's Friday (weekday 5 in Dart)
    if (this == PrayerName.dhuhr && date.weekday == DateTime.friday) {
      return '🕌'; // Mosque emoji for Jumu'ah
    }
    return emoji;
  }
}

/// List of all prayers in order
const List<PrayerName> allPrayers = [
  PrayerName.fajr,
  PrayerName.dhuhr,
  PrayerName.asr,
  PrayerName.maghrib,
  PrayerName.isha,
];
