import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every 'assets/...' path written in lib/ must exist, or the app shows an
/// error box (or a video won't play). Catches typos like "assest/".
void main() {
  test('all asset paths referenced in lib/ exist', () {
    final path =
        RegExp(r'''['"]((?:assets|assest)/[^'"$]+\.[a-zA-Z0-9]+)['"]''');
    final missing = <String>{};
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      for (final m in path.allMatches(file.readAsStringSync())) {
        if (!File(m.group(1)!).existsSync()) {
          missing.add('${m.group(1)} (in ${file.path})');
        }
      }
    }
    expect(missing, isEmpty);
  });
}
