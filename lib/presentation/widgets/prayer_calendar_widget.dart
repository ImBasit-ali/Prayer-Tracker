import 'package:flutter/material.dart';
import '../../domain/models/prayer_day.dart';

/// Calendar widget showing prayer completion for a month
class PrayerCalendarWidget extends StatelessWidget {
  final int year;
  final int month;
  final List<PrayerDay> prayerDays;
  final Function(DateTime)? onDateTap;

  const PrayerCalendarWidget({
    super.key,
    required this.year,
    required this.month,
    required this.prayerDays,
    this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday;

    // Create a map for quick lookup
    final prayerMap = <String, PrayerDay>{};
    for (final day in prayerDays) {
      prayerMap[day.date] = day;
    }

    return Column(
      children: [
        // Weekday headers
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),

        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: 42, // 6 weeks
          itemBuilder: (context, index) {
            final dayNumber = index - (startWeekday - 1) + 1;

            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox(); // Empty cell
            }

            final date = DateTime(year, month, dayNumber);
            final dateStr =
                '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            final prayerDay = prayerMap[dateStr];
            final today = DateTime.now();
            final isToday =
                date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
            final isFuture = date.isAfter(today);

            Color? cellColor;
            Color? textColor;

            if (isFuture) {
              cellColor = Colors.grey.shade200;
              textColor = Colors.grey.shade400;
            } else if (prayerDay != null) {
              if (prayerDay.isCompleted) {
                cellColor = Colors.green.shade100;
                textColor = Colors.green.shade800;
              } else {
                final completedCount = prayerDay.completedCount;
                if (completedCount > 0) {
                  cellColor = Colors.orange.shade100;
                  textColor = Colors.orange.shade800;
                } else {
                  cellColor = Colors.red.shade100;
                  textColor = Colors.red.shade800;
                }
              }
            }

            return GestureDetector(
              onTap: isFuture ? null : () => onDateTap?.call(date),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: cellColor,
                  border: isToday
                      ? Border.all(color: theme.colorScheme.primary, width: 2)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayNumber.toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: textColor,
                        ),
                      ),
                      if (prayerDay != null && !prayerDay.isCompleted) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${prayerDay.completedCount}/5',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            color: textColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Legend
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildLegendItem(
              context,
              Colors.green.shade100,
              'All prayers completed',
            ),
            _buildLegendItem(
              context,
              Colors.orange.shade100,
              'Partial completion',
            ),
            _buildLegendItem(context, Colors.red.shade100, 'No prayers'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
