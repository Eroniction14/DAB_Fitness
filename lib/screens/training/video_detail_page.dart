import 'package:flutter/material.dart';

import 'package:dab_fitness/widgets/video_player_widget.dart';

/// Curves the bottom edge inward by [arcHeight] (replaces shape_of_view's ArcShape).
class _BottomArcClipper extends CustomClipper<Path> {
  final double arcHeight;
  const _BottomArcClipper(this.arcHeight);

  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height)
      ..quadraticBezierTo(
        size.width / 2, size.height - 2 * arcHeight, // dips arcHeight at centre
        size.width, size.height,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(_BottomArcClipper old) => old.arcHeight != arcHeight;
}

class VideoDetailPage extends StatelessWidget {
  static const routeName = '/videodetail';
  const VideoDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = ModalRoute.of(context)!.settings.arguments as Map;
    const topCorners = BorderRadius.only(
      topLeft: Radius.elliptical(300, 40),
      topRight: Radius.elliptical(300, 40),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        child: SizedBox(
          height: 900,
          child: Stack(
            children: [
              SizedBox(
                height: 300,
                width: double.infinity,
                child: PhysicalShape(
                  clipper: const _BottomArcClipper(50),
                  elevation: 5,
                  color: Colors.white,
                  child: Image.asset(data['image'], fit: BoxFit.fill),
                ),
              ),
              Positioned(
                top: 100,
                left: 5,
                right: 5,
                child: Card(
                  margin: const EdgeInsets.only(top: 150),
                  elevation: 10,
                  shape: const RoundedRectangleBorder(borderRadius: topCorners),
                  child: SizedBox(
                    height: 700,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 30, left: 20, right: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  data['category'],
                                  style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Text(
                                "30 mins",
                                style:
                                    TextStyle(fontSize: 20, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 10, left: 10),
                          child: Text(
                            "Perfect For Training Your Body And Endurance",
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Padding(
                          padding:
                              EdgeInsets.only(top: 10, left: 10, bottom: 10),
                          child: Text(
                            "Programs",
                            style: TextStyle(
                                fontSize: 25, fontWeight: FontWeight.bold),
                          ),
                        ),
                        buildPrograms(data),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPrograms(Map data) {
    final workouts = data['workouts'] as List;
    return Container(
      height: 440,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: ListView.separated(
        itemCount: workouts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final workout = workouts[index];
          return InkWell(
            onTap: () => showDialog(
              context: context,
              builder: (_) => Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: VideoPlayerApp(workout.videos),
              ),
            ),
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
                        child: Image.asset(workout.image, fit: BoxFit.fill),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        workout.name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Icon(Icons.play_circle_outline),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}