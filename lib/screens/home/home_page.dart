import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/config/theme.dart';
import 'package:dab_fitness/data/workout_data.dart';
import 'package:dab_fitness/models/booking.dart';
import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/providers/database_model.dart';
import 'package:dab_fitness/screens/shell/shell_scope.dart';
import 'package:dab_fitness/widgets/app_card.dart';
import 'package:dab_fitness/widgets/booking_tile.dart';
import 'package:dab_fitness/widgets/page_header.dart';
import 'package:dab_fitness/widgets/workout_tile.dart';

/// The user's Home tab: greeting, next session, top picks and quick
/// workouts.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  /// "Good morning" / "Good afternoon" / "Good evening".
  static String greeting(DateTime now) => now.hour < 12
      ? 'Good morning'
      : now.hour < 17
          ? 'Good afternoon'
          : 'Good evening';

  @override
  Widget build(BuildContext context) {
    final user = context.watch<DatabaseModel>().getUser;
    final firstName = user.name.trim().split(' ').first;
    final hello = greeting(DateTime.now());

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: firstName.isEmpty ? hello : '$hello, $firstName',
            subtitle: "Ready for today's workout?",
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: const [
                _Section('Next session'),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  child: _NextSessionCard(),
                ),
                _Section('Top picks for you'),
                _TopPicks(),
                _Section('5 minute workouts'),
                _QuickWorkouts(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.xl, AppSpacing.screen, AppSpacing.md),
        child: Semantics(
          header: true,
          child: Text(title, style: context.textStyles.titleMedium),
        ),
      );
}

/// The soonest upcoming booking, or a prompt to book one.
class _NextSessionCard extends StatelessWidget {
  const _NextSessionCard();

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingModel>();
    final shell = ShellScope.maybeOf(context);
    // Never a past session: groupBookings puts anything already started
    // in Past.
    final Booking? next =
        groupBookings(booking.getAppoinments, DateTime.now()).next;

    if (booking.bookingsLoading && next == null) {
      return Container(
        height: 88,
        decoration: BoxDecoration(
          color: context.appColors.inputFill,
          borderRadius: AppRadius.cardAll,
        ),
      );
    }
    if (next == null) {
      final trainingsTab = shell?.trainingsTab;
      return AppCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No session booked',
                      style: context.textStyles.titleMedium),
                  Text('Book a trainer for an in-person session.',
                      style: context.textStyles.bodyMedium
                          ?.copyWith(color: context.appColors.textSecondary)),
                ],
              ),
            ),
            if (shell != null && trainingsTab != null) ...[
              const SizedBox(width: AppSpacing.md),
              FilledButton(
                onPressed: () => shell.selectTab(trainingsTab),
                child: const Text('Book'),
              ),
            ],
          ],
        ),
      );
    }
    final trainerName =
        context.watch<DatabaseModel>().trainerName(next.trainerId);
    return AppCard(
      onTap: shell == null ? null : () => shell.selectTab(shell.bookingsTab),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              borderRadius: AppRadius.inputAll,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Icon(Icons.event_available,
                  color: context.colors.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    trainerName == null
                        ? 'Your next session'
                        : 'With $trainerName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.titleMedium),
                Text(bookingWhen(next),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodyMedium
                        ?.copyWith(color: context.appColors.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.appColors.textSecondary),
        ],
      ),
    );
  }
}

/// Horizontal workout cards: photo with the name under it.
class _TopPicks extends StatelessWidget {
  const _TopPicks();

  static const _cardWidth = 168.0;
  static const _imageHeight = 132.0;

  @override
  Widget build(BuildContext context) {
    // Room for two lines of the name at the current text size.
    final textHeight = MediaQuery.textScalerOf(context)
            .scale(context.textStyles.titleSmall!.fontSize!) *
        1.3 *
        2;
    return SizedBox(
      height: _imageHeight + textHeight + AppSpacing.card * 2 + AppSpacing.sm,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        // Leave room for the card shadow.
        clipBehavior: Clip.none,
        itemCount: workoutList.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final workout = workoutList[index];
          return SizedBox(
            width: _cardWidth,
            child: AppCard(
              clip: true,
              padding: EdgeInsets.zero,
              onTap: () => playWorkout(context, workout),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: _imageHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        WorkoutImage(workout.image),
                        const Center(child: PlayOverlay()),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(workout.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.titleSmall),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A list of short workouts with thumbnail, sets/reps and target muscles.
class _QuickWorkouts extends StatelessWidget {
  const _QuickWorkouts();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Column(
        children: [
          for (final workout in workoutList) ...[
            WorkoutTile(workout, onTap: () => playWorkout(context, workout)),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
