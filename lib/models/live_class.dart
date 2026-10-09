import 'package:dab_fitness/models/json_helpers.dart';

class LiveClass {
  final String date;
  final String time;
  final String title;
  final String name;
  final String channelName;
  final int participants;
  final String image;

  LiveClass({
    required this.date,
    required this.time,
    required this.title,
    required this.name,
    required this.participants,
    required this.channelName,
    required this.image,
  });

  factory LiveClass.fromJson(Map<String, dynamic> d) => LiveClass(
        date: jsonString(d['Date']),
        time: jsonString(d['Time']),
        title: jsonString(d['title']),
        name: jsonString(d['user']),
        participants: jsonInt(d['participants']),
        channelName: jsonString(d['channelName']),
        image: d['image'] == null
            ? 'assets/images/Strength.jpg'
            : jsonString(d['image']),
      );
}
