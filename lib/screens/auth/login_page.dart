import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/config/theme.dart';
import 'package:dab_fitness/providers/auth_model.dart';
import 'package:dab_fitness/providers/database_model.dart';
import 'package:dab_fitness/screens/auth/signup_detail_page.dart';
import 'package:dab_fitness/screens/auth/signup_page.dart';
import 'package:dab_fitness/screens/shell/trainer_shell.dart';
import 'package:dab_fitness/screens/shell/user_shell.dart';
import 'package:dab_fitness/services/auth_service.dart';
import 'package:dab_fitness/widgets/auth_layout.dart';
import 'package:dab_fitness/widgets/busy_button.dart';

class LoginPage extends StatefulWidget {
  static const routeName = '/login';
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLoading = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final auth = context.read<AuthModel>();
    final database = context.read<DatabaseModel>();
    final navigator = Navigator.of(context);

    try {
      final uid = await auth.signIn(_email, _password);
      final account = await database.loadData(uid);
      switch (account) {
        case AccountType.user:
          navigator.pushReplacementNamed(UserShell.routeName);
        case AccountType.trainer:
          navigator.pushReplacementNamed(TrainerShell.routeName);
        case AccountType.none:
          // Sign-up never saved a profile: finish it.
          navigator.pushReplacement(
              MaterialPageRoute(builder: (_) => const SignUpDetail.complete()));
      }
    } catch (e) {
      debugPrint('Login failed: $e');
      if (mounted) _showError(authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Welcome back',
      subtitle: 'Log in to keep training.',
      footer: AuthFooterLink(
        prompt: 'New here?',
        action: 'Create an account',
        onPressed: () =>
            Navigator.of(context).pushReplacementNamed(SignUpPage.routeName),
      ),
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty || !v.contains('@')) return 'Invalid email!';
                    return null;
                  },
                  onSaved: (value) => _email = value?.trim() ?? '',
                ),
                formGap,
                PasswordField(
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Enter your password'
                      : null,
                  onSaved: (value) => _password = value ?? '',
                ),
                const SizedBox(height: AppSpacing.xl),
                BusyFilledButton(
                    label: 'Log in', busy: _isLoading, onPressed: _submit),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
