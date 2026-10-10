import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/providers/auth_model.dart';
import 'package:dab_fitness/services/auth_service.dart';
import 'package:dab_fitness/widgets/booking_sheet.dart';
import 'package:dab_fitness/widgets/busy_button.dart';

/// Asks for an email and sends a Firebase password-reset link. Returns the
/// email it was sent to, or null if dismissed.
Future<String?> showForgotPasswordSheet(BuildContext context,
        {String initialEmail = ''}) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ForgotPasswordSheet(initialEmail: initialEmail),
    );

class _ForgotPasswordSheet extends StatefulWidget {
  final String initialEmail;
  const _ForgotPasswordSheet({required this.initialEmail});

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _email.text.trim();
    final navigator = Navigator.of(context);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await context.read<AuthModel>().sendPasswordReset(email);
      navigator.pop(email);
    } catch (e) {
      debugPrint('Password reset failed: $e');
      if (mounted) setState(() => _error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SheetBody(
        title: 'Reset your password',
        subtitle: "We'll email you a link to choose a new one.",
        error: _error,
        action: BusyFilledButton(
            label: 'Send reset link', busy: _sending, onPressed: _send),
        children: [
          TextFormField(
            controller: _email,
            autofocus: widget.initialEmail.isEmpty,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.send,
            onFieldSubmitted: (_) => _send(),
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty || !v.contains('@')) return 'Invalid email!';
              return null;
            },
          ),
        ],
      ),
    );
  }
}
