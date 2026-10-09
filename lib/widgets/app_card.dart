import 'package:flutter/material.dart';

import 'package:dab_fitness/config/theme.dart';

/// The standard card: surface colour, radius 20, the one soft shadow and
/// 16 internal padding. Tappable when [onTap] is set.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  /// Clip the child to the card's corners (for full-bleed photos).
  final bool clip;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.card),
    this.margin = EdgeInsets.zero,
    this.clip = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: AppRadius.cardAll,
          boxShadow: colors.cardShadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: AppRadius.cardAll,
          clipBehavior: clip ? Clip.antiAlias : Clip.none,
          child: InkWell(
            borderRadius: AppRadius.cardAll,
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
