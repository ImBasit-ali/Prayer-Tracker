import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/prayer_times_service.dart';
import 'prayer_history_screen.dart';

/// Settings screen for app configuration
class SettingsScreen extends HookWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationsEnabled = useState(false);
    final calculationMethod = useState('MuslimWorldLeague');
    final locationName = useState<String?>(null);
    final isLoading = useState(false);

    // Load settings on mount
    useEffect(() {
      Future<void> loadSettings() async {
        final prefs = await SharedPreferences.getInstance();
        notificationsEnabled.value =
            prefs.getBool('notifications_enabled') ?? false;
        calculationMethod.value = await PrayerTimesService()
            .getCalculationMethod();
        locationName.value = await PrayerTimesService().getSavedLocationName();
      }

      loadSettings();
      return null;
    }, []);

    Future<void> saveNotificationsSetting(bool enabled) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', enabled);
      notificationsEnabled.value = enabled;

      if (enabled) {
        // Request permissions and schedule notifications
        final service = NotificationService();
        final granted = await service.requestPermissions();

        if (granted) {
          final prayerTimes = await PrayerTimesService().getTodayPrayerTimes();
          if (prayerTimes != null) {
            await service.scheduleAllPrayers(prayerTimes);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Prayer notifications enabled!')),
              );
            }
          }
        } else {
          notificationsEnabled.value = false;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Permission denied. Please enable notifications in settings.',
                ),
              ),
            );
          }
        }
      } else {
        await NotificationService().cancelAllNotifications();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prayer notifications disabled')),
          );
        }
      }
    }

    Future<void> updateCalculationMethod(String method) async {
      await PrayerTimesService().saveCalculationMethod(method);
      calculationMethod.value = method;

      // Reschedule notifications if enabled
      if (notificationsEnabled.value) {
        final prayerTimes = await PrayerTimesService().getTodayPrayerTimes();
        if (prayerTimes != null) {
          await NotificationService().cancelAllNotifications();
          await NotificationService().scheduleAllPrayers(prayerTimes);
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Calculation method updated to: $method')),
        );
      }
    }

    Future<void> updateLocation() async {
      isLoading.value = true;

      final position = await PrayerTimesService().getCurrentLocation();

      if (position != null) {
        locationName.value =
            'GPS: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';

        // Reschedule notifications if enabled
        if (notificationsEnabled.value) {
          final prayerTimes = await PrayerTimesService().getTodayPrayerTimes();
          if (prayerTimes != null) {
            await NotificationService().cancelAllNotifications();
            await NotificationService().scheduleAllPrayers(prayerTimes);
          }
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location updated successfully!')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to get location. Please enable location services.',
              ),
            ),
          );
        }
      }

      isLoading.value = false;
    }

    Future<void> showPrayerTimes() async {
      final times = await PrayerTimesService().getTodayPrayerTimes();

      if (times != null && context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Today\'s Prayer Times'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimeRow('Fajr', times['fajr']!),
                _buildTimeRow('Sunrise', times['sunrise']!),
                _buildTimeRow('Dhuhr', times['dhuhr']!),
                _buildTimeRow('Asr', times['asr']!),
                _buildTimeRow('Maghrib', times['maghrib']!),
                _buildTimeRow('Isha', times['isha']!),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        children: [
          // Notifications Section
          const ListTile(
            title: Text(
              'Notifications',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          SwitchListTile(
            title: const Text('Prayer Time Notifications'),
            subtitle: const Text('Get notified at each prayer time'),
            value: notificationsEnabled.value,
            onChanged: saveNotificationsSetting,
            secondary: const Icon(Icons.notifications_active),
          ),
          ListTile(
            title: const Text('Test Notification'),
            subtitle: const Text('Send a test notification now'),
            leading: const Icon(Icons.notification_add),
            onTap: () async {
              await NotificationService().showTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test notification sent!')),
                );
              }
            },
          ),

          // const Divider(),

          // // Location Section
          // const ListTile(
          //   title: Text(
          //     'Location',
          //     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          //   ),
          // ),
          // ListTile(
          //   title: const Text('Current Location'),
          //   subtitle: Text(locationName.value ?? 'Not set'),
          //   leading: const Icon(Icons.location_on),
          // ),
          // ListTile(
          //   title: const Text('Update Location'),
          //   subtitle: const Text('Use GPS to get current location'),
          //   leading: isLoading.value
          //       ? const SizedBox(
          //           width: 24,
          //           height: 24,
          //           child: CircularProgressIndicator(strokeWidth: 2),
          //         )
          //       : const Icon(Icons.my_location),
          //   onTap: isLoading.value ? null : updateLocation,
          // ),

          const Divider(),

          // Calculation Method Section
          const ListTile(
            title: Text(
              'Prayer Time Calculation',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          ListTile(
            title: const Text('Calculation Method'),
            subtitle: Text(_getMethodDisplayName(calculationMethod.value)),
            leading: const Icon(Icons.calculate),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Select Calculation Method'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: PrayerTimesService()
                          .getAvailableMethods()
                          .map(
                            (method) => RadioListTile<String>(
                              title: Text(method['name']!),
                              value: method['id']!,
                              groupValue: calculationMethod.value,
                              onChanged: (value) {
                                if (value != null) {
                                  updateCalculationMethod(value);
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('View Prayer Times'),
            subtitle: const Text('See today\'s prayer times'),
            leading: const Icon(Icons.access_time),
            onTap: showPrayerTimes,
          ),

          const Divider(),

          // Prayer History Section
          const ListTile(
            title: Text(
              'Prayer History',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          ListTile(
            title: const Text('View Prayer History'),
            subtitle: const Text('Track your prayer completion over time'),
            leading: const Icon(Icons.history),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrayerHistoryScreen(),
                ),
              );
            },
          ),
       

          const Divider(),

          // App Info
          const ListTile(
            title: Text(
              'About',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const ListTile(
            title: Text('Muslim Prayer Tracker'),
            subtitle: Text(
              'Version 1.0.0\nTrack your daily prayers and tasbeeh',
            ),
            leading: Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(String name, DateTime time) {
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(timeStr),
        ],
      ),
    );
  }

  String _getMethodDisplayName(String id) {
    final methods = PrayerTimesService().getAvailableMethods();
    final method = methods.firstWhere(
      (m) => m['id'] == id,
      orElse: () => {'name': 'Muslim World League'},
    );
    return method['name']!;
  }
}
