import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/prayer_repository_impl.dart';
import '../../core/database/isar_service.dart';
import '../providers/prayer_history_provider.dart';
import '../../domain/models/prayer_day.dart';
import '../widgets/statistics_card.dart';
import '../widgets/prayer_calendar_widget.dart';
import 'prayer_date_screen.dart';

/// Prayer history screen with year/month/day views
class PrayerHistoryScreen extends HookWidget {
  const PrayerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tabController = useTabController(initialLength: 3);

    // Initialize provider
    final provider = useMemoized(
      () => PrayerHistoryProvider(PrayerRepositoryImpl(IsarService.instance)),
    );

    final isInitialized = useState(false);

    // Initialize on mount
    useEffect(() {
      if (!isInitialized.value) {
        provider.initialize().then((_) {
          isInitialized.value = true;
        });
      }
      return null;
    }, []);

    // Watch signals
    final overallStats = provider.overallStatistics.value;
    final yearStats = provider.yearStatistics.value;
    final monthStats = provider.monthStatistics.value;
    final monthHistory = provider.monthHistory.value;
    final yearHistory = provider.yearHistory.value;
    final isLoading = provider.isLoading.value;
    final selectedYear = provider.selectedYear.value;
    final selectedMonth = provider.selectedMonth.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer History'),
        centerTitle: true,
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.analytics)),
            Tab(text: 'Monthly', icon: Icon(Icons.calendar_month)),
            Tab(text: 'Yearly', icon: Icon(Icons.calendar_today)),
          ],
        ),
      ),
      body: isLoading && !isInitialized.value
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: tabController,
              children: [
                // Overview Tab
                _buildOverviewTab(context, overallStats),

                // Monthly Tab
                _buildMonthlyTab(
                  context,
                  provider,
                  monthStats,
                  monthHistory,
                  selectedYear,
                  selectedMonth,
                  isLoading,
                  overallStats,
                ),

                // Yearly Tab
                _buildYearlyTab(
                  context,
                  provider,
                  yearStats,
                  yearHistory,
                  selectedYear,
                  isLoading,
                  tabController,
                  overallStats,
                ),
              ],
            ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, dynamic overallStats) {
    if (overallStats == null) {
      return const Center(child: Text('No prayer data available yet'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh logic can be added here
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Overall Statistics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Total days tracked
          StatisticsCard(
            icon: Icons.calendar_today,
            title: 'Total Days Tracked',
            value: overallStats.totalDaysTracked.toString(),
            subtitle: 'Days with prayer records',
          ),
          const SizedBox(height: 12),

          // Completed days
          StatisticsCard(
            icon: Icons.check_circle,
            title: 'Days All Prayers Completed',
            value: overallStats.completedDays.toString(),
            subtitle:
                '${overallStats.completionPercentage.toStringAsFixed(1)}% completion rate',
            iconColor: Colors.green,
            progressValue: overallStats.completionPercentage / 100,
          ),
          const SizedBox(height: 12),

          // Total prayers
          StatisticsCard(
            icon: Icons.mosque,
            title: 'Total Prayers Completed',
            value:
                '${overallStats.totalPrayersCompleted}/${overallStats.totalPossiblePrayers}',
            subtitle:
                '${(overallStats.totalPrayersCompleted / overallStats.totalPossiblePrayers * 100).toStringAsFixed(1)}% of all prayers',
            iconColor: Colors.blue,
          ),
          const SizedBox(height: 12),

          // Current streak
          StatisticsCard(
            icon: Icons.local_fire_department,
            title: 'Current Streak',
            value: '${overallStats.currentStreak} days',
            subtitle: 'Longest: ${overallStats.longestStreak} days',
            iconColor: Colors.orange,
          ),
          const SizedBox(height: 12),

          // Date range
          if (overallStats.startDate != null && overallStats.endDate != null)
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tracking Period',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${DateFormat('MMM d, yyyy').format(overallStats.startDate!)} - ${DateFormat('MMM d, yyyy').format(overallStats.endDate!)}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTab(
    BuildContext context,
    PrayerHistoryProvider provider,
    dynamic monthStats,
    List<PrayerDay> prayerHistory,
    int selectedYear,
    int selectedMonth,
    bool isLoading,
    dynamic overallStats,
  ) {
    final startYear = overallStats?.startDate?.year ?? DateTime.now().year;
    final startMonth = overallStats?.startDate?.month ?? 1;
    final isAtStartMonth = selectedYear == startYear && selectedMonth == startMonth;

    final now = DateTime.now();
    final isAtCurrentMonth = selectedYear == now.year && selectedMonth == now.month;

    return Column(
      children: [
        // Month selector
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: (isLoading || isAtStartMonth) ? null : provider.previousMonth,
              ),
              Text(
                '${provider.getMonthName(selectedMonth)} $selectedYear',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: (isLoading || isAtCurrentMonth) ? null : provider.nextMonth,
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Month stats
                    if (monthStats != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: StatisticsCard(
                              icon: Icons.check_circle,
                              title: 'Complete Days',
                              value: monthStats.completedDays.toString(),
                              iconColor: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatisticsCard(
                              icon: Icons.mosque,
                              title: 'Total Prayers',
                              value:
                                  '${monthStats.totalPrayersCompleted}/${monthStats.totalPossiblePrayers}',
                              iconColor: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Calendar
                    PrayerCalendarWidget(
                      year: selectedYear,
                      month: selectedMonth,
                      prayerDays: prayerHistory,
                      onDateTap: (date) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PrayerDateScreen(date: date),
                          ),
                        ).then((_) {
                          provider.refreshYearAndMonth(selectedYear, selectedMonth);
                        });
                      },
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildYearlyTab(
    BuildContext context,
    PrayerHistoryProvider provider,
    dynamic yearStats,
    List<PrayerDay> prayerHistory,
    int selectedYear,
    bool isLoading,
    TabController tabController,
    dynamic overallStats,
  ) {
    final startYear = overallStats?.startDate?.year ?? DateTime.now().year;
    final isAtStartYear = selectedYear == startYear;
    final isAtCurrentYear = selectedYear == DateTime.now().year;

    return Column(
      children: [
        // Year selector
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: (isLoading || isAtStartYear) ? null : provider.previousYear,
              ),
              Text(
                selectedYear.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: (isLoading || isAtCurrentYear) ? null : provider.nextYear,
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : yearStats == null
              ? const Center(child: Text('No data for this year'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    StatisticsCard(
                      icon: Icons.calendar_today,
                      title: 'Days Tracked',
                      value: yearStats.totalDaysTracked.toString(),
                    ),
                    const SizedBox(height: 12),
                    StatisticsCard(
                      icon: Icons.check_circle,
                      title: 'Complete Days',
                      value: yearStats.completedDays.toString(),
                      subtitle:
                          '${yearStats.completionPercentage.toStringAsFixed(1)}% completion',
                      iconColor: Colors.green,
                      progressValue: yearStats.completionPercentage / 100,
                    ),
                    const SizedBox(height: 12),
                    StatisticsCard(
                      icon: Icons.mosque,
                      title: 'Total Prayers',
                      value:
                          '${yearStats.totalPrayersCompleted}/${yearStats.totalPossiblePrayers}',
                      iconColor: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    StatisticsCard(
                      icon: Icons.local_fire_department,
                      title: 'Longest Streak',
                      value: '${yearStats.longestStreak} days',
                      iconColor: Colors.orange,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Months in $selectedYear',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final monthIndex = index + 1;
                        final monthName = provider.getMonthName(monthIndex);
                        
                        // Filter history for this month
                        final monthDays = prayerHistory.where((day) {
                          final date = DateTime.parse(day.date);
                          return date.month == monthIndex;
                        }).toList();
                        
                        final daysTracked = monthDays.length;
                        final completedDays = monthDays.where((d) => d.isCompleted).length;
                        
                        String statusText = 'No data';
                        Color cardColor = Theme.of(context).colorScheme.surfaceVariant;
                        Color? textColor;
                        if (daysTracked > 0) {
                          statusText = '$completedDays/$daysTracked comp';
                          if (completedDays == daysTracked) {
                            cardColor = Colors.green.withValues(alpha: 0.15);
                            textColor = Colors.green;
                          } else if (completedDays > 0) {
                            cardColor = Colors.orange.withValues(alpha: 0.15);
                            textColor = Colors.orange;
                          } else {
                            cardColor = Colors.red.withValues(alpha: 0.15);
                            textColor = Colors.red;
                          }
                        }
                        
                        return Card(
                          color: cardColor,
                          elevation: 1,
                          child: InkWell(
                            onTap: () async {
                              if (daysTracked == 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('No prayer data available for $monthName'),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                await provider.loadMonthStatistics(selectedYear, monthIndex);
                                tabController.index = 1; // Switch to Monthly Tab
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    monthName.substring(0, 3), // e.g. "Jan"
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: textColor ?? Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
        ),
      ],
    );
  }

}
