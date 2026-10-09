import 'package:dab_fitness/models/json_helpers.dart';

/// A trainer-hosted live video class, stored at `liveClass/{trainerId}/{key}`.
class LiveClass {
  static const defaultImage = 'assets/images/Strength.jpg';

  final String date;
  final String time;
  final String title;

  /// uid of the hosting trainer (the legacy `Id` field).
  final String trainerId;

  /// Name of the hosting trainer (the legacy `user` field).
  final String name;

  /// Agora channel; always the trainer's uid.
  final String channelName;
  final int participants;
  final String image;

  LiveClass({
    required this.date,
    required this.time,
    required this.title,
    required this.trainerId,
    required this.name,
    required this.participants,
    required this.channelName,
    required this.image,
  });

  factory LiveClass.fromJson(Map<String, dynamic> d) => LiveClass(
        date: jsonString(d['Date']),
        time: jsonString(d['Time']),
        title: jsonString(d['title']),
        trainerId: jsonString(d['Id']),
        name: jsonString(d['user']),
        participants: jsonInt(d['participants']),
        channelName: jsonString(d['channelName']),
        image: d['image'] == null ? defaultImage : jsonString(d['image']),
      );

  Map<String, dynamic> toJson() => {
        'Date': date,
        'Time': time,
        'Id': trainerId,
        'user': name,
        'title': title,
        'participants': participants,
        'channelName': channelName,
        'image': image,
      };
}
