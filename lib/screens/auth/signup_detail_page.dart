import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/config/theme.dart';
import 'package:dab_fitness/providers/auth_model.dart';
import 'package:dab_fitness/providers/database_model.dart';
import 'package:dab_fitness/screens/auth/logout.dart';
import 'package:dab_fitness/screens/shell/trainer_shell.dart';
import 'package:dab_fitness/screens/shell/user_shell.dart';
import 'package:dab_fitness/services/auth_service.dart';
import 'package:dab_fitness/services/location_service.dart';
import 'package:dab_fitness/widgets/auth_layout.dart';
import 'package:dab_fitness/widgets/busy_button.dart';
import 'package:dab_fitness/widgets/speciality_field.dart';
import 'package:dab_fitness/widgets/app_snackbar.dart';

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
    ScaffoldMessenger.of(context).showError(message);
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
            ? TrainerShell.routeName
            : UserShell.routeName,
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
    return AuthLayout(
      // Completing: nowhere to go back to, so offer log out instead.
      showBack: !widget.isCompleting,
      actions: [
        if (widget.isCompleting)
          TextButton(
            onPressed: () => logOut(context),
            child: const Text('Log out'),
          ),
      ],
      title: widget.isCompleting ? 'Finish your profile' : 'About you',
      subtitle: widget.isCompleting
          ? "Your account exists but its profile wasn't saved. Finish it below."
          : _isTrainer
              ? 'Tell clients about yourself.'
              : 'A few details for your trainers.',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.isCompleting) ...[
                Text('I am a', style: context.textStyles.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('User')),
                    ButtonSegment(value: 1, label: Text('Trainer')),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => setState(() => _mode = s.first),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              _field('Name', 'Full name', autofill: AutofillHints.name),
              if (_isTrainer) ...[
                _field('Age', 'Age', keyboardType: TextInputType.number),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: SpecialityField(
                      onSaved: (v) => _data['Speciality'] = v ?? ''),
                ),
                _field('Description', 'About you', maxLines: 3),
              ],
              _field('Number', 'Phone number',
                  keyboardType: TextInputType.phone,
                  autofill: AutofillHints.telephoneNumber),
              Text('Gender', style: context.textStyles.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'male', label: Text('Male')),
                  ButtonSegment(value: 'female', label: Text('Female')),
                ],
                selected: {_gender},
                onSelectionChanged: (s) => setState(() => _gender = s.first),
              ),
              const SizedBox(height: AppSpacing.xl),
              BusyFilledButton(
                  label: _submitLabel(), busy: _isLoading, onPressed: _submit),
            ],
          ),
        ),
      ],
    );
  }

  String _submitLabel() => widget.isCompleting ? "Save profile" : "Sign up";

  /// [key] is the field name the value is saved under (Name, Age, Number...),
  /// which is what registerUserData / registerTrainerData read.
  Widget _field(String key, String label,
      {TextInputType? keyboardType, int maxLines = 1, String? autofill}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: TextFormField(
        keyboardType: keyboardType,
        maxLines: maxLines,
        autofillHints: autofill == null ? null : [autofill],
        textInputAction:
            maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
        decoration: InputDecoration(labelText: label),
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? '$label is empty!' : null,
        onSaved: (value) => _data[key] = value?.trim() ?? '',
      ),
    );
  }
}
