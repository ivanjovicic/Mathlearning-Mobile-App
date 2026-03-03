import 'package:flutter/material.dart';

class SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final IconData? icon;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    this.icon,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      value: value,
      onChanged: enabled ? onChanged : (_) {},
      secondary: icon != null ? Icon(icon) : null,
    );
  }
}

Widget SettingsSwitchTileFactory({required String title, String? subtitle, required bool value, IconData? icon, bool enabled = true, required ValueChanged<bool> onChanged}) {
  return SettingsSwitchTile(title: title, subtitle: subtitle, value: value, icon: icon, enabled: enabled, onChanged: onChanged);
}
Widget SettingsSwitchTile({required String title, String? subtitle, required bool value, IconData? icon, bool enabled = true, required ValueChanged<bool> onChanged}) =>
    SettingsSwitchTileFactory(title: title, subtitle: subtitle, value: value, icon: icon, enabled: enabled, onChanged: onChanged);
