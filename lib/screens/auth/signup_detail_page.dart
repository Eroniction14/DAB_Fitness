import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/providers/auth_model.dart';
import 'package:dab_fitness/providers/database_model.dart';
import 'package:dab_fitness/screens/auth/logout.dart';
import 'package:dab_fitness/screens/home/home_page.dart';
import 'package:dab_fitness/screens/trainer_home/trainer_home_page.dart';
import 'package:dab_fitness/services/auth_service.dart';
import 'package:dab_fitness/services/location_service.dart';
import 'package:dab_fitness/widgets/fade_animation.dart';

class SignUpDetail extends StatefulWidget {
  /// 0 = User, 1 = Trainer; null lets the user choose ([SignUpDetail.complete]).
  final int? mode;

  /// `email` and `password` from the first sign-up step.
  final Map<String, String> authData;

  const SignUpDetail(int this.mode, this.authData, {super.key});

  /// "Finish your profile" for a signed-in account whose sign-up never saved
  /// a profile. No new account is created.
  const SignUpDetail.complete({super.key})
      : mode = null,
        authData = const {};

  bool get isCompleting => mode == null;

  @override
  State<SignUpDetail> createState() => _SignUpDetailState();
}

class _SignUpDetailState extends State<SignUpDetail> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, String> _data = Map.of(widget.authData);
  String _gender = 'male';
  bool _isLoading = false;
  late int _mode = widget.mode ?? 0;

  /// The account the profile is for, once it exists. Set after sign-up so
  /// a failed profile save can be retried without signing up again.
  String? _uid;

  bool get _isTrainer => _mode == 1;

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
      _data['Gender'] = _gender;
      _data['Address'] = await getCity();

      final String uid;
      if (widget.isCompleting) {
        final current = auth.userId;
        if (current == null) {
          if (mounted) _showError('Please log in again.');
          return;
        }
        uid = current;
        _data['email'] = auth.email ?? '';
      } else {
        uid = _uid ??= await auth.signUp(_data['email']!, _data['password']!);
      }

      final saved = _isTrainer
          ? await database.registerTrainerData(uid, _data)
          : await database.registerUserData(uid, _data);
      if (!saved) {
        if (mounted) {
          _showError("Couldn't save your profile. Check your connection and "
              "tap ${_submitLabel()} again.");
        }
        return;
      }

      final account = await database.loadData(uid);
      navigator.pushNamedAndRemoveUntil(
        account == AccountType.trainer
            ? TrainerHomePage.routeName
            : HomePage.routeName,
        (_) => false,
      );
    } catch (e) {
      debugPrint('Sign up failed: $e');
      if (mounted) _showError(authErrorMessage(e));
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
        // When completing there is nowhere to go back to; offer log out.
        automaticallyImplyLeading: false,
        leading: widget.isCompleting
            ? null
            : IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios,
                    size: 20, color: Colors.black),
              ),
        actions: [
          if (widget.isCompleting)
            TextButton(
              onPressed: () => logOut(context),
              child: const Text('Log out'),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            child: Column(
              children: [
                const FadeAnimation(
                  1,
                  Text("Sign up",
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                ),
                if (widget.isCompleting) ...[
                  const SizedBox(height: 12),
                  Text(
                    "Your account exists but its profile wasn't saved. "
                    "Finish it below.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text("User")),
                        ButtonSegment(value: 1, label: Text("Trainer")),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (s) =>
                          setState(() => _mode = s.first),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FadeAnimation(
                  1.2,
                  Text(
                    _isTrainer
                        ? "Tell us about yourself"
                        : "Enter your details",
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                  ),
                ),
                const SizedBox(height: 30),
                FadeAnimation(1.2, _input("Name")),
                if (_isTrainer) ...[
                  FadeAnimation(
                      1.3, _input("Age", keyboardType: TextInputType.number)),
                  FadeAnimation(1.4, _input("Description", maxLines: 3)),
                  FadeAnimation(1.5, _input("Speciality")),
                ],
                FadeAnimation(
                    1.5, _input("Number", keyboardType: TextInputType.phone)),
                FadeAnimation(1.6, _genderSelector()),
                const SizedBox(height: 40),
                FadeAnimation(1.6, _signUpButton()),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _genderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Gender",
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Colors.black87)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'male', label: Text("Male")),
              ButtonSegment(value: 'female', label: Text("Female")),
            ],
            selected: {_gender},
            onSelectionChanged: (s) => setState(() => _gender = s.first),
          ),
        ),
      ],
    );
  }

  String _submitLabel() => widget.isCompleting ? "Save profile" : "Sign up";

  Widget _signUpButton() {
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
            : Text(_submitLabel(),
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
      ),
    );
  }

  /// [label] is also the key the value is saved under (Name, Age, Number...),
  /// which is what registerUserData / registerTrainerData read.
  Widget _input(String label, {TextInputType? keyboardType, int maxLines = 1}) {
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
          keyboardType: keyboardType,
          maxLines: maxLines,
          textInputAction:
              maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            enabledBorder: border,
            border: border,
          ),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? '$label is empty!'
              : null,
          onSaved: (value) => _data[label] = value?.trim() ?? '',
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
