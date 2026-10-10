import 'package:flutter/material.dart';

import 'package:dab_fitness/config/theme.dart';

/// Snackbars with a clear tone: failures use the error colour and an error
/// icon, success and info messages stay neutral.
extension AppSnackBars on ScaffoldMessengerState {
  /// Neutral: confirmations and information.
  void showInfo(String message) {
    hideCurrentSnackBar();
    showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    ));
  }

  /// Something went wrong: error colour, error icon, a little longer.
  void showError(String message) {
    final scheme = Theme.of(context).colorScheme;
    hideCurrentSnackBar();
    showSnackBar(SnackBar(
      backgroundColor: scheme.error,
      duration: const Duration(seconds: 5),
      content: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.onError),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(message,
                style: context.textStyles.bodyMedium
                    ?.copyWith(color: scheme.onError)),
          ),
        ],
      ),
    ));
  }
}
