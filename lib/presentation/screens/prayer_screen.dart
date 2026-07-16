import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:intl/intl.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../core/constants/prayer_names.dart';
import '../../core/database/isar_service.dart';
import '../../data/repositories/prayer_repository_impl.dart';
import '../providers/prayer_provider.dart';
import '../widgets/prayer_card.dart';
import '../widgets/date_display.dart';
import '../widgets/completion_indicator.dart';

/// Prayer tracking screen
class PrayerScreen extends HookWidget {
  const PrayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Create provider instance
    final provider = useMemoized(
      () => PrayerProvider(PrayerRepositoryImpl(IsarService.instance)),
    );

    // Initialize on first build
    useEffect(() {
      provider.initialize();
      return null;
    }, []);

    // Watch prayer day signal
    final prayerDay = provider.currentPrayerDay.watch(context);
    final isLoading = provider.isLoading.watch(context);
    final errorMsg = provider.errorMessage.watch(context);

    // Create periodic timer for date change detection
    useEffect(() {
      final timer = Stream.periodic(const Duration(minutes: 1)).listen((_) {
        provider.refresh();
      });
      return timer.cancel;
    }, []);

    return VisibilityDetector(
      key: const Key('prayer-screen'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5) {
          // Screen is visible, refresh data
          provider.refresh();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Daily Prayers', style: TextStyle(fontSize: 18)),
          centerTitle: true,
          elevation: 0,
        ),
        body: RefreshIndicator(
          onRefresh: () => provider.initialize(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date Display
                DateDisplay(
                  date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  isCompleted: prayerDay?.isCompleted ?? false,
                  completedCount: prayerDay?.completedCount ?? 0,
                ),
                const SizedBox(height: 24),

                // Completion Indicator
                if (prayerDay?.isCompleted ?? false)
                  const CompletionIndicator(),

                if (prayerDay?.isCompleted ?? false)
                  const SizedBox(height: 24),

                // Error Message
                if (errorMsg != null)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        errorMsg,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),

                if (errorMsg != null) const SizedBox(height: 16),

                // Loading or Prayer Cards
                if (isLoading && prayerDay == null)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  ...allPrayers.map((prayer) {
                    final isCompleted = provider.isPrayerCompleted(
                      prayer,
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PrayerCard(
                        prayer: prayer,
                        isCompleted: isCompleted,
                        date: DateTime.now(), // Pass the date for Friday detection
                        onTap: () {
                          provider.togglePrayer(prayer);
                        },
                      ),
                    );
                  }),

                const SizedBox(height: 16),

                // Progress Text
                if (prayerDay != null)
                  Center(
                    child: Text(
                      '${prayerDay.completedCount} of 5 prayers completed',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
