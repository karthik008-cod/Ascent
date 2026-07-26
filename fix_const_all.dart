import 'dart:io';

void fixFile(String path) {
  var file = File(path);
  if (!file.existsSync()) return;
  
  var content = file.readAsStringSync();
  content = content.replaceAll('const Text(', 'Text(');
  content = content.replaceAll('const Icon(', 'Icon(');
  content = content.replaceAll('const Divider(', 'Divider(');
  content = content.replaceAll('const Border(', 'Border(');
  content = content.replaceAll('const BorderSide(', 'BorderSide(');
  
  file.writeAsStringSync(content);
  print('Fixed constants in \$path');
}

void main() {
  fixFile('lib/features/tasks/presentation/screens/add_mission_screen.dart');
  fixFile('lib/features/tasks/presentation/widgets/filter_sort_bar.dart');
}
