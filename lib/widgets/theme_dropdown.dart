import 'package:flutter/material.dart';

class ThemeDropdown extends StatelessWidget {
  final dynamic themeController;
  final VoidCallback? onThemePicked;

  const ThemeDropdown({super.key, this.themeController, this.onThemePicked});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.format_paint),
        title: const Text('Tema stil'),
        trailing: const Icon(Icons.arrow_drop_down),
        onTap: () {
          if (onThemePicked != null) onThemePicked!();
        },
      ),
    );
  }
}

Widget ThemeDropdownFactory({dynamic themeController, VoidCallback? onThemePicked}) => ThemeDropdown(themeController: themeController, onThemePicked: onThemePicked);
Widget ThemeDropdown({dynamic themeController, VoidCallback? onThemePicked}) => ThemeDropdownFactory(themeController: themeController, onThemePicked: onThemePicked);
