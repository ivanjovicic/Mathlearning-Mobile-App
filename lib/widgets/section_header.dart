import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;

  const SectionHeader({super.key, required this.title, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}

Widget SectionHeaderFactory({required String title, IconData? icon}) => SectionHeader(title: title, icon: icon);
Widget SectionHeader({required String title, IconData? icon}) => SectionHeaderFactory(title: title, icon: icon);
