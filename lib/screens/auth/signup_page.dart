import 'package:flutter/material.dart';

import 'package:dab_fitness/config/theme.dart';
import 'package:dab_fitness/screens/auth/login_page.dart';
import 'package:dab_fitness/screens/auth/signup_detail_page.dart';
import 'package:dab_fitness/widgets/auth_layout.dart';

class SignUpPage extends StatefulWidget {
  static const routeName = '/signUp';
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final Map<String, String> _authData = {'email': '', 'password': ''};

  /// 0 = User, 1 = Trainer
  int _accountType = 0;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SignUpDetail(_accountType, _authData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Create your account',
      subtitle: "It's free and takes a minute.",
      footer: AuthFooterLink(
        prompt: 'Already have an account?',
        action: 'Log in',
        onPressed: () =>
            Navigator.of(context).pushReplacementNamed(LoginPage.routeName),
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
                  onSaved: (value) => _authData['email'] = value?.trim() ?? '',
                ),
                formGap,
                PasswordField(
                  controller: _passwordController,
                  validator: (value) => (value == null || value.length < 6)
                      ? 'Password must be at least 6 characters'
                      : null,
                  onSaved: (value) => _authData['password'] = value ?? '',
                ),
                formGap,
                PasswordField(
                  label: 'Confirm password',
                  textInputAction: TextInputAction.done,
                  validator: (value) => value != _passwordController.text
                      ? 'Passwords do not match!'
                      : null,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('I am a', style: context.textStyles.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                        value: 0,
                        label: Text('User'),
                        icon: Icon(Icons.person_outline)),
                    ButtonSegment(
                        value: 1,
                        label: Text('Trainer'),
                        icon: Icon(Icons.fitness_center)),
                  ],
                  selected: {_accountType},
                  onSelectionChanged: (selection) =>
                      setState(() => _accountType = selection.first),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(onPressed: _submit, child: const Text('Next')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
