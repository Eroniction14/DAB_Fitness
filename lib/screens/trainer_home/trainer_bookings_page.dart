import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/models/booking.dart';
import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/widgets/booking_tile.dart';
import 'package:dab_fitness/widgets/refreshable_list.dart';

/// Trainer: sessions clients have booked with me, with cancel.
class TrainerBookingsPage extends StatelessWidget {
  const TrainerBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Bookings')),
      body: RefreshableList<Booking>(
        items: booking.getAppoinments,
        isLoading: booking.bookingsLoading,
        error: booking.bookingsError,
        onRefresh: booking.refreshBookings,
        emptyIcon: Icons.event_available_outlined,
        emptyTitle: 'No bookings yet',
        emptyHint: 'Sessions clients book with you will show up here.',
        itemBuilder: (context, item) => BookingTile(item,
            key: ValueKey(item.key),
            title: item.user.isEmpty ? null : item.user),
      ),
    );
  }
}
