import 'package:flutter/material.dart';

import 'package:dab_fitness/config/theme.dart';

/// Icon in a soft tinted circle, a short title, a one-line hint and an
/// optional action (DESIGN.md "Empty states").
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? hint;
  final Widget? action;

  /// Use the error colour for the icon circle (load failures).
  final bool isError;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
    this.action,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final tint = isError ? scheme.errorContainer : scheme.primaryContainer;
    final onTint =
        isError ? scheme.onErrorContainer : scheme.onPrimaryContainer;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Icon(icon, size: 32, color: onTint),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(title,
              textAlign: TextAlign.center,
              style: context.textStyles.titleMedium),
          if (hint != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(hint!,
                textAlign: TextAlign.center,
                style: context.textStyles.bodyMedium
                    ?.copyWith(color: context.appColors.textSecondary)),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}
