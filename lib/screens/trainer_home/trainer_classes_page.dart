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
import 'package:dab_fitness/widgets/booking_sheet.dart';
import 'package:dab_fitness/widgets/live_class_card.dart';
import 'package:dab_fitness/widgets/page_header.dart';
import 'package:dab_fitness/widgets/picker_tile.dart';
import 'package:dab_fitness/widgets/refreshable_list.dart';
import 'package:dab_fitness/widgets/app_snackbar.dart';

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
    // Re-filter once a minute so classes go live / disappear on time.
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
    final details = await showModalBottomSheet<_ClassDetails>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _ScheduleClassSheet(),
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
      messenger.showInfo('Class scheduled');
    } on BookingException catch (e) {
      messenger.showError(e.message);
    } catch (e) {
      debugPrint('Scheduling class failed: $e');
      messenger.showError('Could not schedule the class.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scheduleClass,
        icon: const Icon(Icons.add),
        label: const Text('Schedule class'),
      ),
      body: Column(
        children: [
          const PageHeader(
              title: 'Classes', subtitle: 'Your upcoming live classes'),
          Expanded(
            child: StreamBuilder<List<LiveClass>>(
              stream: _classes,
              builder: (context, snapshot) => RefreshableList<LiveClass>(
                items:
                    upcomingClasses(snapshot.data ?? const [], DateTime.now()),
                isLoading: !snapshot.hasData && !snapshot.hasError,
                error: snapshot.error,
                onRefresh: _refresh,
                emptyIcon: Icons.live_tv_outlined,
                emptyTitle: 'No upcoming classes',
                emptyHint: 'Schedule a live class for your clients.',
                skeletonHeight: 220,
                // Leave room for the FAB under the last card.
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, 96),
                itemBuilder: (context, liveClass) => LiveClassCard(
                  key: ValueKey(liveClass.key),
                  liveClass: liveClass,
                  actionLabel: 'Start',
                  onJoin: () => openLiveClass(context, liveClass, asHost: true),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- "Schedule a live class" bottom sheet ----------

class _ClassDetails {
  final String title;
  final DateTime date;
  final TimeOfDay time;
  final int durationMinutes;
  const _ClassDetails(this.title, this.date, this.time, this.durationMinutes);
}

class _ScheduleClassSheet extends StatefulWidget {
  const _ScheduleClassSheet();

  @override
  State<_ScheduleClassSheet> createState() => _ScheduleClassSheetState();
}

class _ScheduleClassSheetState extends State<_ScheduleClassSheet> {
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

  static bool _notSunday(DateTime d) => d.weekday != DateTime.sunday;

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
    return Form(
      key: _formKey,
      child: SheetBody(
        title: 'Schedule a live class',
        error: _error,
        action: FilledButton(onPressed: _submit, child: const Text('Schedule')),
        children: [
          TextFormField(
            controller: _titleController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Class title'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          PickerTile(
            icon: Icons.event_outlined,
            label: 'Date',
            value: _date == null
                ? null
                : DateFormat('EEE, d MMM yyyy').format(_date!),
            placeholder: 'Choose a day (Mon–Sat)',
            onTap: _pickDate,
          ),
          const SizedBox(height: AppSpacing.md),
          PickerTile(
            icon: Icons.schedule,
            label: 'Start time',
            value: _time?.format(context),
            placeholder: 'Choose a time',
            onTap: _pickTime,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Duration', style: context.textStyles.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final minutes in LiveClass.durationChoices)
                ChoiceChip(
                  label: Text('$minutes min'),
                  selected: _duration == minutes,
                  onSelected: (_) => setState(() => _duration = minutes),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
