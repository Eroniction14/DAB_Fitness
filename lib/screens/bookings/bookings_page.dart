import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/models/booking.dart';
import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/screens/shell/shell_scope.dart';
import 'package:dab_fitness/screens/shell/user_shell.dart';
import 'package:dab_fitness/widgets/booking_tile.dart';
import 'package:dab_fitness/widgets/refreshable_list.dart';

/// The user's booked sessions, with cancel and pull-to-refresh.
class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingModel>();
    final shell = ShellScope.maybeOf(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Bookings')),
      body: RefreshableList<Booking>(
        items: booking.getAppoinments,
        isLoading: booking.bookingsLoading,
        error: booking.bookingsError,
        onRefresh: booking.refreshBookings,
        emptyIcon: Icons.event_available_outlined,
        emptyTitle: 'No sessions booked',
        emptyHint: 'Book an in-person session with a trainer.',
        emptyAction: shell == null
            ? null
            : FilledButton(
                onPressed: () => shell.selectTab(UserShell.trainingsTab),
                child: const Text('Find a trainer'),
              ),
        itemBuilder: (context, item) =>
            BookingTile(item, key: ValueKey(item.key)),
      ),
    );
  }
}
