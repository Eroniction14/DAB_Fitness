import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/providers/auth_model.dart';
import 'package:dab_fitness/providers/database_model.dart';
import 'package:dab_fitness/screens/auth/signup_page.dart';
import 'package:dab_fitness/screens/home/home_page.dart';
import 'package:dab_fitness/screens/trainer_home/trainer_home_page.dart';
import 'package:dab_fitness/widgets/fade_animation.dart';

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
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
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
      final response = await auth.signIn(_email, _password);
      if (response['error'] != null) {
        _showError(authErrorMessage(response));
        return;
      }

      final role = await database.loadData(auth.token, auth.userId);
      if (role == 1) {
        navigator.pushReplacementNamed(HomePage.routeName);
      } else if (role == 2) {
        navigator.pushReplacementNamed(TrainerHomePage.routeName);
      } else if (mounted) {
        _showError(
            'No profile found for this account. Please finish signing up.');
      }
    } catch (e) {
      debugPrint('Login failed: $e');
      if (mounted) {
        _showError('Could not connect. Check your internet connection.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Column(
              children: [
                const FadeAnimation(
                  1,
                  Text("Login",
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
                FadeAnimation(
                  1.2,
                  Text("Login to your account",
                      style:
                          TextStyle(fontSize: 15, color: Colors.grey.shade700)),
                ),
                const SizedBox(height: 60),
                FadeAnimation(
                  1.3,
                  _input(
                    label: "Email",
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty || !v.contains('@')) {
                        return 'Invalid email!';
                      }
                      return null;
                    },
                    onSaved: (value) => _email = value?.trim() ?? '',
                  ),
                ),
                FadeAnimation(
                  1.4,
                  _input(
                    label: "Password",
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Enter your password'
                        : null,
                    onSaved: (value) => _password = value ?? '',
                  ),
                ),
                const SizedBox(height: 10),
                FadeAnimation(1.5, _loginButton()),
                const SizedBox(height: 30),
                FadeAnimation(
                  1.6,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      InkWell(
                        onTap: () => Navigator.of(context)
                            .pushReplacementNamed(SignUpPage.routeName),
                        child: const Text(
                          "Sign up",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginButton() {
    return Container(
      padding: const EdgeInsets.only(top: 3, left: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.black),
      ),
      child: MaterialButton(
        minWidth: double.infinity,
        height: 60,
        onPressed: _isLoading ? null : _submit,
        color: Colors.greenAccent,
        disabledColor: Colors.greenAccent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const Text("Login",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
      ),
    );
  }

  Widget _input({
    required String label,
    required FormFieldValidator<String> validator,
    required FormFieldSetter<String> onSaved,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    final border =
        OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Colors.black87)),
        const SizedBox(height: 5),
        TextFormField(
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
            enabledBorder: border,
            border: border,
          ),
          validator: validator,
          onSaved: onSaved,
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
