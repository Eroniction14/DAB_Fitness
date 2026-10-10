import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/config/theme.dart';
import 'package:dab_fitness/models/booking.dart';
import 'package:dab_fitness/models/trainer.dart';
import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/providers/database_model.dart';
import 'package:dab_fitness/screens/auth/logout.dart';
import 'package:dab_fitness/screens/profile/edit_profile_page.dart';
import 'package:dab_fitness/screens/shell/shell_scope.dart';
import 'package:dab_fitness/widgets/app_card.dart';
import 'package:dab_fitness/widgets/booking_tile.dart';
import 'package:dab_fitness/widgets/initials_avatar.dart';
import 'package:dab_fitness/widgets/page_header.dart';
import 'package:dab_fitness/widgets/refreshable_list.dart';

/// The signed-in account's profile (user or trainer): avatar, role, details,
/// and Edit profile / My appointments / Log out. Reads the live profile, so
/// edits show at once.
class ProfilePage extends StatelessWidget {
  static const routeName = '/profile';
  const ProfilePage({super.key});

  void _openAppointments(BuildContext context) {
    final shell = ShellScope.maybeOf(context);
    if (shell != null) {
      shell.selectTab(shell.bookingsTab);
      return;
    }
    // Shown on its own (via the route): list them in a sheet instead.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const SizedBox(height: 480, child: _AppointmentsList()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<DatabaseModel>().profile;
    if (profile == null) {
      // Signed out underneath us; nothing to show.
      return const Scaffold(body: SizedBox.shrink());
    }
    final text = context.textStyles;
    final scheme = context.colors;
    final isTrainer = profile is Trainer;
    final details = <(IconData, String)>[
      if (profile.number.isNotEmpty) (Icons.phone_outlined, profile.number),
      if (profile.address.isNotEmpty)
        (Icons.location_on_outlined, profile.address),
      if (profile case Trainer(:final speciality) when speciality.isNotEmpty)
        (Icons.fitness_center, speciality),
    ];

    return Scaffold(
      body: Column(
        children: [
          const PageHeader(title: 'Profile', showAvatar: false),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen,
                  AppSpacing.lg, AppSpacing.screen, AppSpacing.xl),
              children: [
                Center(
                  // Initials, not the trainer photo: new trainers get a
                  // stock placeholder image, which isn't them.
                  child: InitialsAvatar(name: profile.name, radius: 44),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(profile.name,
                    textAlign: TextAlign.center, style: text.titleLarge),
                Text(profile.email,
                    textAlign: TextAlign.center,
                    style: text.bodyMedium
                        ?.copyWith(color: context.appColors.textSecondary)),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                        color: scheme.primaryContainer,
                        shape: const StadiumBorder()),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      child: Text(isTrainer ? 'Trainer' : 'User',
                          style: text.labelLarge
                              ?.copyWith(color: scheme.onPrimaryContainer)),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (details.isNotEmpty) ...[
                  _Group(children: [
                    for (final (icon, value) in details)
                      ListTile(leading: Icon(icon), title: Text(value)),
                  ]),
                  const SizedBox(height: AppSpacing.lg),
                ],
                _Group(children: [
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Edit profile'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => EditProfilePage(profile))),
                  ),
                  ListTile(
                    leading: const Icon(Icons.event_note_outlined),
                    title: const Text('My appointments'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openAppointments(context),
                  ),
                ]),
                const SizedBox(height: AppSpacing.lg),
                _Group(children: [
                  ListTile(
                    leading: Icon(Icons.logout, color: scheme.error),
                    title: Text('Log out',
                        style: text.bodyLarge?.copyWith(color: scheme.error)),
                    onTap: () => logOut(context),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A card grouping list rows, with dividers between them.
class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      clip: true,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: AppSpacing.screen + 40),
            children[i],
          ],
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
      emptyTitle: 'No appointments scheduled',
      emptyIcon: Icons.event_available_outlined,
      itemBuilder: (context, item) =>
          BookingTile(item, key: ValueKey(item.key)),
    );
  }
}
