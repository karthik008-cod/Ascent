import 'dart:io';

void main() {
  // Fix add_mission_screen.dart
  var path = 'lib/features/tasks/presentation/screens/add_mission_screen.dart';
  var content = File(path).readAsStringSync();
  content = content.replaceAll('const ColorScheme.dark(', 'ColorScheme.dark(');
  content = content.replaceAll('style: const TextStyle(', 'style: TextStyle(');
  content = content.replaceAll('color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)', 'color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey');
  File(path).writeAsStringSync(content);
  
  // Fix filter_sort_bar.dart
  path = 'lib/features/tasks/presentation/widgets/filter_sort_bar.dart';
  content = File(path).readAsStringSync();
  content = content.replaceAll('style: const TextStyle(', 'style: TextStyle(');
  content = content.replaceAll('color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)', 'color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey');
  File(path).writeAsStringSync(content);
}
