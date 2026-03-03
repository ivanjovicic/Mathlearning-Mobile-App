import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class UserTile extends StatelessWidget {
  final UserSearchResult user;

  const UserTile({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary,
          child: Text(
            user.displayName.isNotEmpty
                ? user.displayName[0].toUpperCase()
                : user.username[0].toUpperCase(),
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.displayName.isNotEmpty ? user.displayName : user.username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${user.username}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, size: 16, color: colorScheme.secondary),
                const SizedBox(width: 4),
                Text('Nivo ${user.level}'),
                const SizedBox(width: 16),
                Icon(Icons.trending_up, size: 16, color: colorScheme.tertiary),
                const SizedBox(width: 4),
                Text('${user.xp} XP'),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          final title = user.displayName.isNotEmpty
              ? user.displayName
              : user.username;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Izabran korisnik: $title'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}