import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every 'assets/...' path written in lib/ must exist with exactly that
/// case, or the app shows an error box (or a video won't play) on Android,
/// whose file system is case-sensitive. Windows is not, so a plain
/// File.existsSync() passes there for "Squat.jpg" vs "squat.jpg"; this test
/// compares names exactly so it fails on every OS.
void main() {
  final pattern =
      RegExp(r'''['"]((?:assets|assest)/[^'"$]+\.[a-zA-Z0-9]+)['"]''');

  /// path -> where it is referenced.
  Map<String, List<String>> referencedAssets() {
    final refs = <String, List<String>>{};
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final m in pattern.allMatches(lines[i])) {
          refs
              .putIfAbsent(m.group(1)!, () => [])
              .add('${file.path.replaceAll(r'\', '/')}:${i + 1}');
        }
      }
    }
    return refs;
  }

  /// Whether [path] exists with exactly this case in every segment.
  bool existsWithExactCase(String path) {
    var dir = Directory('.');
    final parts = path.split('/');
    for (var i = 0; i < parts.length; i++) {
      final names = dir.existsSync()
          ? dir
              .listSync()
              .map((e) => e.uri.pathSegments.lastWhere((s) => s.isNotEmpty))
              .toSet()
          : const <String>{};
      if (!names.contains(parts[i])) return false;
      dir = Directory('${dir.path}/${parts[i]}');
    }
    return true;
  }

  test('all asset paths referenced in lib/ exist with exact case', () {
    final problems = [
      for (final MapEntry(key: path, value: where)
          in referencedAssets().entries)
        if (!existsWithExactCase(path)) '$path (in ${where.join(', ')})',
    ];
    expect(problems, isEmpty);
  });

  test('all referenced assets are tracked by git (exact case)', () {
    final ProcessResult result;
    try {
      result = Process.runSync('git', ['ls-files', 'assets']);
    } on ProcessException {
      markTestSkipped('git is not available');
      return;
    }
    if (result.exitCode != 0) {
      markTestSkipped('not a git checkout');
      return;
    }
    final tracked = (result.stdout as String)
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toSet();
    final untracked = [
      for (final MapEntry(key: path, value: where)
          in referencedAssets().entries)
        if (!tracked.contains(path)) '$path (in ${where.join(', ')})',
    ];
    expect(untracked, isEmpty,
        reason: 'These exist locally (or differ in case) but are not '
            'committed, so CI and other machines will not have them.');
  });
}
