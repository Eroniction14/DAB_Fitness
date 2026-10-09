import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/models/booking.dart';
import 'package:dab_fitness/models/trainer.dart';
import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/providers/database_model.dart';
import 'package:dab_fitness/screens/auth/logout.dart';
import 'package:dab_fitness/screens/profile/edit_profile_page.dart';
import 'package:dab_fitness/widgets/booking_tile.dart';
import 'package:dab_fitness/widgets/refreshable_list.dart';

/// The signed-in account's profile (user or trainer), with editing, their
/// appointments and logout. Reads the live profile, so edits show at once.
class ProfilePage extends StatelessWidget {
  static const routeName = '/profile';
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<DatabaseModel>().profile;
    if (profile == null) {
      // Signed out underneath us; nothing to show.
      return const Scaffold(body: SizedBox.shrink());
    }
    final details = <(IconData, String)>[
      (Icons.email_outlined, profile.email),
      if (profile.number.isNotEmpty) (Icons.phone_outlined, profile.number),
      if (profile.address.isNotEmpty)
        (Icons.location_on_outlined, profile.address),
      if (profile case Trainer(:final speciality) when speciality.isNotEmpty)
        (Icons.fitness_center, speciality),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        children: [
          Container(
            color: Colors.lightBlue,
            height: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_circle, size: 50),
                Text(profile.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                if (profile is Trainer) const Text('Trainer'),
              ],
            ),
          ),
          for (final (icon, text) in details)
            ListTile(leading: Icon(icon), title: Text(text), dense: true),
          const Divider(color: Colors.grey),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text("Edit profile"),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EditProfilePage(profile))),
          ),
          ListTile(
            leading: const Icon(Icons.event_note),
            title: const Text("My Appointments"),
            onTap: () => showDialog(
              context: context,
              builder: (context) => const Dialog(
                child: SizedBox(height: 360, child: _AppointmentsList()),
              ),
            ),
          ),
          const Divider(color: Colors.grey),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text("Logout of this app"),
            onTap: () => logOut(context),
          ),
        ],
      ),
    );
  }
}

class _AppointmentsList extends StatelessWidget {
  const _AppointmentsList();

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingModel>();
    return RefreshableList<Booking>(
      items: booking.getAppoinments,
      isLoading: booking.bookingsLoading,
      error: booking.bookingsError,
      onRefresh: booking.refreshBookings,
      emptyMessage: "No appointments scheduled",
      emptyIcon: Icons.event_available,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, item) =>
          BookingTile(item, key: ValueKey(item.key)),
    );
  }
}
