import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../provider/booking_model.dart';
import '../provider/database_model.dart';
import '../utils/location_helper.dart';

class TrainerDetail extends StatefulWidget {
  final Trainer trainer;
  const TrainerDetail(this.trainer, {super.key});

  @override
  State<TrainerDetail> createState() => _TrainerDetailState();
}

class _TrainerDetailState extends State<TrainerDetail> {
  bool _expandText = false;
  bool _isBooking = false;

  Trainer get trainer => widget.trainer;

  Future<void> _openBooking() async {
    final slot = await showDialog<BookingSlot>(
      context: context,
      builder: (_) => const BookingDialog(),
    );
    if (slot == null || !mounted) return;

    setState(() => _isBooking = true);
    final booking = context.read<Booking>();
    final userName = context.read<DataBase>().user?.name ?? '';
    final messenger = ScaffoldMessenger.of(context);

    try {
      final city = await getCity();
      final ok = await booking.book(
        DateFormat('yyyy-MM-dd').format(slot.date),
        slot.time,
        city,
        trainer.trainerId,
        userName,
      );
      messenger.showSnackBar(SnackBar(
        content: Text(ok
            ? 'Booked with ${trainer.name}!'
            : 'Booking failed. Please try again.'),
        duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      debugPrint('Booking failed: $e');
      messenger.showSnackBar(const SnackBar(
        content: Text('Could not connect. Check your internet connection.'),
      ));
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                  start: 56, bottom: 16, end: 16),
              title: Text(
                trainer.name,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(trainer.image, fit: BoxFit.cover),
                  // Fade to white at the bottom so the title stays readable.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.white],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(30, 20, 30, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text("Speciality: ${trainer.speciality}",
                    style: const TextStyle(color: Colors.black, fontSize: 18)),
                const SizedBox(height: 20),
                _description(),
                const SizedBox(height: 20),
                _field("Age", Text(trainer.age, style: _valueStyle)),
                _field("Rating", _ratingBar(trainer.rating)),
                _field(
                    "Experience",
                    Text(
                        "${trainer.experience} year${trainer.experience == 1 ? '' : 's'}",
                        style: _valueStyle)),
                _field("Contact Number", Text(trainer.number, style: _valueStyle),
                    divider: false),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 8, 30, 16),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isBooking ? null : _openBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1BC0C5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: _isBooking
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text("Book a session",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }

  static const _labelStyle =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 20);
  static const _valueStyle = TextStyle(fontSize: 16);

  Widget _description() {
    return InkWell(
      onTap: () => setState(() => _expandText = !_expandText),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trainer.description,
            maxLines: _expandText ? null : 3,
            overflow: _expandText ? null : TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black, fontSize: 18),
          ),
          if (trainer.description.length > 120)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_expandText ? "Show less" : "Read more",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _field(String label, Widget value, {bool divider = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 10),
        value,
        if (divider) const Divider(height: 30),
      ],
    );
  }

  Widget _ratingBar(int rating) {
    return Row(
      children: [
        for (int i = 0; i < 5; i++)
          Icon(i < rating ? Icons.star : Icons.star_border,
              color: Colors.orange.shade700),
      ],
    );
  }
}

// ---------- "Pick a date and time" dialog ----------

class BookingSlot {
  final DateTime date;
  final TimeOfDay time;
  const BookingSlot(this.date, this.time);
}

class BookingDialog extends StatefulWidget {
  const BookingDialog();

  @override
  State<BookingDialog> createState() => BookingDialogState();
}

class BookingDialogState extends State<BookingDialog> {
  DateTime? _date;
  TimeOfDay? _time;
  String? _error;

  bool _notSunday(DateTime d) => d.weekday != DateTime.sunday;

  DateTime _firstSelectableDay() {
    var day = DateUtils.dateOnly(DateTime.now());
    if (!_notSunday(day)) day = day.add(const Duration(days: 1));
    return day;
  }

  Future<void> _pickDate() async {
    final first = _firstSelectableDay();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? first,
      firstDate: first,
      lastDate: DateTime(2100),
      selectableDayPredicate: _notSunday,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    if (_date == null || _time == null) {
      setState(() => _error = 'Pick a date and a time');
      return;
    }
    Navigator.of(context).pop(BookingSlot(_date!, _time!));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Choose a time",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event),
                    label: Text(_date == null
                        ? 'Date'
                        : DateFormat('d MMM, yyyy').format(_date!)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time),
                    label:
                        Text(_time == null ? 'Time' : _time!.format(context)),
                  ),
                ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1BC0C5),
                foregroundColor: Colors.white,
              ),
              child: const Text("Book"),
            ),
          ],
        ),
      ),
    );
  }
}