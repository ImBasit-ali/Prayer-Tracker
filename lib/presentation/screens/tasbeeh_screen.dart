import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:intl/intl.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../core/database/isar_service.dart';
import '../../data/repositories/tasbeeh_repository_impl.dart';
import '../providers/tasbeeh_provider.dart';
import '../widgets/tasbeeh_counter_button.dart';

/// Tasbeeh counter screen
class TasbeehScreen extends HookWidget {
  const TasbeehScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Create provider instance
    final provider = useMemoized(
      () => TasbeehProvider(TasbeehRepositoryImpl(IsarService.instance)),
    );

    // Initialize on first build
    useEffect(() {
      provider.initialize();
      return null;
    }, []);

    // Watch signals
    final count = provider.currentCount.watch(context);
    final history = provider.history.watch(context);
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
      key: const Key('tasbeeh-screen'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5) {
          provider.refresh();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tasbeeh Counter'),
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
                // Error Message
                if (errorMsg != null)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        errorMsg,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),

                if (errorMsg != null) const SizedBox(height: 16),

                // Today's Date
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Today',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Counter Display
                TasbeehCounterButton(
                  count: count,
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    await provider.increment();
                  },
                  isLoading: isLoading,
                ),

                const SizedBox(height: 32),

                // History Section
                Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recent History',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // History List
                if (history.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No history yet',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...history.map((item) {
                    final localUpdatedAt = item.updatedAt.toLocal();
                    final dayStr = DateFormat('EEEE').format(localUpdatedAt);
                    final timeStr = DateFormat('h:mm a').format(localUpdatedAt);
                    final isToday =
                        DateFormat('yyyy-MM-dd').format(DateTime.now()) ==
                        item.date;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isToday
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.access_time,
                            size: 20,
                            color: isToday
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          isToday ? 'Today ($dayStr)' : dayStr,
                          style: TextStyle(
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(timeStr),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${item.count}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Text(
                              'times',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
