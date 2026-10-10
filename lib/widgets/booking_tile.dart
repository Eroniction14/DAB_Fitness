import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/config/theme.dart';
import 'package:dab_fitness/models/booking.dart';
import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/widgets/app_card.dart';
import 'package:dab_fitness/widgets/app_snackbar.dart';

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
    messenger.showInfo('Session cancelled');
    return true;
  } catch (e) {
    debugPrint('Cancelling booking failed: $e');
    messenger
        .showError('Could not cancel. Check your connection and try again.');
    return false;
  }
}

/// "Mon, 12 Oct at 09:30" for a booking.
String bookingWhen(Booking booking) =>
    '${friendlyDate(booking.date)} at ${booking.time}';

/// A booked session with a cancel action:
///
///   [title]            (defaults to the date and time)
///   [detail]           e.g. "With Alex Carter", or the date for trainers
///   location           on its own line, cut off with an ellipsis
///
/// [muted] dims past sessions.
class BookingTile extends StatelessWidget {
  final Booking booking;
  final String? title;
  final String? detail;
  final bool muted;

  const BookingTile(this.booking,
      {super.key, this.title, this.detail, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    final secondary = context.appColors.textSecondary;
    final scheme = context.colors;

    // Past sessions ([muted]) tone down the icons only: dimming the text
    // with opacity would break contrast.
    return AppCard(
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color:
                  muted ? context.appColors.inputFill : scheme.primaryContainer,
              borderRadius: AppRadius.inputAll,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Icon(muted ? Icons.history : Icons.event_outlined,
                  color: muted ? secondary : scheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The title (client name, or the date for users) is the most
                // prominent line: heading size, above the 16pt detail line.
                Text(title ?? bookingWhen(booking),
                    style: text.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (detail != null) ...[
                  const SizedBox(height: AppSpacing.xs / 2),
                  Text(detail!,
                      style: text.bodyMedium?.copyWith(color: secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
                if (booking.address.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs / 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 16, color: secondary),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(booking.address,
                            style: text.bodySmall?.copyWith(color: secondary),
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: muted ? 'Remove session' : 'Cancel session',
            icon: Icon(Icons.close_rounded,
                color: muted ? secondary : scheme.error),
            onPressed: () => confirmAndCancelBooking(context, booking),
          ),
        ],
      ),
    );
  }
}
