import 'package:flutter/material.dart';

import 'package:dab_fitness/config/theme.dart';
import 'package:dab_fitness/models/live_class.dart';
import 'package:dab_fitness/widgets/app_card.dart';
import 'package:dab_fitness/widgets/booking_tile.dart';
import 'package:dab_fitness/widgets/info_chip.dart';

/// A live class: photo (with a LIVE badge while it's on), title, trainer,
/// time, duration and "N watching" chips, and a Join button.
class LiveClassCard extends StatelessWidget {
  final LiveClass liveClass;
  final VoidCallback onJoin;

  /// Label of the action button ("Join" for users, "Start" for trainers).
  final String actionLabel;

  const LiveClassCard({
    super.key,
    required this.liveClass,
    required this.onJoin,
    this.actionLabel = 'Join',
  });

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    final secondary = context.appColors.textSecondary;
    final live = liveClass.isLive(DateTime.now());

    return AppCard(
      clip: true,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 140,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(liveClass.image, fit: BoxFit.cover),
                DecoratedBox(
                    decoration:
                        BoxDecoration(gradient: context.appColors.photoScrim)),
                if (live)
                  const Positioned(
                      top: AppSpacing.md,
                      left: AppSpacing.md,
                      child: LiveBadge()),
                Positioned(
                  left: AppSpacing.md,
                  bottom: AppSpacing.md,
                  right: AppSpacing.md,
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      InfoChip(
                          icon: Icons.timer_outlined,
                          label: '${liveClass.durationMinutes} min',
                          onPhoto: true),
                      InfoChip(
                          icon: Icons.visibility_outlined,
                          label: '${liveClass.participants} watching',
                          onPhoto: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.card),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(liveClass.title,
                          style: text.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        [
                          if (liveClass.name.isNotEmpty) liveClass.name,
                          '${friendlyDate(liveClass.date)}, ${liveClass.time}',
                        ].join(' · '),
                        style: text.bodyMedium?.copyWith(color: secondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                FilledButton(onPressed: onJoin, child: Text(actionLabel)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
