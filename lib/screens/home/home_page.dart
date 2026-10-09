import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/data/workout_data.dart';
import 'package:dab_fitness/providers/database_model.dart';
import 'package:dab_fitness/widgets/video_player_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
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
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(firstName.isEmpty
                ? greeting(DateTime.now())
                : '${greeting(DateTime.now())}, $firstName'),
          ),
          SliverFillRemaining(child: buildPage()),
        ],
      ),
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
                      style: Theme.of(context).textTheme.titleLarge),
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
                        style: Theme.of(context).textTheme.titleMedium),
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
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
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
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
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
                          style: Theme.of(context).textTheme.titleMedium,
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
