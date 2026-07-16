import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_prayer_tracker/core/constants/prayer_names.dart';

void main() {
  group('Friday Jumu\'ah Prayer Tests', () {
    test('Dhuhr shows as Jumu\'ah on Friday', () {
      // Create a Friday date (February 6, 2026 is a Friday)
      final friday = DateTime(2026, 2, 6);

      // Test display name
      expect(
        PrayerName.dhuhr.getDisplayNameForDate(friday),
        equals('Jumu\'ah'),
      );

      // Test Arabic name
      expect(PrayerName.dhuhr.getArabicNameForDate(friday), equals('جمعة'));

      // Test emoji
      expect(PrayerName.dhuhr.getEmojiForDate(friday), equals('🕌'));
    });

    test('Dhuhr shows normally on non-Friday days', () {
      // Create a Tuesday date (February 3, 2026 is a Tuesday)
      final tuesday = DateTime(2026, 2, 3);

      // Test display name
      expect(PrayerName.dhuhr.getDisplayNameForDate(tuesday), equals('Dhuhr'));

      // Test Arabic name
      expect(PrayerName.dhuhr.getArabicNameForDate(tuesday), equals('ظهر'));

      // Test emoji
      expect(PrayerName.dhuhr.getEmojiForDate(tuesday), equals('☀️'));
    });

    test('Other prayers are not affected on Friday', () {
      final friday = DateTime(2026, 2, 7);

      // Fajr should remain the same
      expect(PrayerName.fajr.getDisplayNameForDate(friday), equals('Fajr'));

      // Asr should remain the same
      expect(PrayerName.asr.getDisplayNameForDate(friday), equals('Asr'));

      // Maghrib should remain the same
      expect(
        PrayerName.maghrib.getDisplayNameForDate(friday),
        equals('Maghrib'),
      );

      // Isha should remain the same
      expect(PrayerName.isha.getDisplayNameForDate(friday), equals('Isha'));
    });

    test('Weekday detection works correctly', () {
      // Test all days of the week
      final monday = DateTime(2026, 2, 2);
      final tuesday = DateTime(2026, 2, 3);
      final wednesday = DateTime(2026, 2, 4);
      final thursday = DateTime(2026, 2, 5);
      final friday = DateTime(2026, 2, 6);
      final saturday = DateTime(2026, 2, 7);
      final sunday = DateTime(2026, 2, 8);

      // Only Friday should show Jumu'ah
      expect(PrayerName.dhuhr.getDisplayNameForDate(monday), equals('Dhuhr'));
      expect(PrayerName.dhuhr.getDisplayNameForDate(tuesday), equals('Dhuhr'));
      expect(
        PrayerName.dhuhr.getDisplayNameForDate(wednesday),
        equals('Dhuhr'),
      );
      expect(PrayerName.dhuhr.getDisplayNameForDate(thursday), equals('Dhuhr'));
      expect(
        PrayerName.dhuhr.getDisplayNameForDate(friday),
        equals('Jumu\'ah'),
      );
      expect(PrayerName.dhuhr.getDisplayNameForDate(saturday), equals('Dhuhr'));
      expect(PrayerName.dhuhr.getDisplayNameForDate(sunday), equals('Dhuhr'));
    });
  });
}
