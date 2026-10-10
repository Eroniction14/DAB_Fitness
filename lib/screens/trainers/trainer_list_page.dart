import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/config/theme.dart';
import 'package:dab_fitness/models/trainer.dart';
import 'package:dab_fitness/models/workout.dart';
import 'package:dab_fitness/providers/database_model.dart';
import 'package:dab_fitness/screens/trainers/book_trainer.dart';
import 'package:dab_fitness/screens/trainers/trainer_detail_page.dart';
import 'package:dab_fitness/widgets/app_card.dart';
import 'package:dab_fitness/widgets/busy_button.dart';
import 'package:dab_fitness/widgets/empty_state.dart';
import 'package:dab_fitness/widgets/rating_stars.dart';
import 'package:dab_fitness/widgets/refreshable_list.dart';
import 'package:dab_fitness/widgets/app_snackbar.dart';

/// Swipeable trainer cards. Push with a [WorkoutCategory] as the route
/// argument (or [category]) to show only trainers in that category.
class TrainerListPage extends StatefulWidget {
  static const routeName = '/trainerpage';

  /// Overrides the route argument; mainly for tests.
  final WorkoutCategory? category;
  const TrainerListPage({super.key, this.category});

  @override
  State<TrainerListPage> createState() => _TrainerListPageState();
}

class _TrainerListPageState extends State<TrainerListPage> {
  final _pageController = PageController(viewportFraction: 0.85);
  int _index = 0;
  String? _bookingFor; // trainerId currently being booked

  /// The category filter; null shows everyone.
  WorkoutCategory? _category;
  bool _filterRead = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_filterRead) return;
    _filterRead = true;
    _category = widget.category ??
        ModalRoute.of(context)?.settings.arguments as WorkoutCategory?;
  }

  void _showAll() => setState(() {
        _category = null;
        _index = 0;
      });

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final database = context.read<DatabaseModel>();
    final messenger = ScaffoldMessenger.of(context);
    await database.loadTrainers();
    if (database.trainersError != null) {
      messenger
          .showError("Couldn't refresh. Showing the last loaded trainers.");
    }
  }

  Future<void> _book(Trainer trainer) =>
      bookTrainer(context, trainer, onBusy: (busy) {
        if (mounted) {
          setState(() => _bookingFor = busy ? trainer.trainerId : null);
        }
      });

  @override
  Widget build(BuildContext context) {
    final database = context.watch<DatabaseModel>();
    final category = _category;
    final everyone = database.getTrainersData;
    final trainers = category == null
        ? everyone
        : everyone.where((t) => category.matches(t.speciality)).toList();

    if (category != null && trainers.isEmpty && everyone.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(category.name)),
        body: Center(
          child: EmptyState(
            icon: Icons.person_search_outlined,
            title: 'No ${category.name} trainers yet',
            hint: 'Browse all our trainers instead.',
            action: FilledButton(
              onPressed: _showAll,
              child: const Text('Show all trainers'),
            ),
          ),
        ),
      );
    }
    if (trainers.isEmpty) {
      // Loading, error or empty: a pull-to-refreshable message.
      return Scaffold(
        appBar: AppBar(title: Text(category?.name ?? 'Trainers')),
        body: RefreshableList<Trainer>(
          items: const [],
          isLoading: database.trainersLoading,
          error: database.trainersError,
          onRefresh: database.loadTrainers,
          emptyTitle: 'No trainers yet',
          emptyHint: 'Pull down to check again.',
          emptyIcon: Icons.person_search_outlined,
          itemBuilder: (_, __) => const SizedBox.shrink(),
        ),
      );
    }
    final current = trainers[_index.clamp(0, trainers.length - 1)];

    final onPhoto = context.appColors.onPhoto;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: onPhoto,
        title: Text(category?.name ?? 'All trainers',
            style: context.textStyles.titleMedium?.copyWith(color: onPhoto)),
        actions: [
          if (category != null)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: onPhoto),
              onPressed: _showAll,
              child: const Text('Show all'),
            ),
          // The carousel scrolls sideways, so refresh is a button here.
          IconButton(
            tooltip: 'Refresh trainers',
            icon: database.trainersLoading
                ? SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: onPhoto),
                  )
                : const Icon(Icons.refresh),
            onPressed: database.trainersLoading ? null : _refresh,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Full-screen photo of the current trainer, cross-fading on swipe.
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              layoutBuilder: (currentChild, previous) => Stack(
                fit: StackFit.expand,
                children: [...previous, if (currentChild != null) currentChild],
              ),
              child: Image.asset(
                current.image,
                key: ValueKey(current.trainerId),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: context.appColors.photoScrim),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              // Up to 440 tall, but always leave room for the app bar.
              builder: (context, constraints) => Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: (constraints.maxHeight - kToolbarHeight)
                      .clamp(0.0, 440.0),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: trainers.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) => _trainerCard(trainers[i]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trainerCard(Trainer trainer) {
    final isBooking = _bookingFor == trainer.trainerId;
    final text = context.textStyles;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.xl),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: 'View ${trainer.name}',
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => TrainerDetail(trainer)),
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.inputAll,
                    child: Image.asset(trainer.image, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(trainer.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleMedium),
            Row(
              children: [
                Expanded(
                  child: Text(trainer.speciality,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium
                          ?.copyWith(color: context.appColors.textSecondary)),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Shrinks on narrow screens instead of overflowing.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: RatingStars(rating: trainer.rating, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            BusyFilledButton(
                label: 'Book',
                busy: isBooking,
                onPressed: () => _book(trainer)),
          ],
        ),
      ),
    );
  }
}
