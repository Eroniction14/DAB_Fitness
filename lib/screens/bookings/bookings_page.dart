import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/models/booking.dart';
import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/providers/database_model.dart';
import 'package:dab_fitness/screens/shell/shell_scope.dart';
import 'package:dab_fitness/widgets/booking_tile.dart';
import 'package:dab_fitness/widgets/grouped_bookings_list.dart';
import 'package:dab_fitness/widgets/page_header.dart';

/// The user's booked sessions in Today / Upcoming / Past, with cancel and
/// pull-to-refresh.
class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingModel>();
    final shell = ShellScope.maybeOf(context);
    final trainingsTab = shell?.trainingsTab;
    return Scaffold(
      body: Column(
        children: [
          const PageHeader(
              title: 'Bookings', subtitle: 'Your in-person sessions'),
          Expanded(
            child: GroupedBookingsList(
              bookings: booking.getAppoinments,
              isLoading: booking.bookingsLoading,
              error: booking.bookingsError,
              onRefresh: booking.refreshBookings,
              emptyTitle: 'No sessions booked',
              emptyHint: 'Book an in-person session with a trainer.',
              emptyAction: shell == null || trainingsTab == null
                  ? null
                  : FilledButton(
                      onPressed: () => shell.selectTab(trainingsTab),
                      child: const Text('Find a trainer'),
                    ),
              tileBuilder: (context, item, muted) =>
                  userBookingTile(context, item, muted: muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// A user's booking: when, "With `trainer`", where.
Widget userBookingTile(BuildContext context, Booking booking,
    {bool muted = false}) {
  final trainer = context.watch<DatabaseModel>().trainerName(booking.trainerId);
  return BookingTile(booking,
      detail: trainer == null ? null : 'With $trainer', muted: muted);
}
