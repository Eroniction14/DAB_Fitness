import 'package:flutter/material.dart';

import 'package:dab_fitness/data/workout_data.dart';

/// A trainer's speciality, chosen from the Trainings categories so the
/// category filter matches reliably. An older free-text value that isn't in
/// the list stays selectable, so editing a profile never changes it silently.
class SpecialityField extends StatelessWidget {
  final String? initialValue;
  final FormFieldSetter<String> onSaved;

  const SpecialityField({super.key, this.initialValue, required this.onSaved});

  @override
  Widget build(BuildContext context) {
    final current = initialValue?.trim() ?? '';
    final choices = [
      ...specialityChoices,
      if (current.isNotEmpty && !specialityChoices.contains(current)) current,
    ];
    return DropdownButtonFormField<String>(
      initialValue: current.isEmpty ? null : current,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Speciality'),
      items: [
        for (final choice in choices)
          DropdownMenuItem(value: choice, child: Text(choice)),
      ],
      onChanged: (_) {},
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Choose a speciality' : null,
      onSaved: onSaved,
    );
  }
}
