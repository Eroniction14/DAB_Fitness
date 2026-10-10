import 'package:flutter/material.dart';

import 'package:dab_fitness/config/theme.dart';

/// A tappable field-like tile for pickers (date, time): icon, label and
/// the chosen value (or a placeholder), on the input fill colour.
class PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  const PickerTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      label: '$label: ${value ?? placeholder}',
      excludeSemantics: true,
      child: Material(
        color: colors.inputFill,
        borderRadius: AppRadius.inputAll,
        child: InkWell(
          borderRadius: AppRadius.inputAll,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(icon, color: context.colors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label,
                            style: context.textStyles.bodySmall
                                ?.copyWith(color: colors.inputLabel)),
                        Text(value ?? placeholder,
                            style: context.textStyles.bodyLarge?.copyWith(
                                color: value == null
                                    ? colors.inputLabel
                                    : colors.textPrimary)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: colors.inputLabel),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
