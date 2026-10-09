import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/screens/auth/logout.dart';
import 'package:dab_fitness/widgets/booking_tile.dart';

class ProfilePage extends StatelessWidget {
  /// The signed-in `UserProfile` or `Trainer`; both have a `name`.
  final dynamic user;
  const ProfilePage(this.user, {super.key});
  static const routeName = '/profile';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        elevation: 0,
      ),
      body: ListView(
        children: [
          Container(
            color: Colors.lightBlue,
            height: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_circle,
                  size: 50,
                ),
                Text(user.name),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.event_note),
            title: Text("My Appointments"),
            onTap: () => showDialog(
              context: context,
              builder: (context) => Dialog(
                child: SizedBox(
                  height: 300,
                  child: Consumer<BookingModel>(
                    builder: (context, booking, _) {
                      final appointments = booking.getAppoinments;
                      if (appointments.isEmpty) {
                        return Center(
                          child: Text("No appointments scheduled",
                              style: Theme.of(context).textTheme.bodyMedium),
                        );
                      }
                      return ListView.builder(
                        itemCount: appointments.length,
                        itemBuilder: (context, index) => BookingTile(
                          appointments[index],
                          key: ValueKey(appointments[index].key),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Divider(
            color: Colors.grey,
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text("Logout of this app"),
            onTap: () => logOut(context),
          ),
        ],
      ),
    );
  }
}
