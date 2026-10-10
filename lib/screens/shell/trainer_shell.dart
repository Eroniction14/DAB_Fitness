import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/screens/profile/profile_page.dart';
import 'package:dab_fitness/screens/shell/shell_scope.dart';
import 'package:dab_fitness/screens/trainer_home/trainer_bookings_page.dart';
import 'package:dab_fitness/screens/trainer_home/trainer_classes_page.dart';

/// The signed-in trainer's app: Bookings, Classes and Profile tabs.
class TrainerShell extends StatefulWidget {
  static const routeName = '/trainerHome';
  static const bookingsTab = 0, classesTab = 1, profileTab = 2;

  final int initialTab;
  const TrainerShell({super.key, this.initialTab = bookingsTab});

  @override
  State<TrainerShell> createState() => _TrainerShellState();
}

class _TrainerShellState extends State<TrainerShell> {
  late int _tab = widget.initialTab;

  @override
  void initState() {
    super.initState();
    // After the first frame, because loading notifies listeners straight away.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BookingModel>().getMyAppoinments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ShellScope(
      currentTab: _tab,
      selectTab: (tab) => setState(() => _tab = tab),
      bookingsTab: TrainerShell.bookingsTab,
      profileTab: TrainerShell.profileTab,
      child: Scaffold(
        body: IndexedStack(
          index: _tab,
          children: const [
            TrainerBookingsPage(),
            TrainerClassesPage(),
            ProfilePage(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (tab) => setState(() => _tab = tab),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.event_note_outlined),
                selectedIcon: Icon(Icons.event_note),
                label: 'Bookings'),
            NavigationDestination(
                icon: Icon(Icons.live_tv_outlined),
                selectedIcon: Icon(Icons.live_tv),
                label: 'Classes'),
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
