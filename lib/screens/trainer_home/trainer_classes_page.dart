import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/config/theme.dart';
import 'package:dab_fitness/models/booking.dart';
import 'package:dab_fitness/models/live_class.dart';
import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/providers/database_model.dart';
import 'package:dab_fitness/screens/live_class/call_page.dart';
import 'package:dab_fitness/widgets/app_card.dart';
import 'package:dab_fitness/widgets/refreshable_list.dart';

/// Trainer: my upcoming live classes, updated live, with a FAB to schedule
/// a new one.
class TrainerClassesPage extends StatefulWidget {
  const TrainerClassesPage({super.key});

  @override
  State<TrainerClassesPage> createState() => _TrainerClassesPageState();
}

class _TrainerClassesPageState extends State<TrainerClassesPage> {
  late Stream<List<LiveClass>> _classes;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _classes = context.read<BookingModel>().watchLiveClasses(mine: true);
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

  /// Pull-to-refresh / Retry: re-subscribe.
  Future<void> _refresh() async {
    setState(() =>
        _classes = context.read<BookingModel>().watchLiveClasses(mine: true));
  }

  Future<void> _scheduleClass() async {
    final trainerName = context.read<DatabaseModel>().getTrainer.name;
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
      messenger.showSnackBar(const SnackBar(
        content: Text('Class scheduled'),
        duration: Duration(seconds: 2),
      ));
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
    return Scaffold(
      appBar: AppBar(title: const Text('Classes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scheduleClass,
        icon: const Icon(Icons.add),
        label: const Text('Schedule class'),
      ),
      body: StreamBuilder<List<LiveClass>>(
        stream: _classes,
        builder: (context, snapshot) => RefreshableList<LiveClass>(
          items: upcomingClasses(snapshot.data ?? const [], DateTime.now()),
          isLoading: !snapshot.hasData && !snapshot.hasError,
          error: snapshot.error,
          onRefresh: _refresh,
          emptyIcon: Icons.live_tv_outlined,
          emptyTitle: 'No upcoming classes',
          emptyHint: 'Schedule a live class for your clients.',
          // Leave room for the FAB under the last card.
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, 96),
          itemBuilder: (context, liveClass) =>
              _ClassTile(liveClass, key: ValueKey(liveClass.key)),
        ),
      ),
    );
  }
}

class _ClassTile extends StatelessWidget {
  final LiveClass liveClass;
  const _ClassTile(this.liveClass, {super.key});

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    final secondary = context.appColors.textSecondary;
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(liveClass.title,
                    style: text.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${liveClass.date} · ${liveClass.time} · '
                  '${liveClass.durationMinutes} min',
                  style: text.bodyMedium?.copyWith(color: secondary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('${liveClass.participants} watching',
                    style: text.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          FilledButton(
            onPressed: () => openLiveClass(context, liveClass, asHost: true),
            child: const Text('Start'),
          ),
        ],
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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Class title", style: context.textStyles.titleLarge),
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
                decoration: const InputDecoration(labelText: 'Duration'),
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
              FilledButton(
                onPressed: _submit,
                child: const Text("Schedule"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
