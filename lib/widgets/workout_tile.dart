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
            child: SizedBox.square(
                dimension: 72, child: WorkoutImage(workout.image)),
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

/// A workout photo on the neutral [AppColors.photoBackdrop]. Many workout
/// images are cut-outs on white; multiplying onto the backdrop turns that
/// white into a soft grey (and barely changes full photos), so every card
/// looks alike in both themes.
class WorkoutImage extends StatelessWidget {
  final String asset;
  const WorkoutImage(this.asset, {super.key});

  @override
  Widget build(BuildContext context) {
    final backdrop = context.appColors.photoBackdrop;
    return ColoredBox(
      color: backdrop,
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        color: backdrop,
        colorBlendMode: BlendMode.multiply,
        excludeFromSemantics: true,
        errorBuilder: (context, _, __) => Center(
          child: Icon(Icons.fitness_center,
              color: context.appColors.textSecondary),
        ),
      ),
    );
  }
}

/// A play icon on a translucent dark disc, visible on light and dark images.
class PlayOverlay extends StatelessWidget {
  final double size;
  const PlayOverlay({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration:
          BoxDecoration(color: colors.photoChip, shape: BoxShape.circle),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(Icons.play_arrow_rounded,
            size: size - AppSpacing.lg, color: colors.onPhoto),
      ),
    );
  }
}
