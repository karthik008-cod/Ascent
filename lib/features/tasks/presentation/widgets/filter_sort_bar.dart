import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/missions_provider.dart';

class FilterSortBar extends ConsumerWidget {
  const FilterSortBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(missionFilterProvider);
    final currentSort = ref.watch(missionSortProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Filter Button
          Expanded(
            child: GestureDetector(
              onTap: () => _showFilterPopup(context, ref, currentFilter),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: currentFilter != 'All'
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: currentFilter != 'All'
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      size: 18,
                      color: currentFilter != 'All'
                          ? AppColors.primary
                          : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Filter: $currentFilter',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: currentFilter != 'All'
                              ? AppColors.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Sort Button
          Expanded(
            child: GestureDetector(
              onTap: () => _showSortPopup(context, ref, currentSort),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: currentSort != 'Default'
                      ? AppColors.secondary.withValues(alpha: 0.15)
                      : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: currentSort != 'Default'
                        ? AppColors.secondary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sort_rounded,
                      size: 18,
                      color: currentSort != 'Default'
                          ? AppColors.secondary
                          : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Sort: $currentSort',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: currentSort != 'Default'
                              ? AppColors.secondary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterPopup(BuildContext context, WidgetRef ref, String currentFilter) {
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);

    String? expandedWeeklyDay;
    String baseFilterType = currentFilter;
    if (currentFilter.startsWith('Weekly:')) {
      baseFilterType = 'Weekly';
      expandedWeeklyDay = currentFilter.split(':')[1];
    }
    bool isWeeklyExpanded = baseFilterType == 'Weekly';

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Consumer(
              builder: (context, ref, child) {
                final availableHashtags = ref.watch(availableHashtagsProvider);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle Bar & Title
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filter Missions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (currentFilter != 'All')
                            TextButton(
                              onPressed: () {
                                ref.read(missionFilterProvider.notifier).state = 'All';
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Reset (All)',
                                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'BY MISSION TYPE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.5,
                              color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: ['All', 'Main', 'Side', 'Routine'].map((type) {
                          final isSelected = currentFilter == type;
                          return GestureDetector(
                            onTap: () {
                              ref.read(missionFilterProvider.notifier).state = type;
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                                ),
                              ),
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'BY REPETITION',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.5,
                              color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: ['Daily', 'Weekly', 'Once'].map((type) {
                          final isSelected = baseFilterType == type;
                          return GestureDetector(
                            onTap: () {
                              if (type == 'Weekly') {
                                setState(() {
                                  isWeeklyExpanded = true;
                                  baseFilterType = 'Weekly';
                                });
                              } else {
                                ref.read(missionFilterProvider.notifier).state = type;
                                Navigator.pop(context);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                                ),
                              ),
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: !isWeeklyExpanded ? const SizedBox(width: double.infinity) : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              'SELECT DAY OF THE WEEK',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    letterSpacing: 1.5,
                                    color: AppColors.primary,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                {'label': 'Mon', 'val': '1'},
                                {'label': 'Tue', 'val': '2'},
                                {'label': 'Wed', 'val': '3'},
                                {'label': 'Thu', 'val': '4'},
                                {'label': 'Fri', 'val': '5'},
                                {'label': 'Sat', 'val': '6'},
                                {'label': 'Sun', 'val': '7'},
                              ].map((dayObj) {
                                final isSelectedDay = expandedWeeklyDay == dayObj['val'];
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      expandedWeeklyDay = dayObj['val'];
                                    });
                                    ref.read(missionFilterProvider.notifier).state = 'Weekly:${dayObj['val']}';
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelectedDay ? AppColors.primary : Theme.of(context).scaffoldBackgroundColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelectedDay ? AppColors.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                                      ),
                                    ),
                                    child: Text(
                                      dayObj['label']!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelectedDay ? FontWeight.bold : FontWeight.w500,
                                        color: isSelectedDay ? Colors.white : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'BY HASHTAG',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.5,
                              color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 10),
                      if (availableHashtags.isEmpty)
                        Text(
                          'No hashtags found in your missions yet.',
                          style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                        )
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: availableHashtags.map((tag) {
                            final isSelected = currentFilter == tag;
                            return GestureDetector(
                              onTap: () {
                                ref.read(missionFilterProvider.notifier).state = tag;
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '#$tag',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 6),
                                      Icon(Icons.check_rounded, size: 14, color: AppColors.primary),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  },
);
}

  void _showSortPopup(BuildContext context, WidgetRef ref, String currentSort) {
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);

    final sortOptions = [
      {'label': 'Default', 'desc': 'Sort by custom order or category priority', 'icon': Icons.sort_rounded},
      {'label': 'By Hashtag', 'desc': 'Group and sort alphabetically by #Hashtag', 'icon': Icons.tag_rounded},
      {'label': 'Incomplete First', 'desc': 'Show active missions before completed ones', 'icon': Icons.check_circle_outline_rounded},
      {'label': 'XP High to Low', 'desc': 'Highest XP reward missions at the top', 'icon': Icons.bolt_rounded},
      {'label': 'Title A-Z', 'desc': 'Alphabetical order by mission title', 'icon': Icons.sort_by_alpha_rounded},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sort Missions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...sortOptions.map((opt) {
                    final label = opt['label'] as String;
                    final desc = opt['desc'] as String;
                    final icon = opt['icon'] as IconData;
                    final isSelected = currentSort == label;

                    return GestureDetector(
                      onTap: () {
                        ref.read(missionSortProvider.notifier).state = label;
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.secondary.withValues(alpha: 0.15) : Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.secondary : Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              color: isSelected ? AppColors.secondary : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                              size: 22,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: isSelected ? AppColors.secondary : Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    desc,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 20),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}