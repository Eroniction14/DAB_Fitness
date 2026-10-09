import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/config/theme.dart';
import 'package:dab_fitness/models/booking.dart';
import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/widgets/app_card.dart';

/// "Mon, 12 Oct" for a booking's yyyy-MM-dd date (or the raw value).
String friendlyDate(String date) {
  final parsed = DateTime.tryParse(date);
  return parsed == null ? date : DateFormat('EEE, d MMM').format(parsed);
}

/// Asks for confirmation, then cancels both copies of [booking].
/// Shows the outcome in a snackbar and returns whether it was cancelled.
Future<bool> confirmAndCancelBooking(
    BuildContext context, Booking booking) async {
  final model = context.read<BookingModel>();
  final messenger = ScaffoldMessenger.of(context);
  final scheme = context.colors;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cancel this session?'),
      content: Text('${friendlyDate(booking.date)} at ${booking.time}'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Keep it'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: scheme.error),
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

/// A booked session: date, time and place, with a cancel action.
/// [title] defaults to the date; trainers pass the client's name.
class BookingTile extends StatelessWidget {
  final Booking booking;
  final String? title;
  const BookingTile(this.booking, {super.key, this.title});

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    final secondary = context.appColors.textSecondary;
    final scheme = context.colors;

    return AppCard(
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: AppRadius.inputAll,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child:
                  Icon(Icons.event_outlined, color: scheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title ?? friendlyDate(booking.date),
                    style: text.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  [
                    if (title != null) friendlyDate(booking.date),
                    booking.time,
                    if (booking.address.isNotEmpty) booking.address,
                  ].join(' · '),
                  style: text.bodyMedium?.copyWith(color: secondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cancel session',
            icon: Icon(Icons.close_rounded, color: scheme.error),
            onPressed: () => confirmAndCancelBooking(context, booking),
          ),
        ],
      ),
    );
  }
}
