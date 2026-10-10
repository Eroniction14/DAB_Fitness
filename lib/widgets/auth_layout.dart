import 'package:flutter/material.dart';

import 'package:dab_fitness/config/theme.dart';

/// The app's logo mark (teal "D" with a dumbbell), from tool/make_icons.py.
class LogoMark extends StatelessWidget {
  final double size;
  const LogoMark({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/images/logo_mark.png',
        width: size,
        height: size,
        semanticLabel: 'DAB Fitness',
      );
}

/// Centred, card-less layout for Welcome / Login / Sign-up: logo mark,
/// title, subtitle, the form, and a quiet footer link.
class AuthLayout extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? footer;
  final List<Widget>? actions;

  /// Back button in the app bar (when there is a route to go back to).
  final bool showBack;

  const AuthLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.footer,
    this.actions,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: showBack, actions: actions),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm,
                AppSpacing.screen, AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: LogoMark()),
                  const SizedBox(height: AppSpacing.xl),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: context.textStyles.displaySmall),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(subtitle!,
                        textAlign: TextAlign.center,
                        style: context.textStyles.bodyLarge
                            ?.copyWith(color: context.appColors.textSecondary)),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  ...children,
                  if (footer != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Center(child: footer!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Space between form fields.
const formGap = SizedBox(height: AppSpacing.lg);

/// "Already have an account? Log in"-style footer.
class AuthFooterLink extends StatelessWidget {
  final String prompt;
  final String action;
  final VoidCallback onPressed;
  const AuthFooterLink(
      {super.key,
      required this.prompt,
      required this.action,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prompt,
            style: context.textStyles.bodyMedium
                ?.copyWith(color: context.appColors.textSecondary)),
        TextButton(onPressed: onPressed, child: Text(action)),
      ],
    );
  }
}

/// A password field with a show/hide toggle.
class PasswordField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const PasswordField({
    super.key,
    this.label = 'Password',
    this.controller,
    this.validator,
    this.onSaved,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      autofillHints: const [AutofillHints.password],
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Show password' : 'Hide password',
          icon: Icon(_obscure
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: widget.validator,
      onSaved: widget.onSaved,
    );
  }
}
