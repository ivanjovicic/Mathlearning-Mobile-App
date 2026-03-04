import 'package:flutter/material.dart';

class LanguageDropdown extends StatelessWidget {
  final dynamic settings;

  const LanguageDropdown({super.key, this.settings});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.language),
        title: const Text('Jezik'),
        trailing: const Icon(Icons.arrow_drop_down),
        onTap: () {},
      ),
    );
  }
}

// Keep class `LanguageDropdown`; remove duplicate top-level factory helpers to avoid name collision.
