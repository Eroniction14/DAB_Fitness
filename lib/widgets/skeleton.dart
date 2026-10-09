import 'package:flutter/material.dart';

import 'package:dab_fitness/config/theme.dart';

/// Placeholder rows shown while a list loads: grey blocks with a gentle
/// pulse (no shimmer).
class SkeletonList extends StatefulWidget {
  final int count;
  final double itemHeight;
  final EdgeInsetsGeometry? padding;

  const SkeletonList({
    super.key,
    this.count = 4,
    this.itemHeight = 84,
    this.padding,
  });

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fill = context.appColors.inputFill;
    return Semantics(
      label: 'Loading',
      child: FadeTransition(
        opacity: _pulse,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: widget.padding ??
              const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen, vertical: AppSpacing.lg),
          itemCount: widget.count,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, __) => Container(
            height: widget.itemHeight,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: AppRadius.cardAll,
            ),
          ),
        ),
      ),
    );
  }
}
