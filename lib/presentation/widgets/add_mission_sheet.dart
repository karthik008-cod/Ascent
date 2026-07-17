import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/missions_provider.dart';
import '../../data/models/mission.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';

class AddMissionSheet extends ConsumerStatefulWidget {
  final Mission? existingMission;

  const AddMissionSheet({super.key, this.existingMission});

  @override
  ConsumerState<AddMissionSheet> createState() => _AddMissionSheetState();
}

class _AddMissionSheetState extends ConsumerState<AddMissionSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _checklistInputController = TextEditingController();

  bool _titleHasError = false;
  MissionType _selectedType = MissionType.side;
  final List<String> _checklist = [];
  
  // Scheduling
  late DateTime _startDate;
  String _repeatMode = 'Never'; // 'Never', 'Daily', 'Weekly', 'Custom Days'
  final Set<int> _selectedDays = {1, 2, 3, 4, 5}; // 1 = Mon, 7 = Sun
  
  // Reminders & Tags
  TimeOfDay? _reminderTime;
  bool _syncReminderWithMissionRepeat = true;
  String _reminderRepeatMode = 'Once';
  final Set<String> _selectedTags = {};
  final List<String> _availableTags = ['#Career', '#Fitness', '#Mindset', '#Project', '#Personal'];

  @override
  void initState() {
    super.initState();
    _startDate = widget.existingMission?.date ?? DateTime.now();

    if (widget.existingMission != null) {
      final mission = widget.existingMission!;
      _titleController.text = mission.title;
      _selectedType = mission.type;

      // Parse existing description to extract notes, checklist, tags, reminder
      if (mission.description != null) {
        final lines = mission.description!.split('\n');
        final notesLines = <String>[];
        for (final line in lines) {
          if (line.startsWith('• ')) {
            _checklist.add(line.substring(2));
          } else if (line.startsWith('Tags: ')) {
            final tags = line.substring(6).split(' ');
            for (final t in tags) {
              if (t.isNotEmpty) {
                _selectedTags.add(t);
                if (!_availableTags.contains(t)) _availableTags.add(t);
              }
            }
          } else if (line.startsWith('Repeats: ')) {
            _repeatMode = line.substring(9);
          } else if (line.startsWith('Reminder: ')) {
            // keep noted
          } else if (line.startsWith('Reminder Repeat: ')) {
            final mode = line.substring(17).trim();
            if (mode == 'Synced') {
              _syncReminderWithMissionRepeat = true;
            } else {
              _syncReminderWithMissionRepeat = false;
              _reminderRepeatMode = mode;
            }
          } else if (line != 'Subtasks:') {
            notesLines.add(line);
          }
        }
        _descController.text = notesLines.join('\n').trim();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _checklistInputController.dispose();
    super.dispose();
  }

  void _addSubtask() {
    final text = _checklistInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _checklist.add(text);
        _checklistInputController.clear();
      });
    }
  }

  void _addCustomHashtag() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('New Hashtag'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g. AI, Flutter, Workout'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                var text = controller.text.trim();
                if (text.isNotEmpty) {
                  if (!text.startsWith('#')) text = '#$text';
                  setState(() {
                    if (!_availableTags.contains(text)) _availableTags.add(text);
                    _selectedTags.add(text);
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add Tag'),
            ),
          ],
        );
      },
    );
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _titleHasError = true;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: AppColors.error),
              SizedBox(width: 10),
              Text('Required Fields Missing'),
            ],
          ),
          content: const Text('Please fill in the Mission Title before committing to your mission board.'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
      return;
    }

    // Compile rich description
    final buffer = StringBuffer();
    final descText = _descController.text.trim();
    if (descText.isNotEmpty) {
      buffer.writeln(descText);
    }
    if (_checklist.isNotEmpty) {
      buffer.writeln('\nSubtasks:');
      for (final item in _checklist) {
        buffer.writeln('• $item');
      }
    }
    if (_repeatMode != 'Never') {
      buffer.writeln('\nRepeats: $_repeatMode');
    }
    if (_reminderTime != null) {
      buffer.writeln('\nReminder: ${_reminderTime!.format(context)}');
      final repeatStr = _syncReminderWithMissionRepeat && _repeatMode != 'Never'
          ? 'Synced'
          : (_syncReminderWithMissionRepeat ? 'Once' : _reminderRepeatMode);
      buffer.writeln('Reminder Repeat: $repeatStr');
    }
    if (_selectedTags.isNotEmpty) {
      buffer.writeln('\nTags: ${_selectedTags.join(' ')}');
    }

    final actualRepeatMode = _syncReminderWithMissionRepeat
        ? (_repeatMode == 'Daily' || _repeatMode == 'Custom Days'
            ? 'Daily'
            : (_repeatMode == 'Weekly' ? 'Weekly' : 'Once'))
        : _reminderRepeatMode;

    if (widget.existingMission != null) {
      final mission = widget.existingMission!
        ..title = title
        ..description = buffer.isEmpty ? null : buffer.toString().trim()
        ..type = _selectedType
        ..xpReward = _selectedType == MissionType.main ? 100 : (_selectedType == MissionType.side ? 50 : 20)
        ..date = _startDate;

      ref.read(missionNotifierProvider.notifier).updateMission(mission);
      if (_reminderTime != null) {
        NotificationService.scheduleMissionNotification(
          id: mission.id,
          title: 'Ascent Reminder: ${mission.title}',
          body: 'It is time to focus on your mission!',
          scheduledTime: _reminderTime!,
          repeatMode: actualRepeatMode,
        );
      } else {
        NotificationService.cancelNotification(mission.id);
      }
    } else {
      final mission = Mission()
        ..title = title
        ..description = buffer.isEmpty ? null : buffer.toString().trim()
        ..type = _selectedType
        ..xpReward = _selectedType == MissionType.main ? 100 : (_selectedType == MissionType.side ? 50 : 20)
        ..date = _startDate
        ..isCompleted = false;

      ref.read(missionNotifierProvider.notifier).addMission(mission);
      if (_reminderTime != null) {
        NotificationService.scheduleMissionNotification(
          id: mission.id,
          title: 'Ascent Reminder: ${mission.title}',
          body: 'It is time to focus on your mission!',
          scheduledTime: _reminderTime!,
          repeatMode: actualRepeatMode,
        );
      }
    }
    Navigator.of(context).pop();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.existingMission != null ? 'Edit Mission' : 'New Mission',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 24),
              ),
              Row(
                children: [
                  if (widget.existingMission != null) ...[
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                      tooltip: 'Delete Mission',
                      onPressed: () {
                        ref.read(missionNotifierProvider.notifier).deleteMission(widget.existingMission!.id);
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 4),
                  ],
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Scrollable form contents
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Input
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                    onChanged: (_) {
                      if (_titleHasError) setState(() => _titleHasError = false);
                    },
                    decoration: InputDecoration(
                      labelText: 'Mission Title *',
                      hintText: 'e.g., Complete System Design Chapter',
                      errorText: _titleHasError ? 'Mission Title cannot be empty' : null,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Description Input
                  TextField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes & Description (Optional)',
                      hintText: 'Add details, context, or key objectives...',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mission Type / XP
                  Text('MISSION WEIGHT & XP', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildTypeChip('Main', MissionType.main, 100, AppColors.accent)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTypeChip('Side', MissionType.side, 50, AppColors.primary)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildTypeChip('Routine', MissionType.routine, 20, AppColors.success)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Checklist / Subtasks
                  Text('CHECKLIST / SUBTASKS', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  for (int i = 0; i < _checklist.length; i++)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceHighlight.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_box_outline_blank_rounded, size: 20, color: AppColors.textSecondary),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_checklist[i], style: const TextStyle(fontSize: 14))),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              setState(() {
                                _checklist.removeAt(i);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _checklistInputController,
                          onSubmitted: (_) => _addSubtask(),
                          decoration: const InputDecoration(
                            hintText: 'New checklist entry...',
                            prefixIcon: Icon(Icons.add_rounded, color: AppColors.primary),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addSubtask,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Scheduling & Repetition
                  Text('SCHEDULING & REPETITION', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Start Date Pill
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickStartDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.surfaceHighlight.withOpacity(0.6)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Start Date', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    Text(DateFormat('MMM dd, yyyy').format(_startDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Repeat Mode Selector
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.surfaceHighlight.withOpacity(0.6)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _repeatMode,
                              isExpanded: true,
                              dropdownColor: AppColors.surface,
                              icon: const Icon(Icons.repeat_rounded, color: AppColors.primary, size: 20),
                              items: ['Never', 'Daily', 'Weekly', 'Custom Days'].map((mode) {
                                return DropdownMenuItem(
                                  value: mode,
                                  child: Text(mode, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _repeatMode = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_repeatMode == 'Custom Days' || _repeatMode == 'Weekly') ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (index) {
                        final dayNum = index + 1;
                        final isSelected = _selectedDays.contains(dayNum);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                if (_selectedDays.length > 1) _selectedDays.remove(dayNum);
                              } else {
                                _selectedDays.add(dayNum);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.background,
                              shape: BoxShape.circle,
                              border: Border.all(color: isSelected ? AppColors.primary : AppColors.surfaceHighlight),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              dayNames[index],
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Reminders & Tags
                  Text('REMINDERS & TAGS', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _pickReminderTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: _reminderTime != null ? AppColors.primary.withOpacity(0.15) : AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _reminderTime != null ? AppColors.primary : AppColors.surfaceHighlight.withOpacity(0.6)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.alarm_rounded, size: 18, color: _reminderTime != null ? AppColors.primary : AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                _reminderTime != null ? _reminderTime!.format(context) : '+ Add Reminder',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _reminderTime != null ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                              if (_reminderTime != null) ...[
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _reminderTime = null;
                                    });
                                  },
                                  child: const Icon(Icons.close_rounded, size: 16, color: AppColors.primary),
                                )
                              ]
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _addCustomHashtag,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.surfaceHighlight.withOpacity(0.6)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tag_rounded, size: 18, color: AppColors.secondary),
                              SizedBox(width: 6),
                              Text('+ Add Hashtag', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_reminderTime != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Sync with Mission Repeat', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                    SizedBox(height: 2),
                                    Text('Repeat reminder along with mission schedule', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _syncReminderWithMissionRepeat,
                                activeThumbColor: AppColors.primary,
                                onChanged: (val) {
                                  setState(() {
                                    _syncReminderWithMissionRepeat = val;
                                  });
                                },
                              ),
                            ],
                          ),
                          if (!_syncReminderWithMissionRepeat) ...[
                            const Divider(height: 18, color: AppColors.surfaceHighlight),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Reminder Repetition:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.surfaceHighlight),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _reminderRepeatMode,
                                      isDense: true,
                                      dropdownColor: AppColors.surface,
                                      icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
                                      items: ['Once', 'Daily', 'Weekly', 'Hourly (Nag)'].map((mode) {
                                        return DropdownMenuItem(
                                          value: mode,
                                          child: Text(mode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _reminderRepeatMode = val;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else if (_repeatMode != 'Never') ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.sync_rounded, size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text('Repeats: $_repeatMode at ${_reminderTime!.format(context)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 4),
                            const Row(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textSecondary),
                                SizedBox(width: 6),
                                Text('Mission does not repeat (Reminder fires once)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedTags.remove(tag);
                            } else {
                              _selectedTags.add(tag);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.secondary.withOpacity(0.2) : AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? AppColors.secondary : AppColors.surfaceHighlight.withOpacity(0.5)),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.secondary : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action Button
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              widget.existingMission != null ? 'Save Changes' : 'Commit to Mission Board',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, MissionType type, int xp, Color color) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : AppColors.surfaceHighlight.withOpacity(0.5), width: isSelected ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: isSelected ? color : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 2),
            Text('+$xp XP', style: TextStyle(color: isSelected ? color : AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
