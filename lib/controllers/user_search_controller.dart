import 'dart:async';

import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';

class UserSearchController extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();
  final UserService _userService = UserService.instance;
  Timer? _debounce;

  List<UserSearchResult> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<UserSearchResult> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  void onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchUsers(query);
    });
  }

  void clearSearch() {
    _debounce?.cancel();
    searchController.clear();
    _searchResults = [];
    _errorMessage = '';
    notifyListeners();
  }

  Future<void> retrySearch() async {
    _searchUsers(searchController.text);
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _errorMessage = '';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final results = await _userService.searchUsers(query);
      _searchResults = results;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Pretraga trenutno nije uspela. Pokusaj ponovo.';
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }
}