import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _dbUrl = 'https://dab-fitness-acd05-default-rtdb.firebaseio.com';

String _str(dynamic v) => v?.toString() ?? '';
int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

/// Accepts a TimeOfDay or an "HH:mm..." string and returns "HH:mm".
String _formatTime(dynamic time) {
  if (time is TimeOfDay) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
  final s = _str(time);
  return s.length >= 5 ? s.substring(0, 5) : s;
}

String _newKey() => DateTime.now().microsecondsSinceEpoch.toString();

class Slot {
  final String date;
  final String time;
  final String address;
  final String trainerId;
  final String user;

  Slot({
    required this.date,
    required this.time,
    required this.address,
    required this.trainerId,
    required this.user,
  });

  factory Slot.fromJson(Map<String, dynamic> d) => Slot(
        date: _str(d['Date']),
        time: _str(d['Time']),
        address: _str(d['Address']),
        trainerId: _str(d['TrainerId']),
        user: _str(d['user']),
      );
}

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
        date: _str(d['Date']),
        time: _str(d['Time']),
        title: _str(d['title']),
        name: _str(d['user']),
        participants: _int(d['participants']),
        channelName: _str(d['channelName']),
        image: d['image'] == null
            ? 'assets/images/Strength.jpg'
            : _str(d['image']),
      );
}

class Booking with ChangeNotifier {
  final String? authToken;
  final String? userId;

  List<Slot> bookings = [];
  List<LiveClass> liveClass = [];

  Booking(this.authToken, this.userId);

  List<Slot> get getAppoinments => bookings;
  List<LiveClass> get getLiveClass => liveClass;

  Uri _uri(String path) => Uri.parse('$_dbUrl/$path.json?auth=$authToken');

  Future<Map<String, dynamic>?> _get(String path) async {
    final res = await http.get(_uri(path));
    if (res.statusCode != 200) {
      throw Exception('GET $path failed (${res.statusCode}): ${res.body}');
    }
    final body = json.decode(res.body);
    return body is Map<String, dynamic> ? body : null;
  }

  /// The child maps of a node, e.g. every booking under appointments/<uid>.
  Iterable<Map<String, dynamic>> _children(Map<String, dynamic>? node) =>
      node == null ? const [] : node.values.whereType<Map<String, dynamic>>();

  /// User books a trainer. Saved under both the user and the trainer.
  Future<bool> book(dynamic date, dynamic time, dynamic address,
      dynamic trainerId, dynamic name) async {
    final key = _newKey();
    final slot = {
      'Date': _str(date),
      'Time': _formatTime(time),
      'Address': _str(address),
      'Id': userId,
      'user': _str(name),
      'TrainerId': _str(trainerId),
    };
    final res = await http.patch(
      _uri(''), // root: multi-path update
      body: json.encode({
        'appointments/$userId/$key': slot,
        'trainerAppointments/${_str(trainerId)}/$key': slot,
      }),
    );
    if (res.statusCode != 200) return false;
    bookings.add(Slot.fromJson(slot));
    notifyListeners();
    return true;
  }

  /// Trainer: bookings made with me.
  Future<void> getMyAppoinments() async {
    final data = await _get('trainerAppointments/$userId');
    bookings = _children(data).map(Slot.fromJson).toList();
    notifyListeners();
  }

  /// User: bookings I made.
  Future<void> loadMyAppoinments() async {
    final data = await _get('appointments/$userId');
    bookings = _children(data).map(Slot.fromJson).toList();
    notifyListeners();
  }

  /// Trainer schedules a live class. The channel name is the trainer's id.
  Future<List<LiveClass>> startLiveClass(
      dynamic date, dynamic time, dynamic name, dynamic title) async {
    final entry = {
      'Date': _str(date),
      'Time': _formatTime(time),
      'Id': userId,
      'user': _str(name),
      'title': _str(title),
      'participants': 0,
      'channelName': userId,
      'image': 'assets/images/Strength.jpg',
    };
    final res = await http.post(
      _uri('liveClass/$userId'),
      body: json.encode(entry),
    );
    if (res.statusCode == 200) {
      liveClass.add(LiveClass.fromJson(entry));
      notifyListeners();
    }
    return liveClass;
  }

  /// User: every trainer's live classes.
  Future<void> loadLiveClass() async {
    final data = await _get('liveClass');
    liveClass = [
      for (final trainerClasses in _children(data))
        ..._children(trainerClasses).map(LiveClass.fromJson),
    ];
    notifyListeners();
  }

  /// Trainer: my own live classes.
  Future<void> loadLiveClassTrainer() async {
    final data = await _get('liveClass/$userId');
    liveClass = _children(data).map(LiveClass.fromJson).toList();
    notifyListeners();
  }
}