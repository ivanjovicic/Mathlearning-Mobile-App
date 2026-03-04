import 'package:flutter/material.dart';

class QuestChecklist extends StatelessWidget {
  final dynamic settings;

  const QuestChecklist({super.key, this.settings});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.checklist),
        title: const Text('Zadaci'),
        subtitle: const Text('Pregled zadataka za postavljanje naloga'),
        onTap: () {},
      ),
    );
  }
}

