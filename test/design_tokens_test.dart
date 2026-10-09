import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// DESIGN.md: "Nothing outside the theme file may hard-code colours, font
/// sizes, radii or shadows." This scans lib/ for the usual ways of doing so.
final _forbidden = <String, RegExp>{
  'Color(0x...) literal': RegExp(r'Color\(0x'),
  'Colors.* constant': RegExp(r'\bColors\.(?!transparent\b)'),
  'fontSize': RegExp(r'\bfontSize\s*:'),
  'BorderRadius.circular()': RegExp(r'BorderRadius\.circular\('),
  'BoxShadow()': RegExp(r'\bBoxShadow\('),
};

/// The design system itself.
const _themeFile = 'lib/config/theme.dart';

/// Screens not yet restyled (Phase 4b). Remove each file as it's converted;
/// the test fails if a listed file is already clean, so the list can only
/// shrink.
const _notYetConverted = {
  'lib/screens/auth/login_page.dart',
  'lib/screens/auth/signup_detail_page.dart',
  'lib/screens/auth/signup_page.dart',
  'lib/screens/home/home_page.dart',
  'lib/screens/live_class/call_page.dart',
  'lib/screens/onboarding/launch_page.dart',
  'lib/screens/onboarding/splash_screen.dart',
  'lib/screens/onboarding/welcome_page.dart',
  'lib/screens/profile/profile_page.dart',
  'lib/screens/trainers/trainer_detail_page.dart',
  'lib/screens/trainers/trainer_list_page.dart',
  'lib/screens/training/training_page.dart',
  'lib/screens/training/video_detail_page.dart',
  'lib/widgets/video_player_widget.dart',
};

/// Violations in [file], ignoring `//` comments.
List<String> _violations(File file) {
  final found = <String>[];
  final lines = file.readAsLinesSync();
  for (var i = 0; i < lines.length; i++) {
    final code = lines[i].split('//').first;
    for (final MapEntry(key: name, value: pattern) in _forbidden.entries) {
      if (pattern.hasMatch(code)) found.add('line ${i + 1}: $name');
    }
  }
  return found;
}

void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => (path: f.path.replaceAll(r'\', '/'), file: f))
      .where((f) => f.path != _themeFile)
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  test('only lib/config/theme.dart defines colours, sizes, radii, shadows', () {
    final offenders = <String>[
      for (final f in files)
        if (!_notYetConverted.contains(f.path))
          for (final v in _violations(f.file)) '${f.path} $v',
    ];
    expect(offenders, isEmpty,
        reason: 'Use Theme.of(context), context.appColors, AppSpacing or '
            'AppRadius from lib/config/theme.dart instead:\n'
            '${offenders.join('\n')}');
  });

  test('the not-yet-converted list only names files that still need work', () {
    final stale = [
      for (final f in files)
        if (_notYetConverted.contains(f.path) && _violations(f.file).isEmpty)
          f.path,
      for (final path in _notYetConverted)
        if (!files.any((f) => f.path == path)) '$path (no longer exists)',
    ];
    expect(stale, isEmpty, reason: 'Remove these from _notYetConverted.');
  });
}
