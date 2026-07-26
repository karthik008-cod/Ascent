import 'dart:io';

void fixFile(String path, List<int> linesToRemoveConst) {
  var file = File(path);
  if (!file.existsSync()) return;
  
  var lines = file.readAsLinesSync();
  for (var i in linesToRemoveConst) {
    if (i - 1 >= 0 && i - 1 < lines.length) {
      lines[i - 1] = lines[i - 1].replaceAll('const ', '');
    }
  }
  
  file.writeAsStringSync(lines.join('\n'));
  print('Fixed constants in \$path');
}

void main() {
  fixFile('lib/features/tasks/presentation/screens/add_mission_screen.dart', [
    302, 327, 432, 436, 496, 670, 688, 692, 737
  ]);
  
  fixFile('lib/features/tasks/presentation/widgets/filter_sort_bar.dart', [
    162, 230, 328, 378
  ]);
}
