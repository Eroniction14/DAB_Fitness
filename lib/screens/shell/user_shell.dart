import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/screens/bookings/bookings_page.dart';
import 'package:dab_fitness/screens/home/home_page.dart';
import 'package:dab_fitness/screens/profile/profile_page.dart';
import 'package:dab_fitness/screens/shell/shell_scope.dart';
import 'package:dab_fitness/screens/training/training_page.dart';

/// The signed-in user's app: Home, Trainings, Bookings and Profile tabs.
class UserShell extends StatefulWidget {
  static const routeName = '/home';
  static const homeTab = 0, trainingsTab = 1, bookingsTab = 2, profileTab = 3;

  final int initialTab;
  const UserShell({super.key, this.initialTab = homeTab});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  late int _tab = widget.initialTab;

  @override
  void initState() {
    super.initState();
    // Home's "Next session" and the Bookings tab share this load. After the
    // first frame, because loading notifies listeners straight away.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BookingModel>().loadMyAppoinments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ShellScope(
      currentTab: _tab,
      selectTab: (tab) => setState(() => _tab = tab),
      bookingsTab: UserShell.bookingsTab,
      profileTab: UserShell.profileTab,
      trainingsTab: UserShell.trainingsTab,
      child: Scaffold(
        body: IndexedStack(
          index: _tab,
          children: const [
            HomePage(),
            TrainingPage(),
            BookingsPage(),
            ProfilePage(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (tab) => setState(() => _tab = tab),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.fitness_center_outlined),
                selectedIcon: Icon(Icons.fitness_center),
                label: 'Trainings'),
            NavigationDestination(
                icon: Icon(Icons.event_note_outlined),
                selectedIcon: Icon(Icons.event_note),
                label: 'Bookings'),
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
