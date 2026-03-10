import 'package:flutter/material.dart';

class AstraInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const AstraInput({
    super.key,
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Colors.white24),
        ),
      ),
    );
  }
}
