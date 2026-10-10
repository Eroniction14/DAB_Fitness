import 'package:flutter/material.dart';

import 'package:dab_fitness/screens/auth/login_page.dart';
import 'package:dab_fitness/screens/auth/signup_page.dart';
import 'package:dab_fitness/widgets/auth_layout.dart';

class WelcomePage extends StatelessWidget {
  static const routeName = '/welocomePage';

  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      showBack: false,
      title: 'DAB Fitness',
      subtitle: 'Train with real coaches, in person, on video or live.',
      footer: AuthFooterLink(
        prompt: 'Already a member?',
        action: 'Log in',
        onPressed: () => Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginPage())),
      ),
      children: [
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed(SignUpPage.routeName),
          child: const Text('Create account'),
        ),
      ],
    );
  }
}
