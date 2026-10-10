import 'package:flutter/material.dart';

import 'package:dab_fitness/config/theme.dart';

/// A small read-only pill: icon + text (duration, "N watching", ...).
class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  /// Draw on a photo (translucent dark pill, light text).
  final bool onPhoto;

  const InfoChip(
      {super.key,
      required this.icon,
      required this.label,
      this.onPhoto = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final background = onPhoto ? colors.photoChip : colors.inputFill;
    final foreground = onPhoto ? colors.onPhoto : colors.textPrimary;
    return DecoratedBox(
      decoration:
          ShapeDecoration(color: background, shape: const StadiumBorder()),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.labelMedium
                      ?.copyWith(color: foreground)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The red "LIVE" badge for classes happening now.
class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration:
          ShapeDecoration(color: colors.live, shape: const StadiumBorder()),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs / 2),
        child: Text('LIVE',
            style: context.textStyles.labelMedium
                ?.copyWith(color: colors.onLive, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
