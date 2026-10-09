import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dab_fitness/config/theme.dart';

/// WCAG 2.x contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final (name, theme) in [
    ('light', AppTheme.light),
    ('dark', AppTheme.dark),
  ]) {
    group('$name theme meets WCAG AA (4.5:1 for text)', () {
      final s = theme.colorScheme;
      final c = theme.extension<AppColors>()!;
      final input = theme.inputDecorationTheme;

      final pairs = <String, (Color, Color)>{
        'primary text on background': (c.textPrimary, c.background),
        'primary text on card': (c.textPrimary, c.card),
        'secondary text on background': (c.textSecondary, c.background),
        'secondary text on card': (c.textSecondary, c.card),
        'input label on input fill': (input.labelStyle!.color!, c.inputFill),
        'input text on input fill': (c.textPrimary, c.inputFill),
        'filled button text': (s.onPrimary, s.primary),
        'text button on card': (s.primary, c.card),
        'text button on background': (s.primary, c.background),
        'selected nav item': (s.onPrimaryContainer, s.primaryContainer),
        'error text on card': (s.error, c.card),
        'destructive button text': (s.onError, s.error),
        'snackbar text': (s.onInverseSurface, s.inverseSurface),
        'LIVE badge': (c.onLive, c.live),
        'warning on card': (c.warning, c.card),
      };
      for (final MapEntry(key: label, value: (fg, bg)) in pairs.entries) {
        test(label, () {
          expect(contrast(fg, bg), greaterThanOrEqualTo(4.5),
              reason: '$label: ${contrast(fg, bg).toStringAsFixed(2)}:1');
        });
      }
    });
  }

  test('both themes use the bundled font', () {
    expect(AppTheme.light.textTheme.bodyLarge!.fontFamily, 'PlusJakartaSans');
    expect(AppTheme.dark.textTheme.titleLarge!.fontFamily, 'PlusJakartaSans');
  });

  test('type scale matches DESIGN.md', () {
    final t = AppTheme.light.textTheme;
    expect((t.displaySmall!.fontSize, t.displaySmall!.fontWeight),
        (32, FontWeight.w700));
    expect((t.titleLarge!.fontSize, t.titleLarge!.fontWeight),
        (22, FontWeight.w600));
    expect((t.titleMedium!.fontSize, t.titleMedium!.fontWeight),
        (18, FontWeight.w600));
    expect((t.bodyLarge!.fontSize, t.bodyLarge!.fontWeight),
        (16, FontWeight.w400));
    expect((t.labelLarge!.fontSize, t.labelLarge!.fontWeight),
        (14, FontWeight.w500));
    expect((t.bodySmall!.fontSize, t.bodySmall!.fontWeight),
        (12, FontWeight.w400));
  });
}
