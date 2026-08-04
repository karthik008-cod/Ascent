import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/mission.dart';
import '../../data/models/subtask.dart';
import '../providers/missions_provider.dart';
import '../../../progress/presentation/widgets/level_up_celebration.dart';

class SubtaskList extends ConsumerWidget {
  final Mission mission;
  final bool isWhiteText;

  const SubtaskList({super.key, required this.mission, this.isWhiteText = false});

  List<Subtask> _parseSubtasks(String? description) {
    if (description == null) return [];
    final lines = description.split('\n');
    final subtasks = <Subtask>[];
    for (final line in lines) {
      if (line.startsWith('• ')) {
        String subtaskText = line.substring(2);
        bool isCompleted = false;
        if (subtaskText.startsWith('[ ] ')) {
          subtaskText = subtaskText.substring(4);
        } else if (subtaskText.startsWith('[x] ')) {
          subtaskText = subtaskText.substring(4);
          isCompleted = true;
        }
        subtasks.add(Subtask(subtaskText, isCompleted));
      }
    }
    return subtasks;
  }

  String _toggleSubtaskInDescription(String description, int index) {
    final lines = description.split('\n');
    int subtaskIndex = 0;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('• ')) {
        if (subtaskIndex == index) {
          if (lines[i].contains('• [x] ')) {
            lines[i] = lines[i].replaceFirst('• [x] ', '• [ ] ');
          } else if (lines[i].contains('• [ ] ')) {
            lines[i] = lines[i].replaceFirst('• [ ] ', '• [x] ');
          } else {
            lines[i] = lines[i].replaceFirst('• ', '• [x] ');
          }
          break;
        }
        subtaskIndex++;
      }
    }
    return lines.join('\n');
  }

  Future<void> _handleSubtaskToggle(BuildContext context, WidgetRef ref, int index, List<Subtask> currentSubtasks) async {
    final newDesc = _toggleSubtaskInDescription(mission.description!, index);
    mission.description = newDesc;
    await ref.read(missionNotifierProvider.notifier).updateMission(mission);

    final updatedSubtasks = _parseSubtasks(newDesc);
    final allDone = updatedSubtasks.every((s) => s.isCompleted);
    final currentDayCompleted = isMissionCompletedForDay(mission, DateTime.now().weekday);
    
    if (allDone && !currentDayCompleted) {
      final event = await ref.read(missionNotifierProvider.notifier).toggleMissionStatus(mission);
      if (event != null && context.mounted) {
        showLevelUpCelebration(context, event.oldLevel, event.newLevel);
      }
    } else if (!allDone && currentDayCompleted) {
      await ref.read(missionNotifierProvider.notifier).toggleMissionStatus(mission);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (mission.description == null || mission.description!.isEmpty) return const SizedBox.shrink();

    final subtasks = _parseSubtasks(mission.description);
    if (subtasks.isEmpty) {
      final descFirstLine = mission.description!.split('\n').first;
      if (descFirstLine == 'Subtasks:') return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          descFirstLine,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isWhiteText ? Colors.white.withOpacity(0.85) : AppColors.textSecondary, 
            fontSize: 13
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10.0, left: 6.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isWhiteText ? Colors.white.withOpacity(0.3) : AppColors.primary.withOpacity(0.3),
              width: 2.0,
            ),
          ),
        ),
        padding: const EdgeInsets.only(left: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < subtasks.length; i++)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleSubtaskToggle(context, ref, i, subtasks),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 2.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          subtasks[i].isCompleted ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                          color: isWhiteText ? Colors.white : (subtasks[i].isCompleted ? AppColors.success : AppColors.textSecondary),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            subtasks[i].text,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isWhiteText ? Colors.white.withOpacity(0.9) : AppColors.textSecondary,
                              fontSize: 14,
                              decoration: subtasks[i].isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
