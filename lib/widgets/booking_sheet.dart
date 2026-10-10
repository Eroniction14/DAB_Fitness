import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dab_fitness/config/theme.dart';
import 'package:dab_fitness/widgets/picker_tile.dart';

/// A chosen date and time for an in-person session.
class BookingSlot {
  final DateTime date;
  final TimeOfDay time;
  const BookingSlot(this.date, this.time);
}

/// Asks for a date (no Sundays) and a time in the future, in a modal bottom
/// sheet. Returns null if dismissed.
Future<BookingSlot?> showBookingSheet(BuildContext context,
        {required String trainerName}) =>
    showModalBottomSheet<BookingSlot>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _BookingSheet(trainerName: trainerName),
    );

class _BookingSheet extends StatefulWidget {
  final String trainerName;
  const _BookingSheet({required this.trainerName});

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  DateTime? _date;
  TimeOfDay? _time;
  String? _error;

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
    Navigator.of(context).pop(BookingSlot(_date!, _time!));
  }

  @override
  Widget build(BuildContext context) {
    return SheetBody(
      title: 'Book a session',
      subtitle: 'with ${widget.trainerName}',
      error: _error,
      action: FilledButton(onPressed: _submit, child: const Text('Book')),
      children: [
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
          label: 'Time',
          value: _time?.format(context),
          placeholder: 'Choose a time',
          onTap: _pickTime,
        ),
      ],
    );
  }
}

/// Standard modal bottom sheet content: title, subtitle, fields, an error
/// line and a full-width primary action at the bottom.
class SheetBody extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final String? error;
  final Widget action;

  const SheetBody({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.error,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Rise above the keyboard when a text field is focused.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: context.textStyles.titleLarge),
            if (subtitle != null)
              Text(subtitle!,
                  style: context.textStyles.bodyMedium
                      ?.copyWith(color: context.appColors.textSecondary)),
            const SizedBox(height: AppSpacing.xl),
            ...children,
            if (error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(error!,
                  style: context.textStyles.bodyMedium
                      ?.copyWith(color: context.colors.error)),
            ],
            const SizedBox(height: AppSpacing.xl),
            action,
          ],
        ),
      ),
    );
  }
}
