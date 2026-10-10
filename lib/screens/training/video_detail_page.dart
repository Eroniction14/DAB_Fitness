import 'package:flutter/material.dart';

import 'package:dab_fitness/config/theme.dart';
import 'package:dab_fitness/models/workout.dart';
import 'package:dab_fitness/widgets/info_chip.dart';
import 'package:dab_fitness/widgets/workout_tile.dart';

/// A video category: photo header, summary and its workouts (tap to play).
/// Expects `{'category', 'workouts', 'image'}` as route arguments.
class VideoDetailPage extends StatelessWidget {
  static const routeName = '/videodetail';
  const VideoDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = ModalRoute.of(context)!.settings.arguments as Map;
    final workouts = (data['workouts'] as List).cast<Workout>();
    final text = context.textStyles;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: IconButton.filledTonal(
                tooltip: 'Back',
                icon: const BackButtonIcon(),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background:
                  Image.asset(data['image'] as String, fit: BoxFit.cover),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.lg,
                AppSpacing.screen, AppSpacing.xl),
            sliver: SliverList.list(
              children: [
                Text(data['category'] as String, style: text.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    const InfoChip(icon: Icons.timer_outlined, label: '30 min'),
                    InfoChip(
                        icon: Icons.fitness_center,
                        label: '${workouts.length} workouts'),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Perfect for training your body and endurance.',
                    style: text.bodyLarge
                        ?.copyWith(color: context.appColors.textSecondary)),
                const SizedBox(height: AppSpacing.xl),
                Text('Programs', style: text.titleMedium),
                const SizedBox(height: AppSpacing.md),
                for (final workout in workouts) ...[
                  WorkoutTile(workout,
                      onTap: () => playWorkout(context, workout)),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
