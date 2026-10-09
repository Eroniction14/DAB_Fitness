import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data.dart';
import '../provider/booking_model.dart';
import '../provider/database_model.dart';
import '../widgets/appBar_widget.dart';
import '../widgets/videoplayer_widget.dart';

class HomePage extends StatefulWidget {
  static const routeName = '/home';
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  bool _isInit = true;
  bool _isLoading = false;
  bool _sheetOpen = false;
  List<Slot> appoinments = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) return;
    _isInit = false;
    _isLoading = true;
    final booking = Provider.of<Booking>(context, listen: false);
    booking.loadMyAppoinments().then((_) {
      appoinments = booking.getAppoinments;
    }).catchError((e) {
      debugPrint('Failed to load appointments: $e');
    }).whenComplete(() {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<DataBase>(context, listen: false).getUser;
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      extendBody: true,
      body: Container(
        margin: const EdgeInsets.all(10),
        child: CustomScrollView(
          slivers: [
            MyAppbar("Hello, ${user.name}", "Home", true, user),
            SliverFillRemaining(child: buildPage()),
          ],
        ),
      ),
      bottomSheet: _sessionsSheet(),
    );
  }

  // ---------- Sessions bottom sheet (replaces solid_bottom_sheet) ----------

  Widget _sessionsSheet() {
    return Material(
      elevation: 4,
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _sheetOpen = !_sheetOpen),
            child: Container(
              height: 30,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                gradient: LinearGradient(
                  colors: [Color(0xff00e0ff), Color(0xff095e79)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_sheetOpen ? Icons.arrow_drop_down : Icons.arrow_drop_up),
                  Text("Sessions",
                      style: Theme.of(context).textTheme.titleMedium),
                  Icon(_sheetOpen ? Icons.arrow_drop_down : Icons.arrow_drop_up),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: _sheetOpen
                ? Container(
                    height: 300,
                    color: Theme.of(context).colorScheme.surface,
                    child: _sessionsList(),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _sessionsList() {
    if (appoinments.isEmpty) {
      return Center(
        child: Text("No appointments are scheduled",
            style: Theme.of(context).textTheme.displaySmall),
      );
    }
    return ListView.builder(
      itemCount: appoinments.length,
      itemBuilder: (context, index) {
        final slot = appoinments[index];
        return Dismissible(
          key: ValueKey('${slot.date}-${slot.time}-$index'),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Theme.of(context).colorScheme.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
            child: const Icon(Icons.delete, color: Colors.white, size: 40),
          ),
          confirmDismiss: (direction) => showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Are you sure?',
                  style: Theme.of(context).textTheme.bodyMedium),
              content: Text('Do you want to cancel the appointment?',
                  style: Theme.of(context).textTheme.bodyMedium),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text('No',
                      style: Theme.of(context).textTheme.labelLarge),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text('Yes',
                      style: Theme.of(context).textTheme.labelLarge),
                ),
              ],
            ),
          ),
          onDismissed: (direction) {},
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                leading: const Icon(Icons.alarm_on),
                title: Text(slot.date,
                    style: Theme.of(context).textTheme.bodyMedium),
                subtitle: Text(slot.time,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------- Main page content ----------

  Widget buildPage() {
    const images = [
      'assets/images/1.jpg',
      'assets/images/2.jpg',
      'assets/images/3.jpg',
    ];
    return ListView(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Stack(
            children: [
              SizedBox(
                height: 200,
                child: Swiper(
                  itemBuilder: (context, index) =>
                      Image.asset(images[index], fit: BoxFit.fill),
                  itemCount: images.length,
                  pagination: const SwiperPagination(),
                ),
              ),
              Positioned(
                top: 20,
                left: 5,
                child: Container(
                  width: 125,
                  height: 30,
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.red.shade900, width: 10),
                    ),
                    gradient: const LinearGradient(
                      colors: [Color(0x70434444), Color(0x20ffffff)],
                    ),
                  ),
                  child: Text("Trending",
                      style: Theme.of(context).textTheme.headlineMedium),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 50),
        buildListHorizontal("Top picks for you"),
        const SizedBox(height: 20),
        buildListVertical("5 Minutes work out"),
      ],
    );
  }

  void _playWorkout(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: VideoPlayerApp(workoutList[index].videos),
      ),
    );
  }

  Widget buildListHorizontal(String title) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Container(
            height: 250,
            margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: workoutList.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) => InkWell(
                onTap: () => _playWorkout(index),
                child: Column(
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(workoutList[index].image,
                            fit: BoxFit.fill),
                      ),
                    ),
                    Text(workoutList[index].name,
                        style: Theme.of(context).textTheme.displaySmall),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: -30,
          left: 10,
          child: Card(
            elevation: 10,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child:
                  Text(title, style: Theme.of(context).textTheme.displaySmall),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildListVertical(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child:
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
        ),
        Container(
          height: 500,
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: workoutList.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) => InkWell(
              onTap: () => _playWorkout(index),
              child: Card(
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(workoutList[index].image,
                              fit: BoxFit.fill),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          workoutList[index].name,
                          style: Theme.of(context).textTheme.displaySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.play_circle_outline),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}