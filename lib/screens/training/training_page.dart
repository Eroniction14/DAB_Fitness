import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/config/theme.dart';
import 'package:dab_fitness/data/workout_data.dart';
import 'package:dab_fitness/models/live_class.dart';
import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/screens/live_class/call_page.dart';
import 'package:dab_fitness/screens/trainers/trainer_list_page.dart';
import 'package:dab_fitness/screens/training/video_detail_page.dart';
import 'package:dab_fitness/widgets/app_card.dart';
import 'package:dab_fitness/widgets/info_chip.dart';
import 'package:dab_fitness/widgets/live_class_card.dart';
import 'package:dab_fitness/widgets/page_header.dart';
import 'package:dab_fitness/widgets/refreshable_list.dart';

/// Trainings: in-person categories (→ trainers), workout videos and live
/// classes, switched with a segmented control (or by swiping).
class TrainingPage extends StatefulWidget {
  static const routeName = '/trainingPage';
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  final _pageController = PageController();
  int _page = 0;
  late Stream<List<LiveClass>> _classes;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _classes = context.read<BookingModel>().watchLiveClasses();
    // Re-filter once a minute so classes go live / disappear on time.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// Pull-to-refresh / Retry on live classes: re-subscribe.
  Future<void> _refreshClasses() async {
    setState(() => _classes = context.read<BookingModel>().watchLiveClasses());
  }

  void _goTo(int page) {
    setState(() => _page = page);
    _pageController.animateToPage(page,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const PageHeader(
            title: 'Trainings',
            subtitle: 'In person, on video or live',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, 0),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 0, label: Text('In person')),
                  ButtonSegment(value: 1, label: Text('Videos')),
                  ButtonSegment(value: 2, label: Text('Live')),
                ],
                selected: {_page},
                onSelectionChanged: (s) => _goTo(s.first),
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _page = page),
              children: [
                _inPersonPage(),
                _videosPage(),
                _liveClassesPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _listPadding = EdgeInsets.fromLTRB(
      AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, AppSpacing.xl);

  // ---------- In person: workout categories → trainers ----------

  Widget _inPersonPage() {
    return ListView.separated(
      padding: _listPadding,
      itemCount: workoutCategoryData.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) {
        final category = workoutCategoryData[i];
        return _PhotoCard(
          image: category.image,
          title: category.name,
          caption: 'Find a trainer',
          onTap: () => Navigator.of(context)
              .pushNamed(TrainerListPage.routeName, arguments: category),
        );
      },
    );
  }

  // ---------- Videos ----------

  Widget _videosPage() {
    return ListView.separated(
      padding: _listPadding,
      itemCount: offlineVideosData.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) {
        final video = offlineVideosData[i];
        return _PhotoCard(
          image: video.image,
          title: video.category,
          caption: '${video.workouts.length} workouts',
          icon: Icons.play_circle_outline,
          onTap: () => Navigator.of(context).pushNamed(
            VideoDetailPage.routeName,
            arguments: {
              'category': video.category,
              'workouts': video.workouts,
              'image': video.image,
            },
          ),
        );
      },
    );
  }

  // ---------- Live classes ----------

  Widget _liveClassesPage() {
    return StreamBuilder<List<LiveClass>>(
      stream: _classes,
      builder: (context, snapshot) => RefreshableList<LiveClass>(
        items: upcomingClasses(snapshot.data ?? const [], DateTime.now()),
        isLoading: !snapshot.hasData && !snapshot.hasError,
        error: snapshot.error,
        onRefresh: _refreshClasses,
        emptyTitle: 'No upcoming live classes',
        emptyHint: 'Pull down to check again.',
        emptyIcon: Icons.live_tv_outlined,
        skeletonHeight: 220,
        padding: _listPadding,
        itemBuilder: (context, liveClass) => LiveClassCard(
          key: ValueKey(liveClass.key),
          liveClass: liveClass,
          onJoin: () => openLiveClass(context, liveClass, asHost: false),
        ),
      ),
    );
  }
}

/// A full-bleed photo card with a soft bottom gradient behind the title.
class _PhotoCard extends StatelessWidget {
  final String image;
  final String title;
  final String caption;
  final IconData icon;
  final VoidCallback onTap;

  const _PhotoCard({
    required this.image,
    required this.title,
    required this.caption,
    this.icon = Icons.arrow_forward,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onPhoto = context.appColors.onPhoto;
    return AppCard(
      clip: true,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: SizedBox(
        height: 168,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(image, fit: BoxFit.cover),
            DecoratedBox(
                decoration:
                    BoxDecoration(gradient: context.appColors.photoScrim)),
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.titleLarge
                                ?.copyWith(color: onPhoto)),
                        const SizedBox(height: AppSpacing.xs),
                        InfoChip(icon: icon, label: caption, onPhoto: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
