import 'package:flutter/material.dart';

import 'package:dab_fitness/config/theme.dart';

/// A primary button that shows a small spinner while [busy].
class BusyFilledButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback? onPressed;
  const BusyFilledButton(
      {super.key, required this.label, required this.busy, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? SizedBox.square(
              dimension: 22,
              // The button is disabled while busy, so use the primary colour
              // on its grey background rather than onPrimary.
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: context.colors.primary),
            )
          : Text(label),
    );
  }
}
