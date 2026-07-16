import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../logging/logger.dart';

/// Prayer times calculation service using Adhan library
class PrayerTimesService {
  static final PrayerTimesService _instance = PrayerTimesService._internal();
  factory PrayerTimesService() => _instance;
  PrayerTimesService._internal();

  // Storage keys
  static const String _keyLatitude = 'prayer_times_latitude';
  static const String _keyLongitude = 'prayer_times_longitude';
  static const String _keyCalculationMethod = 'prayer_times_calc_method';
  static const String _keyLocationName = 'prayer_times_location_name';

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        logger.info('Location services are disabled');
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          logger.info('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        logger.info('Location permission denied forever');
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );

      logger.info('Got location: ${position.latitude}, ${position.longitude}');

      // Save location
      await saveLocation(position.latitude, position.longitude);

      return position;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to get current location',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Save location to storage
  Future<void> saveLocation(
    double latitude,
    double longitude, [
    String? locationName,
  ]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLatitude, latitude);
    await prefs.setDouble(_keyLongitude, longitude);
    if (locationName != null) {
      await prefs.setString(_keyLocationName, locationName);
    }
    logger.info('Saved location: $latitude, $longitude');
  }

  /// Get saved location
  Future<Coordinates?> getSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_keyLatitude);
      final lng = prefs.getDouble(_keyLongitude);

      if (lat != null && lng != null) {
        return Coordinates(lat, lng);
      }
      return null;
    } catch (e) {
      logger.error('Failed to get saved location', error: e);
      return null;
    }
  }

  /// Get saved location name
  Future<String?> getSavedLocationName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLocationName);
  }

  /// Save calculation method
  Future<void> saveCalculationMethod(String method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCalculationMethod, method);
    logger.info('Saved calculation method: $method');
  }

  /// Get saved calculation method
  Future<String> getCalculationMethod() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCalculationMethod) ?? 'MuslimWorldLeague';
  }

  /// Get calculation parameters based on method name
  CalculationParameters getCalculationParameters(String method) {
    switch (method) {
      case 'MuslimWorldLeague':
        return CalculationMethod.muslim_world_league.getParameters();
      case 'Egyptian':
        return CalculationMethod.egyptian.getParameters();
      case 'Karachi':
        return CalculationMethod.karachi.getParameters();
      case 'UmmAlQura':
        return CalculationMethod.umm_al_qura.getParameters();
      case 'Dubai':
        return CalculationMethod.dubai.getParameters();
      case 'Qatar':
        return CalculationMethod.qatar.getParameters();
      case 'Kuwait':
        return CalculationMethod.kuwait.getParameters();
      case 'MoonsightingCommittee':
        return CalculationMethod.moon_sighting_committee.getParameters();
      case 'Singapore':
        return CalculationMethod.singapore.getParameters();
      case 'NorthAmerica':
        return CalculationMethod.north_america.getParameters();
      case 'Tehran':
        return CalculationMethod.tehran.getParameters();
      default:
        return CalculationMethod.muslim_world_league.getParameters();
    }
  }

  /// Calculate prayer times for today
  Future<Map<String, DateTime>?> getTodayPrayerTimes() async {
    try {
      // Get location (saved or current)
      Coordinates? coordinates = await getSavedLocation();

      if (coordinates == null) {
        final position = await getCurrentLocation();
        if (position == null) {
          logger.info('No location available for prayer times. Using default coordinates (Makkah).');
          // Default fallback coordinates for Makkah, Saudi Arabia
          coordinates = Coordinates(21.3891, 39.8579);
        } else {
          coordinates = Coordinates(position.latitude, position.longitude);
        }
      }

      // Get calculation method
      final methodName = await getCalculationMethod();
      final params = getCalculationParameters(methodName);

      // Calculate prayer times
      final date = DateTime.now();
      final dateComponents = DateComponents(date.year, date.month, date.day);
      final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

      final times = {
        'fajr': prayerTimes.fajr,
        'sunrise': prayerTimes.sunrise,
        'dhuhr': prayerTimes.dhuhr,
        'asr': prayerTimes.asr,
        'maghrib': prayerTimes.maghrib,
        'isha': prayerTimes.isha,
      };

      logger.info('Calculated prayer times for ${date.toString()}');
      logger.debug('Fajr: ${times['fajr']}');
      logger.debug('Dhuhr: ${times['dhuhr']}');
      logger.debug('Asr: ${times['asr']}');
      logger.debug('Maghrib: ${times['maghrib']}');
      logger.debug('Isha: ${times['isha']}');

      return times;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to calculate prayer times',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Calculate prayer times for a specific date
  Future<Map<String, DateTime>?> getPrayerTimesForDate(DateTime date) async {
    try {
      Coordinates? coordinates = await getSavedLocation();

      if (coordinates == null) {
        final position = await getCurrentLocation();
        if (position == null) {
          logger.info('No location available for prayer times on $date. Using default coordinates (Makkah).');
          // Default fallback coordinates for Makkah, Saudi Arabia
          coordinates = Coordinates(21.3891, 39.8579);
        } else {
          coordinates = Coordinates(position.latitude, position.longitude);
        }
      }

      final methodName = await getCalculationMethod();
      final params = getCalculationParameters(methodName);

      final dateComponents = DateComponents(date.year, date.month, date.day);
      final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

      return {
        'fajr': prayerTimes.fajr,
        'sunrise': prayerTimes.sunrise,
        'dhuhr': prayerTimes.dhuhr,
        'asr': prayerTimes.asr,
        'maghrib': prayerTimes.maghrib,
        'isha': prayerTimes.isha,
      };
    } catch (e, stackTrace) {
      logger.error(
        'Failed to calculate prayer times for date',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Get available calculation methods
  List<Map<String, String>> getAvailableMethods() {
    return [
      {'id': 'MuslimWorldLeague', 'name': 'Muslim World League'},
      {'id': 'Egyptian', 'name': 'Egyptian General Authority'},
      {'id': 'Karachi', 'name': 'University of Islamic Sciences, Karachi'},
      {'id': 'UmmAlQura', 'name': 'Umm Al-Qura University, Makkah'},
      {'id': 'Dubai', 'name': 'Dubai'},
      {'id': 'Qatar', 'name': 'Qatar'},
      {'id': 'Kuwait', 'name': 'Kuwait'},
      {'id': 'MoonsightingCommittee', 'name': 'Moonsighting Committee'},
      {'id': 'Singapore', 'name': 'Singapore'},
      {'id': 'NorthAmerica', 'name': 'Islamic Society of North America (ISNA)'},
      {'id': 'Tehran', 'name': 'Institute of Geophysics, University of Tehran'},
    ];
  }
}
