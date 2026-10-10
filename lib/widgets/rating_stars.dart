import 'package:flutter/material.dart';

import 'package:dab_fitness/config/theme.dart';

/// Five stars, [rating] of them filled.
class RatingStars extends StatelessWidget {
  final int rating;
  final double size;
  const RatingStars({super.key, required this.rating, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final color = context.appColors.rating;
    return Semantics(
      label: 'Rated $rating out of 5',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 5; i++)
            Icon(i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size, color: color),
        ],
      ),
    );
  }
}
