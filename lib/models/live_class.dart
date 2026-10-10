import 'package:dab_fitness/models/json_helpers.dart';

/// A trainer-hosted live video class, stored at `liveClass/{trainerId}/{key}`.
class LiveClass {
  static const defaultImage = 'assets/images/Strength.jpg';

  /// Durations a trainer can choose when scheduling.
  static const durationChoices = [30, 45, 60, 90];

  /// Used for classes saved before durations existed.
  static const defaultDurationMinutes = 60;

  /// Database key. Empty until the class is saved.
  final String key;
  final String date;
  final String time;
  final String title;

  /// uid of the hosting trainer (the legacy `Id` field).
  final String trainerId;

  /// Name of the hosting trainer (the legacy `user` field).
  final String name;

  /// Agora channel; always the trainer's uid.
  final String channelName;
  final int durationMinutes;

  /// Users currently in the class: the size of the `attendees` map, which
  /// each user adds themselves to on join and removes on leave/disconnect.
  /// Falls back to the legacy `participants` number for old classes.
  final int participants;
  final String image;

  LiveClass({
    this.key = '',
    required this.date,
    required this.time,
    required this.title,
    required this.trainerId,
    required this.name,
    this.durationMinutes = defaultDurationMinutes,
    required this.participants,
    required this.channelName,
    required this.image,
  });

  factory LiveClass.fromJson(String key, Map<String, dynamic> d) {
    final attendees = asJsonMap(d['attendees']);
    final duration = jsonInt(d['duration']);
    return LiveClass(
      key: key,
      date: jsonString(d['Date']),
      time: jsonString(d['Time']),
      title: jsonString(d['title']),
      trainerId: jsonString(d['Id']),
      name: jsonString(d['user']),
      durationMinutes: duration > 0 ? duration : defaultDurationMinutes,
      participants:
          attendees != null ? attendees.length : jsonInt(d['participants']),
      channelName: jsonString(d['channelName']),
      image: d['image'] == null ? defaultImage : jsonString(d['image']),
    );
  }

  /// When the class starts, or null if the stored date/time is malformed.
  DateTime? get startsAt => DateTime.tryParse('${date}T$time');

  DateTime? get endsAt => startsAt?.add(Duration(minutes: durationMinutes));

  /// Whether the class is happening at [now] (started, not yet over).
  bool isLive(DateTime now) {
    final start = startsAt;
    return start != null && !start.isAfter(now) && !isOver(now);
  }

  /// Whether the class has finished by [now]. Malformed dates count as over.
  bool isOver(DateTime now) {
    final end = endsAt;
    return end == null || !end.isAfter(now);
  }

  Map<String, dynamic> toJson() => {
        'Date': date,
        'Time': time,
        'Id': trainerId,
        'user': name,
        'title': title,
        'participants': 0,
        'duration': durationMinutes,
        'channelName': channelName,
        'image': image,
      };
}

/// The classes in [classes] that haven't finished by [now], soonest first.
List<LiveClass> upcomingClasses(Iterable<LiveClass> classes, DateTime now) =>
    classes.where((c) => !c.isOver(now)).toList()
      ..sort((a, b) => a.startsAt!.compareTo(b.startsAt!));
