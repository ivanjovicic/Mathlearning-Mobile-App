import 'package:flutter/material.dart';

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({super.key, this.value = 'weekly', this.onChanged});

  final String value;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      items: const [
        DropdownMenuItem(value: 'weekly', child: Text('Nedeljno')),
        DropdownMenuItem(value: 'allTime', child: Text('Ukupno')),
      ],
      onChanged: onChanged,
    );
  }
}