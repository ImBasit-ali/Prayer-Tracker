import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/constants/prayer_names.dart';
import '../../core/database/isar_service.dart';
import '../../data/repositories/prayer_repository_impl.dart';
import '../providers/prayer_provider.dart';
import '../widgets/prayer_card.dart';
import '../widgets/date_display.dart';
import '../widgets/completion_indicator.dart';

/// Screen for tracking/marking prayers on a specific historical date
class PrayerDateScreen extends HookWidget {
  final DateTime date;

  const PrayerDateScreen({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    // Create provider instance
    final provider = useMemoized(
      () => PrayerProvider(PrayerRepositoryImpl(IsarService.instance)),
    );

    // Load date data on first build and when date changes
    useEffect(() {
      provider.loadDateData(date);
      return null;
    }, [date]);

    // Watch prayer day signal
    final prayerDay = provider.currentPrayerDay.watch(context);
    final isLoading = provider.isLoading.watch(context);
    final errorMsg = provider.errorMessage.watch(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('MMMM d, yyyy').format(date), style: const TextStyle(fontSize: 18)),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadDateData(date),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date Display
              DateDisplay(
                date: DateFormat('yyyy-MM-dd').format(date),
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
                      date: date,
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
    );
  }
}
