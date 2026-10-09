import 'package:flutter/material.dart';

import 'package:dab_fitness/config/theme.dart';

/// A circular avatar: the photo if there is one, otherwise the person's
/// initials on a tinted background.
class InitialsAvatar extends StatelessWidget {
  final String name;

  /// Asset path of a photo, or null for initials.
  final String? imageAsset;
  final double radius;

  const InitialsAvatar(
      {super.key, required this.name, this.imageAsset, this.radius = 24});

  static String initialsOf(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final image = imageAsset;
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundImage: image == null ? null : AssetImage(image),
      child: Text(
        initialsOf(name),
        style: (radius >= 32
                ? context.textStyles.titleLarge
                : context.textStyles.titleSmall)
            ?.copyWith(color: scheme.onPrimaryContainer),
      ),
    );
  }
}
