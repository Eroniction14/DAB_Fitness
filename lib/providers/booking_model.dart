import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:dab_fitness/models/booking.dart';
import 'package:dab_fitness/models/json_helpers.dart';
import 'package:dab_fitness/models/live_class.dart';

const _dbUrl = 'https://dab-fitness-acd05-default-rtdb.firebaseio.com';

/// Accepts a TimeOfDay or an "HH:mm..." string and returns "HH:mm".
String _formatTime(dynamic time) {
  if (time is TimeOfDay) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
  final s = jsonString(time);
  return s.length >= 5 ? s.substring(0, 5) : s;
}

String _newKey() => DateTime.now().microsecondsSinceEpoch.toString();

class BookingModel with ChangeNotifier {
  final String? authToken;
  final String? userId;

  List<Booking> bookings = [];
  List<LiveClass> liveClass = [];

  BookingModel(this.authToken, this.userId);

  List<Booking> get getAppoinments => bookings;
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

  /// The child maps of a node, e.g. every booking under `appointments/<uid>`.
  Iterable<Map<String, dynamic>> _children(Map<String, dynamic>? node) =>
      node == null ? const [] : node.values.whereType<Map<String, dynamic>>();

  /// User books a trainer. Saved under both the user and the trainer.
  Future<bool> book(dynamic date, dynamic time, dynamic address,
      dynamic trainerId, dynamic name) async {
    final key = _newKey();
    final slot = {
      'Date': jsonString(date),
      'Time': _formatTime(time),
      'Address': jsonString(address),
      'Id': userId,
      'user': jsonString(name),
      'TrainerId': jsonString(trainerId),
    };
    final res = await http.patch(
      _uri(''), // root: multi-path update
      body: json.encode({
        'appointments/$userId/$key': slot,
        'trainerAppointments/${jsonString(trainerId)}/$key': slot,
      }),
    );
    if (res.statusCode != 200) return false;
    bookings.add(Booking.fromJson(slot));
    notifyListeners();
    return true;
  }

  /// Trainer: bookings made with me.
  Future<void> getMyAppoinments() async {
    final data = await _get('trainerAppointments/$userId');
    bookings = _children(data).map(Booking.fromJson).toList();
    notifyListeners();
  }

  /// User: bookings I made.
  Future<void> loadMyAppoinments() async {
    final data = await _get('appointments/$userId');
    bookings = _children(data).map(Booking.fromJson).toList();
    notifyListeners();
  }

  /// Trainer schedules a live class. The channel name is the trainer's id.
  Future<List<LiveClass>> startLiveClass(
      dynamic date, dynamic time, dynamic name, dynamic title) async {
    final entry = {
      'Date': jsonString(date),
      'Time': _formatTime(time),
      'Id': userId,
      'user': jsonString(name),
      'title': jsonString(title),
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
