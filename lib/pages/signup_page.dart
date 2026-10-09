import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../animation/FadeAnimation.dart';
import './login_page.dart';
import './signupdetail_page.dart';

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
                  Text("Sign up",
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
                FadeAnimation(
                  1.2,
                  Text("Create an account, it's free",
                      style:
                          TextStyle(fontSize: 15, color: Colors.grey.shade700)),
                ),
                const SizedBox(height: 40),
                FadeAnimation(
                  1.3,
                  _input(
                    label: "Email",
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty || !v.contains('@')) {
                        return 'Invalid email!';
                      }
                      return null;
                    },
                    onSaved: (value) =>
                        _authData['email'] = value?.trim() ?? '',
                  ),
                ),
                FadeAnimation(
                  1.3,
                  _input(
                    label: "Password",
                    obscureText: true,
                    controller: _passwordController,
                    validator: (value) => (value == null || value.length < 6)
                        ? 'Password must be at least 6 characters'
                        : null,
                    onSaved: (value) => _authData['password'] = value ?? '',
                  ),
                ),
                FadeAnimation(
                  1.3,
                  _input(
                    label: "Confirm Password",
                    obscureText: true,
                    validator: (value) => value != _passwordController.text
                        ? 'Passwords do not match!'
                        : null,
                  ),
                ),
                FadeAnimation(
                  1.5,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("I am a",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Colors.black87)),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(
                                value: 0,
                                label: Text("User"),
                                icon: Icon(Icons.person)),
                            ButtonSegment(
                                value: 1,
                                label: Text("Trainer"),
                                icon: Icon(Icons.fitness_center)),
                          ],
                          selected: {_accountType},
                          onSelectionChanged: (selection) =>
                              setState(() => _accountType = selection.first),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                FadeAnimation(
                  1.5,
                  Container(
                    padding: const EdgeInsets.only(top: 3, left: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.black),
                    ),
                    child: MaterialButton(
                      minWidth: double.infinity,
                      height: 60,
                      onPressed: _submit,
                      color: Colors.greenAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)),
                      child: const Text("Next",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 18)),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                FadeAnimation(
                  1.6,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      InkWell(
                        onTap: () => Navigator.of(context)
                            .pushReplacementNamed(LoginPage.routeName),
                        child: const Text(" Login",
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 18)),
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

  Widget _input({
    required String label,
    required FormFieldValidator<String> validator,
    FormFieldSetter<String>? onSaved,
    TextEditingController? controller,
    bool obscureText = false,
    TextInputType? keyboardType,
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
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.next,
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