import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/models/booking.dart';
import 'package:dab_fitness/models/live_class.dart';
import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/providers/database_model.dart';
import 'package:dab_fitness/screens/live_class/call_page.dart';
import 'package:dab_fitness/widgets/app_bar_widget.dart';
import 'package:dab_fitness/widgets/booking_tile.dart';
import 'package:dab_fitness/widgets/collapsible_sheet.dart';
import 'package:dab_fitness/widgets/refreshable_list.dart';

class TrainerHomePage extends StatefulWidget {
  static const routeName = '/trainerHome';
  const TrainerHomePage({super.key});

  @override
  State<TrainerHomePage> createState() => _TrainerHomePageState();
}

class _TrainerHomePageState extends State<TrainerHomePage> {
  late Stream<List<LiveClass>> _classes;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    final booking = context.read<BookingModel>();
    // After the first frame, because loading notifies listeners straight away.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => booking.getMyAppoinments());
    _classes = booking.watchLiveClasses(mine: true);
    // Re-filter once a minute so classes disappear when they end.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Pull-to-refresh / Retry on My Classes: re-subscribe.
  Future<void> _refreshClasses() async {
    setState(() =>
        _classes = context.read<BookingModel>().watchLiveClasses(mine: true));
  }

  Future<void> _scheduleClass(String trainerName) async {
    final details = await showDialog<_ClassDetails>(
      context: context,
      builder: (_) => const _LiveClassDialog(),
    );
    if (details == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<BookingModel>().startLiveClass(
            DateFormat('yyyy-MM-dd').format(details.date),
            details.time,
            trainerName,
            details.title,
            details.durationMinutes,
          );
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Class scheduled'),
          duration: Duration(seconds: 2),
        ),
      );
    } on BookingException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      debugPrint('Scheduling class failed: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not schedule the class.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingModel>();
    final trainer = context.watch<DatabaseModel>().getTrainer;

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        child: CustomScrollView(
          slivers: [
            MyAppbar("Hello, ${trainer.name}", "Home", false, trainer,
                showLogout: true),
            SliverFillRemaining(child: _appointmentsList(booking)),
          ],
        ),
      ),
      bottomSheet: CollapsibleSheet(
        title: "My Classes",
        child: _classesList(),
      ),
      // Scaffold centres the FAB on the bottom sheet's top edge; lift it
      // clear of the My Classes bar.
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: CollapsibleSheet.barHeight + 8),
        child: FloatingActionButton.extended(
          onPressed: () => _scheduleClass(trainer.name),
          label: const Text("Live Class"),
          icon: const Icon(Icons.live_tv),
        ),
      ),
    );
  }

  // ---------- Bookings made with this trainer ----------

  Widget _appointmentsList(BookingModel booking) {
    const bold20 = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
    return RefreshableList<Booking>(
      items: booking.getAppoinments,
      isLoading: booking.bookingsLoading,
      error: booking.bookingsError,
      onRefresh: booking.refreshBookings,
      emptyMessage: "No bookings yet",
      emptyIcon: Icons.event_available,
      padding: const EdgeInsets.only(bottom: 120),
      itemBuilder: (context, slot) => Card(
        key: ValueKey(slot.key),
        margin: const EdgeInsets.all(10),
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(slot.user, style: bold20),
              const SizedBox(height: 10),
              Text("Date: ${slot.date}\nTime: ${slot.time}",
                  textAlign: TextAlign.center, style: bold20),
              const Divider(),
              Text(slot.address, textAlign: TextAlign.center, style: bold20),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => confirmAndCancelBooking(context, slot),
                child: const Text("Cancel", style: bold20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- My upcoming live classes ----------

  Widget _classesList() {
    return StreamBuilder<List<LiveClass>>(
      stream: _classes,
      builder: (context, snapshot) => RefreshableList<LiveClass>(
        items: upcomingClasses(snapshot.data ?? const [], DateTime.now()),
        isLoading: !snapshot.hasData && !snapshot.hasError,
        error: snapshot.error,
        onRefresh: _refreshClasses,
        emptyMessage: "No upcoming live classes.\nTap Live Class to add one.",
        emptyIcon: Icons.live_tv,
        itemBuilder: (context, liveClass) => Card(
          key: ValueKey(liveClass.key),
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(Icons.alarm_on),
              title: Text(
                "${liveClass.date}  ${liveClass.time}",
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              subtitle: Text(
                "${liveClass.title} - ${liveClass.durationMinutes} min"
                " - ${liveClass.participants} watching",
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              trailing: ElevatedButton(
                onPressed: () =>
                    openLiveClass(context, liveClass, asHost: true),
                child: const Text("Start"),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- "Schedule a live class" dialog ----------

class _ClassDetails {
  final String title;
  final DateTime date;
  final TimeOfDay time;
  final int durationMinutes;
  const _ClassDetails(this.title, this.date, this.time, this.durationMinutes);
}

class _LiveClassDialog extends StatefulWidget {
  const _LiveClassDialog();

  @override
  State<_LiveClassDialog> createState() => _LiveClassDialogState();
}

class _LiveClassDialogState extends State<_LiveClassDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  int _duration = LiveClass.defaultDurationMinutes;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

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
    if (!_formKey.currentState!.validate()) return;
    if (_date == null || _time == null) {
      setState(() => _error = 'Pick a date and a time');
      return;
    }
    final start = DateTime(
        _date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
    if (!start.isAfter(DateTime.now())) {
      setState(() => _error = 'That time has already passed');
      return;
    }
    Navigator.of(context).pop(
      _ClassDetails(_titleController.text.trim(), _date!, _time!, _duration),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Class Title",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              TextFormField(
                controller: _titleController,
                decoration:
                    const InputDecoration(hintText: 'Enter the class title'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
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
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _duration,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final minutes in LiveClass.durationChoices)
                    DropdownMenuItem(
                        value: minutes, child: Text('$minutes minutes')),
                ],
                onChanged: (v) => setState(() => _duration = v ?? _duration),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1BC0C5),
                  foregroundColor: Colors.white,
                ),
                child: const Text("Post"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
