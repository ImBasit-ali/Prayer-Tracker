import 'package:shared_preferences/shared_preferences.dart';
import '../logging/logger.dart';

/// Prayer times service managing manual configurations
class PrayerTimesService {
  static final PrayerTimesService _instance = PrayerTimesService._internal();
  factory PrayerTimesService() => _instance;
  PrayerTimesService._internal();

  // Storage keys for manual times
  static const String keyManualFajr = 'manual_prayer_fajr';
  static const String keyManualDhuhr = 'manual_prayer_dhuhr';
  static const String keyManualAsr = 'manual_prayer_asr';
  static const String keyManualMaghrib = 'manual_prayer_maghrib';
  static const String keyManualIsha = 'manual_prayer_isha';

  /// Get manual time string (HH:mm)
  Future<String> getManualTime(String key, String defaultTime) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? defaultTime;
  }

  /// Save manual time string (HH:mm)
  Future<void> saveManualTime(String key, String timeStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, timeStr);
    logger.info('Saved manual time: $key = $timeStr');
  }

  /// Get manual prayer times map for a specific date
  Future<Map<String, DateTime>> getManualPrayerTimesForDate(DateTime date) async {
    final fajrStr = await getManualTime(keyManualFajr, '05:00');
    final dhuhrStr = await getManualTime(keyManualDhuhr, '12:30');
    final asrStr = await getManualTime(keyManualAsr, '15:45');
    final maghribStr = await getManualTime(keyManualMaghrib, '19:00');
    final ishaStr = await getManualTime(keyManualIsha, '20:30');

    DateTime parseTime(String timeStr) {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(date.year, date.month, date.day, hour, minute);
    }

    final fajr = parseTime(fajrStr);
    final dhuhr = parseTime(dhuhrStr);
    final asr = parseTime(asrStr);
    final maghrib = parseTime(maghribStr);
    final isha = parseTime(ishaStr);
    
    // Mock sunrise as 1.5 hours after Fajr
    final sunrise = fajr.add(const Duration(minutes: 90));

    return {
      'fajr': fajr,
      'sunrise': sunrise,
      'dhuhr': dhuhr,
      'asr': asr,
      'maghrib': maghrib,
      'isha': isha,
    };
  }

  /// Calculate prayer times for today
  Future<Map<String, DateTime>?> getTodayPrayerTimes() async {
    try {
      final times = await getManualPrayerTimesForDate(DateTime.now());
      logger.info('Calculated manual prayer times for today');
      return times;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to calculate manual prayer times',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Calculate prayer times for a specific date
  Future<Map<String, DateTime>?> getPrayerTimesForDate(DateTime date) async {
    try {
      return await getManualPrayerTimesForDate(date);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to calculate manual prayer times for date',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
