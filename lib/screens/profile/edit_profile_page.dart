import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/models/profile.dart';
import 'package:dab_fitness/models/trainer.dart';
import 'package:dab_fitness/providers/database_model.dart';

/// Edits the signed-in user's or trainer's profile. Email can't be changed
/// here (that needs a Firebase Auth verification flow).
class EditProfilePage extends StatefulWidget {
  final Profile profile;
  const EditProfilePage(this.profile, {super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, String> _original = widget.profile.editableFields;
  late final Map<String, String> _values = Map.of(_original);
  bool _isSaving = false;

  bool get _isTrainer => widget.profile is Trainer;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    FocusScope.of(context).unfocus();

    final changes = {
      for (final entry in _values.entries)
        if (entry.value != _original[entry.key]) entry.key: entry.value,
    };
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (changes.isEmpty) {
      navigator.pop();
      return;
    }

    setState(() => _isSaving = true);
    try {
      await context.read<DatabaseModel>().updateProfile(changes);
      messenger.showSnackBar(const SnackBar(
        content: Text('Profile saved'),
        duration: Duration(seconds: 2),
      ));
      navigator.pop();
    } catch (e) {
      debugPrint('Saving profile failed: $e');
      messenger.showSnackBar(const SnackBar(
        content: Text('Could not save. Check your connection and try again.'),
      ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _readOnly('Email', widget.profile.email),
              _field('Name', 'Name'),
              if (_isTrainer) ...[
                _field('Age', 'Age', keyboardType: TextInputType.number),
                _field('Speciality', 'Speciality'),
                _field('Description', 'Description', maxLines: 4),
              ],
              _field('Phone number', 'Number',
                  keyboardType: TextInputType.phone),
              _field('City', 'Address', required: false),
              _genderSelector(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _readOnly(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            helperText: "Email can't be changed",
          ),
          child: Text(value),
        ),
      );

  /// [key] is the database field name the value is saved under.
  Widget _field(String label, String key,
      {TextInputType? keyboardType, int maxLines = 1, bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        initialValue: _values[key],
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
            required && (value == null || value.trim().isEmpty)
                ? '$label is empty!'
                : null,
        onSaved: (value) => _values[key] = value?.trim() ?? '',
      ),
    );
  }

  Widget _genderSelector() {
    final selected =
        _values['Gender'] == 'female' ? 'female' : 'male'; // legacy default
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Gender'),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'male', label: Text('Male')),
              ButtonSegment(value: 'female', label: Text('Female')),
            ],
            selected: {selected},
            onSelectionChanged: (s) =>
                setState(() => _values['Gender'] = s.first),
          ),
        ),
      ],
    );
  }
}
