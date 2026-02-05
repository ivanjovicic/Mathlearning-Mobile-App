import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/user_service.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService.instance;

  List<UserSearchResult> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await _userService.searchUsers(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Pretraga trenutno nije uspela. Pokusaj ponovo.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pretraga korisnika'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pretrazi korisnike...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
              ),
              onChanged: (value) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _searchUsers(value);
                  }
                });
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  border: Border.all(color: colorScheme.error),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
            ),
          Expanded(
            child:
                _searchResults.isEmpty &&
                    !_isLoading &&
                    _searchController.text.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: colorScheme.onSurface,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nema rezultata',
                          style: TextStyle(
                            fontSize: 18,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return _UserTile(user: user);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserSearchResult user;

  const _UserTile({required this.user});

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
