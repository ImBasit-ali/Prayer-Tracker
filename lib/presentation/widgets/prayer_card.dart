import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../core/constants/prayer_names.dart';

/// Reusable prayer card widget with animation
class PrayerCard extends HookWidget {
  final PrayerName prayer;
  final bool isCompleted;
  final VoidCallback onTap;
  final DateTime? date; // Added to support Friday Jumu'ah

  const PrayerCard({
    super.key,
    required this.prayer,
    required this.isCompleted,
    required this.onTap,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    final scaleAnimation = useAnimation(
      Tween<double>(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
      ),
    );

    // Trigger animation when completion status changes
    useEffect(() {
      if (isCompleted) {
        animationController.forward().then(
          (_) => animationController.reverse(),
        );
      }
      return null;
    }, [isCompleted]);

    // Get current date if not provided
    final currentDate = date ?? DateTime.now();

    return Transform.scale(
      scale: scaleAnimation,
      child: Card(
        elevation: isCompleted ? 4 : 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: isCompleted
                  ? LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer,
                        Theme.of(context).colorScheme.secondaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              border: !isCompleted
                  ? Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    )
                  : null,
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Prayer Emoji Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.2)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      prayer.getEmojiForDate(currentDate),
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Prayer Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prayer.getDisplayNameForDate(currentDate),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prayer.getArabicNameForDate(currentDate),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isCompleted
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                                    .withValues(alpha: 0.7)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                // Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: !isCompleted
                        ? Border.all(
                            color: Theme.of(context).colorScheme.outline,
                            width: 2,
                          )
                        : null,
                  ),
                  child: isCompleted
                      ? Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 20,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
