import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/models/booking.dart';
import 'package:dab_fitness/models/live_class.dart';
import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/providers/database_model.dart';
import 'package:dab_fitness/screens/live_class/call_page.dart';
import 'package:dab_fitness/widgets/app_bar_widget.dart';

class TrainerHomePage extends StatefulWidget {
  static const routeName = '/trainerHome';
  const TrainerHomePage({super.key});

  @override
  State<TrainerHomePage> createState() => _TrainerHomePageState();
}

class _TrainerHomePageState extends State<TrainerHomePage> {
  bool _isInit = true;
  bool _isLoading = false;
  bool _sheetOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) return;
    _isInit = false;
    _isLoading = true;
    _load();
  }

  Future<void> _load() async {
    final booking = context.read<BookingModel>();
    try {
      await Future.wait([
        booking.getMyAppoinments(),
        booking.loadLiveClassTrainer(),
      ]);
    } catch (e) {
      debugPrint('Failed to load trainer data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _scheduleClass(String trainerName) async {
    final details = await showDialog<_ClassDetails>(
      context: context,
      builder: (_) => const _LiveClassDialog(),
    );
    if (details == null || !mounted) return;

    await context.read<BookingModel>().startLiveClass(
          DateFormat('yyyy-MM-dd').format(details.date),
          details.time,
          trainerName,
          details.title,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Class scheduled'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _onJoin(String channelName) async {
    if (channelName.isEmpty) return;
    final statuses = await [Permission.camera, Permission.microphone].request();
    if (!mounted) return;
    if (statuses.values.any((s) => !s.isGranted)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera and microphone access are needed to join.'),
        ),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallPage(
          channelName: channelName,
          role: ClientRoleType.clientRoleBroadcaster,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingModel>();
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final trainer = context.read<DatabaseModel>().getTrainer;

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        child: CustomScrollView(
          slivers: [
            MyAppbar("Hello, ${trainer.name}", "Home", false, trainer),
            SliverFillRemaining(
              child: _appointmentsList(booking.getAppoinments),
            ),
          ],
        ),
      ),
      bottomSheet: _classesSheet(booking.getLiveClass),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _scheduleClass(trainer.name),
        label: const Text("Live Class"),
        icon: const Icon(Icons.live_tv),
      ),
    );
  }

  // ---------- Bookings made with this trainer ----------

  Widget _appointmentsList(List<Booking> appointments) {
    if (appointments.isEmpty) {
      return Center(
        child: Text("No bookings yet",
            style: Theme.of(context).textTheme.displaySmall),
      );
    }
    const bold20 = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: appointments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final slot = appointments[index];
        return Card(
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
                  onPressed: () {}, // TODO: cancel booking in Firebase
                  child: const Text("Cancel", style: bold20),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- "My Classes" collapsible sheet ----------

  Widget _classesSheet(List<LiveClass> liveClasses) {
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
                  Icon(
                      _sheetOpen ? Icons.arrow_drop_down : Icons.arrow_drop_up),
                  const Text("My Classes"),
                  Icon(
                      _sheetOpen ? Icons.arrow_drop_down : Icons.arrow_drop_up),
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
                    child: _classesList(liveClasses),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _classesList(List<LiveClass> liveClasses) {
    if (liveClasses.isEmpty) {
      return Center(
        child: Text("No live classes are scheduled",
            style: Theme.of(context).textTheme.displaySmall),
      );
    }
    return ListView.builder(
      itemCount: liveClasses.length,
      itemBuilder: (context, index) {
        final liveClass = liveClasses[index];
        return Card(
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
                liveClass.title,
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              trailing: ElevatedButton(
                onPressed: () => _onJoin(liveClass.channelName),
                child: const Text("Join"),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------- "Schedule a live class" dialog ----------

class _ClassDetails {
  final String title;
  final DateTime date;
  final TimeOfDay time;
  const _ClassDetails(this.title, this.date, this.time);
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
    Navigator.of(context).pop(
      _ClassDetails(_titleController.text.trim(), _date!, _time!),
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
