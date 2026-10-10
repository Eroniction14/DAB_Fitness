import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/providers/auth_model.dart';
import 'package:dab_fitness/providers/database_model.dart';
import 'package:dab_fitness/screens/auth/signup_detail_page.dart';
import 'package:dab_fitness/screens/onboarding/launch_page.dart';
import 'package:dab_fitness/screens/shell/trainer_shell.dart';
import 'package:dab_fitness/screens/shell/user_shell.dart';
import 'package:dab_fitness/widgets/auth_layout.dart';
import 'package:dab_fitness/widgets/empty_state.dart';

/// Shows the logo, then routes to the right home if a session was restored,
/// or to onboarding if not.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _minSplashTime = Duration(seconds: 1);
  static const _loadTimeout = Duration(seconds: 15);

  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final auth = context.read<AuthModel>();
    final database = context.read<DatabaseModel>();
    final navigator = Navigator.of(context);
    setState(() => _failed = false);

    try {
      final (uid, _) =
          await (auth.restoreSession(), Future.delayed(_minSplashTime)).wait;
      if (uid == null) {
        _toOnboarding(navigator);
        return;
      }

      final account = await database.loadData(uid).timeout(_loadTimeout);
      switch (account) {
        case AccountType.user:
          navigator.pushReplacementNamed(UserShell.routeName);
        case AccountType.trainer:
          navigator.pushReplacementNamed(TrainerShell.routeName);
        case AccountType.none:
          // Signed in, but sign-up never saved a profile: finish it.
          navigator.pushReplacement(
              MaterialPageRoute(builder: (_) => const SignUpDetail.complete()));
      }
    } catch (e) {
      debugPrint('Restoring session failed: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  void _toOnboarding(NavigatorState navigator) {
    navigator
        .pushReplacement(MaterialPageRoute(builder: (_) => const LaunchPage()));
  }

  @override
  Widget build(BuildContext context) {
    // Same mark on the same background as the native splash, so the
    // hand-over is seamless.
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Center(child: LogoMark(size: 120)),
            if (_failed)
              Align(
                alignment: Alignment.bottomCenter,
                child: EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: "Couldn't connect",
                  hint: 'Check your internet connection.',
                  isError: true,
                  action: FilledButton(
                    onPressed: _route,
                    child: const Text('Retry'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
