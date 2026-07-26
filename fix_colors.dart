import 'dart:io';

void main() {
  final files = [
    'lib/features/tasks/presentation/screens/add_mission_screen.dart',
    'lib/features/tasks/presentation/widgets/filter_sort_bar.dart'
  ];

  for (var path in files) {
    var file = File(path);
    if (!file.existsSync()) continue;
    var content = file.readAsStringSync();
    
    // Replace AppColors.background with Theme.of(context).scaffoldBackgroundColor
    content = content.replaceAll('AppColors.background', 'Theme.of(context).scaffoldBackgroundColor');
    
    // Replace AppColors.surfaceHighlight with Theme.of(context).colorScheme.surfaceContainerHighest
    content = content.replaceAll('AppColors.surfaceHighlight', 'Theme.of(context).colorScheme.surfaceContainerHighest');

    // Replace AppColors.surface with Theme.of(context).colorScheme.surface
    content = content.replaceAll('AppColors.surface', 'Theme.of(context).colorScheme.surface');
    
    // Replace AppColors.textPrimary with Theme.of(context).colorScheme.onSurface
    content = content.replaceAll('AppColors.textPrimary', 'Theme.of(context).colorScheme.onSurface');
    
    // Replace AppColors.textSecondary with Theme.of(context).textTheme.bodyMedium!.color!
    content = content.replaceAll('AppColors.textSecondary', '(Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)');

    file.writeAsStringSync(content);
    print('Updated \$path');
  }
}
