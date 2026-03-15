import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));
  for (var file in files) {
    var content = file.readAsStringSync();
    if (content.contains(
      'package:flutter_gen/gen_l10n/app_localizations.dart',
    )) {
      content = content.replaceAll(
        'package:flutter_gen/gen_l10n/app_localizations.dart',
        'package:darawalkaab/l10n/app_localizations.dart',
      );
      file.writeAsStringSync(content);
      print('Updated ${file.path}');
    }
  }
}
