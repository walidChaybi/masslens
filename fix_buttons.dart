import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (final file in files) {
    if (file.path.contains('app_theme.dart')) continue;
    
    var content = file.readAsStringSync();
    if (!content.contains('FilledButton.styleFrom(') || !content.contains('backgroundColor:')) continue;
    
    // We only want to apply the fix to buttons that explicitly set backgroundColor in styleFrom
    // It's safer to just do it manually for the ones that need it.
  }
}
