import 'dart:async';

import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/data/workout_data.dart';
import 'package:dab_fitness/models/live_class.dart';
import 'package:dab_fitness/models/workout.dart';
import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/screens/live_class/call_page.dart';
import 'package:dab_fitness/screens/trainers/trainer_list_page.dart';
import 'package:dab_fitness/screens/training/video_detail_page.dart';
import 'package:dab_fitness/widgets/app_bar_widget.dart';
import 'package:dab_fitness/widgets/refreshable_list.dart';

class TrainingPage extends StatefulWidget {
  static const routeName = '/trainingPage';
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  final PageController _pageController = PageController();
  int _activePage = 0;
  late Stream<List<LiveClass>> _classes;
  Timer? _ticker;

  static const _tabs = ["In-Person", "Videos", "Online Classes"];

  @override
  void initState() {
    super.initState();
    _classes = context.read<BookingModel>().watchLiveClasses();
    // Re-filter once a minute so classes disappear when they end.
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

  /// Pull-to-refresh / Retry on Online Classes: re-subscribe.
  Future<void> _refreshClasses() async {
    setState(() => _classes = context.read<BookingModel>().watchLiveClasses());
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: CustomScrollView(
          slivers: [
            MyAppbar("Choose your Way", "Trainings", false, null),
            SliverToBoxAdapter(child: _pageIndicator()),
            SliverFillRemaining(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _activePage = index),
                children: [
                  _inPersonPage(),
                  _videosPage(),
                  _onlineClassesPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Tabs ----------

  Widget _pageIndicator() {
    const pill = BorderRadius.all(Radius.circular(30));
    return Card(
      color: Colors.grey,
      elevation: 4,
      shape: const RoundedRectangleBorder(borderRadius: pill),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            for (int i = 0; i < _tabs.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => _goToPage(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: i == _activePage ? Colors.white : Colors.grey,
                      borderRadius: pill,
                    ),
                    child: Text(
                      _tabs[i],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 15),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------- Page 1: In-person (workout categories → trainers) ----------

  Widget _inPersonPage() {
    return ListView(
      padding: const EdgeInsets.only(top: 20),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text("Featured Workout Collections",
              style: Theme.of(context).textTheme.headlineMedium),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 10),
          child: Text("Get guidance to reach your goals",
              style: Theme.of(context).textTheme.bodyLarge),
        ),
        for (final category in workoutCategoryData) _workoutCard(category),
      ],
    );
  }

  Widget _workoutCard(WorkoutCategory data) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(TrainerListPage.routeName),
      child: Card(
        margin: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 200,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(data.image, fit: BoxFit.cover),
              Positioned(
                bottom: 10,
                left: 10,
                child: Text(data.name,
                    style: Theme.of(context).textTheme.headlineSmall),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Page 2: Videos ----------

  Widget _videosPage() {
    const images = [
      'assets/images/6.jpg',
      'assets/images/11.jpg',
      'assets/images/12.jpg',
    ];
    return ListView(
      children: [
        Container(
          height: 200,
          margin: const EdgeInsets.all(10),
          child: Swiper(
            itemBuilder: (context, index) =>
                Image.asset(images[index], fit: BoxFit.fill),
            itemCount: images.length,
            pagination: const SwiperPagination(),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text("What's New",
              style: Theme.of(context).textTheme.headlineMedium),
        ),
        const SizedBox(height: 20),
        for (final video in offlineVideosData) _videoCard(video),
      ],
    );
  }

  Widget _videoCard(VideoCategory data) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(
        VideoDetailPage.routeName,
        arguments: {
          'category': data.category,
          'workouts': data.workouts,
          'image': data.image,
        },
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 10),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 200,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 10),
                  child: Text(data.category,
                      style: Theme.of(context).textTheme.displaySmall),
                ),
              ),
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(data.image, fit: BoxFit.cover),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0x50828585), Color(0x20e3e3e3)],
                        ),
                      ),
                    ),
                    const Icon(Icons.play_circle_outline,
                        color: Colors.white70, size: 50),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Page 3: Online live classes ----------

  Widget _onlineClassesPage() {
    return StreamBuilder<List<LiveClass>>(
      stream: _classes,
      builder: (context, snapshot) => RefreshableList<LiveClass>(
        items: upcomingClasses(snapshot.data ?? const [], DateTime.now()),
        isLoading: !snapshot.hasData && !snapshot.hasError,
        error: snapshot.error,
        onRefresh: _refreshClasses,
        emptyMessage: "No upcoming live classes right now.\nPull to refresh.",
        emptyIcon: Icons.live_tv,
        itemBuilder: (context, liveClass) => _LiveClassCard(
          key: ValueKey(liveClass.key),
          data: liveClass,
          onJoin: () => openLiveClass(context, liveClass, asHost: false),
        ),
      ),
    );
  }
}

/// Tap-to-expand class card (replaces the expansion_card package).
class _LiveClassCard extends StatefulWidget {
  final LiveClass data;
  final VoidCallback onJoin;
  const _LiveClassCard({super.key, required this.data, required this.onJoin});

  @override
  State<_LiveClassCard> createState() => _LiveClassCardState();
}

class _LiveClassCardState extends State<_LiveClassCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final text = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.all(10),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(data.image, fit: BoxFit.cover)),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black12, Colors.black54],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 50),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data.title, style: text.headlineSmall),
                              Text(data.name, style: text.displayMedium),
                            ],
                          ),
                        ),
                        Icon(
                          _expanded
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          color: Colors.white,
                          size: 32,
                        ),
                      ],
                    ),
                    if (_expanded) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.white),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                                "${data.date}, ${data.time}"
                                " (${data.durationMinutes} min)",
                                style: text.displayMedium),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.account_circle, color: Colors.white),
                          const SizedBox(width: 12),
                          Text("${data.participants} watching",
                              style: text.displayMedium),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: widget.onJoin,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white),
                          child: Text("Join", style: text.labelLarge),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
