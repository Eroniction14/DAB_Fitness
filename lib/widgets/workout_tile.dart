import 'package:flutter/material.dart';

import 'package:dab_fitness/config/theme.dart';
import 'package:dab_fitness/models/workout.dart';
import 'package:dab_fitness/widgets/app_card.dart';
import 'package:dab_fitness/widgets/video_player_widget.dart';

/// Plays a workout's video in a dialog.
void playWorkout(BuildContext context, Workout workout) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      clipBehavior: Clip.antiAlias,
      child: VideoPlayerApp(workout.videos),
    ),
  );
}

/// One workout: thumbnail, name, "sets x reps · muscles", play icon.
class WorkoutTile extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;
  const WorkoutTile(this.workout, {super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final secondary = context.appColors.textSecondary;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.inputAll,
            child: Image.asset(workout.image,
                width: 72, height: 72, fit: BoxFit.cover),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(workout.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${workout.sets} × ${workout.reps} · '
                  '${workout.muscleGroupTargeted}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      context.textStyles.bodySmall?.copyWith(color: secondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(Icons.play_circle_outline, color: context.colors.primary),
        ],
      ),
    );
  }
}
