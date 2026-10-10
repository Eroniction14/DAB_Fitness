import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/models/booking.dart';
import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/widgets/booking_tile.dart';
import 'package:dab_fitness/widgets/grouped_bookings_list.dart';
import 'package:dab_fitness/widgets/page_header.dart';

/// Trainer: sessions clients have booked with me, in Today / Upcoming /
/// Past, with cancel.
class TrainerBookingsPage extends StatelessWidget {
  const TrainerBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingModel>();
    return Scaffold(
      body: Column(
        children: [
          const PageHeader(
              title: 'Bookings', subtitle: 'Sessions clients booked with you'),
          Expanded(
            child: GroupedBookingsList(
              bookings: booking.getAppoinments,
              isLoading: booking.bookingsLoading,
              error: booking.bookingsError,
              onRefresh: booking.refreshBookings,
              emptyTitle: 'No bookings yet',
              emptyHint: 'Sessions clients book with you will show up here.',
              tileBuilder: (context, item, muted) =>
                  trainerBookingTile(item, muted: muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// A trainer's booking: the client's name, when, where.
Widget trainerBookingTile(Booking booking, {bool muted = false}) =>
    BookingTile(booking,
        title: booking.user.isEmpty ? null : booking.user,
        detail: booking.user.isEmpty ? null : bookingWhen(booking),
        muted: muted);
