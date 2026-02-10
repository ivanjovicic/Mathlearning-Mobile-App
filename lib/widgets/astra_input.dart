import 'package:flutter/material.dart';
import '../theme/astrax_theme.dart';

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
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: AstraXTheme.panelLight,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AstraXTheme.radius),
          borderSide: const BorderSide(color: AstraXTheme.neonBlue, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AstraXTheme.radius),
          borderSide: const BorderSide(color: Colors.white24),
        ),
      ),
    );
  }
}
