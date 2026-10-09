import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/providers/auth_model.dart';
import 'package:dab_fitness/screens/auth/login_page.dart';

/// Signs out and goes to the login page, clearing the navigation stack so
/// Back can't return to a signed-out home.
Future<void> logOut(BuildContext context) async {
  final navigator = Navigator.of(context);
  await context.read<AuthModel>().logout();
  navigator.pushNamedAndRemoveUntil(LoginPage.routeName, (_) => false);
}

/// Asks "Log out?" first, then [logOut].
Future<void> confirmLogOut(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Stay'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Log out'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) await logOut(context);
}
