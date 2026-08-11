import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/missions_provider.dart';
import '../../data/models/mission.dart';
import '../../data/models/subtask.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/shake_widget.dart';

class AddMissionScreen extends ConsumerStatefulWidget {
  final Mission? existingMission;

  const AddMissionScreen({super.key, this.existingMission});

  @override
  ConsumerState<AddMissionScreen> createState() => _AddMissionScreenState();
}

class _AddMissionScreenState extends ConsumerState<AddMissionScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _checklistInputController = TextEditingController();

  bool _titleHasError = false;
  int _titleErrorShakeCount = 0;
  
  MissionType _selectedType = MissionType.side;
  final List<Subtask> _checklist = [];
  
  // Scheduling
  late DateTime _startDate;
  String _repeatMode = 'Once'; // 'Once', 'Daily', 'Weekly'
  final Set<int> _selectedDays = {}; // 1 = Mon, 7 = Sun
  
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
    _selectedDays.add(_startDate.weekday);

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
            String subtaskText = line.substring(2);
            bool isCompleted = false;
            if (subtaskText.startsWith('[ ] ')) {
               subtaskText = subtaskText.substring(4);
            } else if (subtaskText.startsWith('[x] ')) {
               subtaskText = subtaskText.substring(4);
               isCompleted = true;
            }
            _checklist.add(Subtask(subtaskText, isCompleted));
          } else if (line.startsWith('Tags: ')) {
            final tags = line.substring(6).split(' ');
            for (final t in tags) {
              if (t.isNotEmpty) {
                _selectedTags.add(t);
                if (!_availableTags.contains(t)) _availableTags.add(t);
              }
            }
          } else if (line.startsWith('Repeats: ')) {
            final repeatStr = line.substring(9).trim();
            if (repeatStr.startsWith('Daily')) {
              _repeatMode = 'Daily';
            } else if (repeatStr.startsWith('Weekly')) {
              _repeatMode = 'Weekly';
              final match = RegExp(r'Days:\s*([0-9a-zA-Z,\s]+)').firstMatch(repeatStr);
              if (match != null && match.group(1) != null) {
                _selectedDays.clear();
                final reverseMap = {'Mon': 1, 'Tue': 2, 'Wed': 3, 'Thu': 4, 'Fri': 5, 'Sat': 6, 'Sun': 7};
                for (final s in match.group(1)!.split(',')) {
                  final val = s.trim();
                  if (reverseMap.containsKey(val)) {
                    _selectedDays.add(reverseMap[val]!);
                  } else {
                    final d = int.tryParse(val);
                    if (d != null) _selectedDays.add(d);
                  }
                }
              } else {
                _selectedDays.clear();
                _selectedDays.add(_startDate.weekday);
              }
            } else {
              _repeatMode = 'Once';
            }
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
        _checklist.add(Subtask(text, false));
        _checklistInputController.clear();
      });
    }
  }

  void _addCustomHashtag() {
    FocusScope.of(context).unfocus();
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('New Hashtag'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g. AI, Flutter, Workout'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
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
              child: Text('Add Tag'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _titleHasError = true;
        _titleErrorShakeCount++;
      });
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
        buffer.writeln('• [${item.isCompleted ? 'x' : ' '}] ${item.text}');
      }
    }
    if (_repeatMode == 'Weekly') {
      final sortedDays = _selectedDays.toList()..sort();
      if (sortedDays.isNotEmpty) {
        final dayNamesMap = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
        final sortedDaysStr = sortedDays.map((d) => dayNamesMap[d]!).join(', ');
        buffer.writeln('\nRepeats: $_repeatMode (Days: $sortedDaysStr)');
      } else {
        buffer.writeln('\nRepeats: $_repeatMode');
      }
    } else {
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
        ? (_repeatMode == 'Once' ? 'Once' : (_repeatMode == 'Daily' ? 'Daily' : 'Weekly'))
        : _reminderRepeatMode;

    if (widget.existingMission != null) {
      final mission = widget.existingMission!
        ..title = title
        ..description = buffer.isEmpty ? null : buffer.toString().trim()
        ..type = _selectedType
        ..xpReward = _selectedType == MissionType.main ? 100 : (_selectedType == MissionType.side ? 50 : 20)
        ..date = _startDate
        ..reminderTime = _reminderTime != null ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}' : null
        ..reminderRepeatMode = _reminderTime != null ? actualRepeatMode : null
        ..reminderWeeklyDays = _reminderTime != null && actualRepeatMode == 'Weekly' ? _selectedDays.toList() : null;

      // updateMission -> _loadMissions -> syncMissionsToNotifications handles scheduling
      await ref.read(missionNotifierProvider.notifier).updateMission(mission);
    } else {
      final mission = Mission()
        ..title = title
        ..description = buffer.isEmpty ? null : buffer.toString().trim()
        ..type = _selectedType
        ..xpReward = _selectedType == MissionType.main ? 100 : (_selectedType == MissionType.side ? 50 : 20)
        ..date = _startDate
        ..reminderTime = _reminderTime != null ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}' : null
        ..reminderRepeatMode = _reminderTime != null ? actualRepeatMode : null
        ..reminderWeeklyDays = _reminderTime != null && actualRepeatMode == 'Weekly' ? _selectedDays.toList() : null
        ..isCompleted = false;

      // addMission -> _loadMissions -> syncMissionsToNotifications handles scheduling
      await ref.read(missionNotifierProvider.notifier).addMission(mission);
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
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
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.existingMission != null ? 'Edit Mission' : 'New Mission',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 24),
        ),
        actions: [
          if (widget.existingMission != null)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: AppColors.error),
              tooltip: 'Delete Mission',
              onPressed: () {
                ref.read(missionNotifierProvider.notifier).deleteMission(widget.existingMission!.id);
                context.pop();
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sticky Title Input
              ShakeWidget(
                key: ValueKey(_titleErrorShakeCount),
                shouldShake: _titleHasError,
                child: TextField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  onChanged: (val) {
                    if (_titleHasError && val.trim().isNotEmpty) setState(() => _titleHasError = false);
                  },
                  decoration: InputDecoration(
                    labelText: 'Mission Title *',
                    hintText: 'e.g., Complete System Design Chapter',
                    errorText: _titleHasError ? 'Mission Title cannot be empty' : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: _titleHasError ? AppColors.error : Theme.of(context).colorScheme.surfaceContainerHighest,
                        width: _titleHasError ? 2 : 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: _titleHasError ? AppColors.error : AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Scrollable form contents
              Expanded(
                child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    title: 'NOTES & DESCRIPTION',
                    child: TextField(
                      controller: _descController,
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        hintText: 'Add details, context, or key objectives...',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                      ),
                    ),
                  ),

                  _buildSectionCard(
                    title: 'MISSION WEIGHT & XP',
                    child: Row(
                      children: [
                        Expanded(child: _buildTypeChip('Main', MissionType.main, 100, AppColors.accent)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTypeChip('Side', MissionType.side, 50, AppColors.primary)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTypeChip('Routine', MissionType.routine, 20, AppColors.success)),
                      ],
                    ),
                  ),

                  _buildSectionCard(
                    title: 'CHECKLIST / SUBTASKS',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < _checklist.length; i++)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _checklist[i].isCompleted ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                    size: 20,
                                    color: _checklist[i].isCompleted ? AppColors.success : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                                  ),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    setState(() {
                                      _checklist[i].isCompleted = !_checklist[i].isCompleted;
                                    });
                                  },
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(_checklist[i].text, style: TextStyle(fontSize: 14, decoration: _checklist[i].isCompleted ? TextDecoration.lineThrough : null))),
                                IconButton(
                                  icon: Icon(Icons.close_rounded, size: 18, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
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
                              child: Text('Add'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  _buildSectionCard(
                    title: 'SCHEDULING & REPETITION',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Start Date Pill
                            Expanded(
                              child: GestureDetector(
                                onTap: _pickStartDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.6)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Start Date', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
                                          Text(DateFormat('MMM dd, yyyy').format(_startDate), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.6)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _repeatMode,
                                    isExpanded: true,
                                    dropdownColor: Theme.of(context).colorScheme.surface,
                                    icon: Icon(Icons.repeat_rounded, color: AppColors.primary, size: 20),
                                    items: ['Once', 'Daily', 'Weekly'].map((mode) {
                                      return DropdownMenuItem(
                                        value: mode,
                                        child: Text(mode, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _repeatMode = val;
                                          if (_repeatMode == 'Weekly' && _selectedDays.isEmpty) {
                                            _selectedDays.add(_startDate.weekday);
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_repeatMode == 'Weekly') ...[
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
                                    color: isSelected ? AppColors.primary : Theme.of(context).scaffoldBackgroundColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.surfaceContainerHighest),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    dayNames[index],
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ],
                    ),
                  ),

                  _buildSectionCard(
                    title: 'REMINDERS & TAGS',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            GestureDetector(
                              onTap: _pickReminderTime,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _reminderTime != null ? AppColors.primary.withOpacity(0.15) : Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _reminderTime != null ? AppColors.primary : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.6)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.alarm_rounded, size: 18, color: _reminderTime != null ? AppColors.primary : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
                                    const SizedBox(width: 8),
                                    Text(
                                      _reminderTime != null ? _reminderTime!.format(context) : '+ Add Reminder',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _reminderTime != null ? AppColors.primary : Theme.of(context).colorScheme.onSurface,
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
                                        child: Icon(Icons.close_rounded, size: 16, color: AppColors.primary),
                                      )
                                    ]
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
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Sync with Mission Repeat', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                                          SizedBox(height: 2),
                                          Text('Repeat reminder along with mission schedule', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
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
                                  Divider(height: 18, color: Theme.of(context).colorScheme.surfaceContainerHighest),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Reminder Repetition:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surface,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _reminderRepeatMode,
                                            isDense: true,
                                            dropdownColor: Theme.of(context).colorScheme.surface,
                                            icon: Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary),
                                            items: ['Once', 'Daily', 'Weekly', 'Hourly (Nag)'].map((mode) {
                                              return DropdownMenuItem(
                                                value: mode,
                                                child: Text(mode, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                                      Icon(Icons.sync_rounded, size: 14, color: AppColors.primary),
                                      const SizedBox(width: 6),
                                      Text('Repeats: $_repeatMode at ${_reminderTime!.format(context)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                    ],
                                  ),
                                ] else ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline_rounded, size: 14, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                                      SizedBox(width: 6),
                                      Text('Mission does not repeat (Reminder fires once)', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
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
                          children: [
                            GestureDetector(
                              onTap: _addCustomHashtag,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(20), // Matched to tags
                                  border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.6)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.tag_rounded, size: 16, color: AppColors.secondary),
                                    const SizedBox(width: 4),
                                    Text('Add Tag', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                            ..._availableTags.map((tag) {
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
                                  color: isSelected ? AppColors.secondary.withOpacity(0.2) : Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isSelected ? AppColors.secondary : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5)),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppColors.secondary : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey),
                                  ),
                                ),
                              ),
                            );
                          }),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                      backgroundColor: _titleHasError ? AppColors.error.withOpacity(0.1) : AppColors.primary,
                      side: _titleHasError ? const BorderSide(color: AppColors.error, width: 2) : BorderSide.none,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _titleHasError 
                            ? 'Fill missing fields' 
                            : (widget.existingMission != null ? 'Save Changes' : 'Commit to Mission Board'),
                        key: ValueKey(_titleHasError),
                        style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold, 
                            color: _titleHasError ? AppColors.error : Colors.white
                        ),
                    ),
                  ),
          ),
        ],
      ),
      ),
      ),
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
          color: isSelected ? color.withOpacity(0.2) : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5), width: isSelected ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: isSelected ? color : Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 2),
            Text('+$xp XP', style: TextStyle(color: isSelected ? color : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}