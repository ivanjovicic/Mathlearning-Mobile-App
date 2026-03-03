import 'package:flutter/material.dart';

class ThemeModeQuickSwitch extends StatelessWidget {
  final dynamic themeController;
  final VoidCallback? onThemePicked;

  const ThemeModeQuickSwitch({super.key, this.themeController, this.onThemePicked});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.brightness_6),
        title: const Text('Tema'),
        trailing: Switch(
          value: false,
          onChanged: (_) {
            if (onThemePicked != null) onThemePicked!();
          },
        ),
      ),
    );
  }
}

Widget ThemeModeQuickSwitchFactory({dynamic themeController, VoidCallback? onThemePicked}) => ThemeModeQuickSwitch(themeController: themeController, onThemePicked: onThemePicked);
Widget ThemeModeQuickSwitch({dynamic themeController, VoidCallback? onThemePicked}) => ThemeModeQuickSwitchFactory(themeController: themeController, onThemePicked: onThemePicked);
