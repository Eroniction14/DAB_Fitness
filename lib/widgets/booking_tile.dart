import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/models/booking.dart';
import 'package:dab_fitness/providers/booking_model.dart';

/// Asks for confirmation, then cancels both copies of [booking].
/// Shows the outcome in a snackbar and returns whether it was cancelled.
Future<bool> confirmAndCancelBooking(
    BuildContext context, Booking booking) async {
  final model = context.read<BookingModel>();
  final messenger = ScaffoldMessenger.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cancel this session?'),
      content: Text('${booking.date} at ${booking.time}'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Keep it'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Cancel session'),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;

  try {
    await model.cancel(booking);
    messenger.showSnackBar(const SnackBar(
      content: Text('Session cancelled'),
      duration: Duration(seconds: 2),
    ));
    return true;
  } catch (e) {
    debugPrint('Cancelling booking failed: $e');
    messenger.showSnackBar(const SnackBar(
      content: Text('Could not cancel. Check your connection and try again.'),
    ));
    return false;
  }
}

/// A user's booking: date and time, with a cancel button.
class BookingTile extends StatelessWidget {
  final Booking booking;
  const BookingTile(this.booking, {super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ListTile(
          leading: const Icon(Icons.alarm_on),
          title: Text(booking.date, style: text.bodyMedium),
          subtitle: Text(booking.time, style: text.bodyMedium),
          trailing: IconButton(
            tooltip: 'Cancel session',
            icon: Icon(Icons.cancel_outlined,
                color: Theme.of(context).colorScheme.error),
            onPressed: () => confirmAndCancelBooking(context, booking),
          ),
        ),
      ),
    );
  }
}
