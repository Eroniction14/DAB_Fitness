import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data.dart' hide LiveClass;
import '../provider/booking_model.dart';
import '../provider/database_model.dart';
import '../widgets/appBar_widget.dart';
import './call_page.dart';
import './trainer_page.dart';
import './videodetail_page.dart';

class TrainingPage extends StatefulWidget {
  static const routeName = '/trainingPage';
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  final PageController _pageController = PageController();
  int _activePage = 0;
  bool _isInit = true;
  bool _isLoading = false;

  static const _tabs = ["In-Person", "Videos", "Online Classes"];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) return;
    _isInit = false;
    _isLoading = true;
    context.read<Booking>().loadLiveClass().catchError((e) {
      debugPrint('Failed to load live classes: $e');
    }).whenComplete(() {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _onJoin(String channelName) async {
    if (channelName.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallPage(
          channelName: channelName,
          role: ClientRoleType.clientRoleAudience,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveClasses = context.watch<Booking>().getLiveClass;
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
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
                  _onlineClassesPage(liveClasses),
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
        for (final category in workOutCategoryData) _workoutCard(category),
      ],
    );
  }

  Widget _workoutCard(dynamic data) {
    final trainers = context.read<DataBase>().getTrainersData;
    return InkWell(
      onTap: () => Navigator.of(context)
          .pushNamed(TrainerPage.routeName, arguments: trainers),
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

  Widget _videoCard(dynamic data) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(
        VideoDetail.routeName,
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

  Widget _onlineClassesPage(List<LiveClass> liveClasses) {
    if (liveClasses.isEmpty) {
      return Center(
        child: Text("No live classes are available",
            style: Theme.of(context).textTheme.displaySmall),
      );
    }
    return ListView.builder(
      itemCount: liveClasses.length,
      itemBuilder: (context, index) {
        final liveClass = liveClasses[index];
        return _LiveClassCard(
          data: liveClass,
          onJoin: () => _onJoin(liveClass.channelName),
        );
      },
    );
  }
}

/// Tap-to-expand class card (replaces the expansion_card package).
class _LiveClassCard extends StatefulWidget {
  final LiveClass data;
  final VoidCallback onJoin;
  const _LiveClassCard({required this.data, required this.onJoin});

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
                            child: Text("${data.date}, ${data.time}",
                                style: text.displayMedium),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.account_circle, color: Colors.white),
                          const SizedBox(width: 12),
                          Text("${data.participants} attendees",
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