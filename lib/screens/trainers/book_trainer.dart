import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/models/booking.dart';
import 'package:dab_fitness/models/trainer.dart';
import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/providers/database_model.dart';
import 'package:dab_fitness/services/location_service.dart';
import 'package:dab_fitness/widgets/booking_sheet.dart';
import 'package:dab_fitness/widgets/app_snackbar.dart';

/// Asks for a date and time in the booking sheet, then books [trainer].
/// [onBusy] is told when the booking starts (true) and ends (false), so the
/// caller can show progress. Outcomes are shown as snackbars.
Future<void> bookTrainer(BuildContext context, Trainer trainer,
    {required ValueChanged<bool> onBusy}) async {
  final slot = await showBookingSheet(context, trainerName: trainer.name);
  if (slot == null || !context.mounted) return;

  final booking = context.read<BookingModel>();
  final userName = context.read<DatabaseModel>().user?.name ?? '';
  final messenger = ScaffoldMessenger.of(context);

  onBusy(true);
  try {
    final city = await getCity();
    final ok = await booking.book(
      DateFormat('yyyy-MM-dd').format(slot.date),
      slot.time,
      city,
      trainer.trainerId,
      userName,
    );
    if (ok) {
      messenger.showInfo('Session booked with ${trainer.name}!');
    } else {
      messenger.showError('Booking failed. Please try again.');
    }
  } on BookingException catch (e) {
    messenger.showError(e.message);
  } catch (e) {
    debugPrint('Booking failed: $e');
    messenger.showError('Could not connect. Check your internet connection.');
  } finally {
    onBusy(false);
  }
}
