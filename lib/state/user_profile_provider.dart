import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import '../services/user_service.dart';

class UserProfileProvider extends ChangeNotifier {
  UserProfile? profile;
  bool isLoading = false;
  Object? error;
  String? lastUserId;

  Future<void> load({bool forceRefresh = false}) async {
    if (isLoading) return;
    if (!forceRefresh && profile != null) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      profile = await UserService.instance.getCurrentProfile(
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      error = e;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    profile = null;
    error = null;
    isLoading = false;
    notifyListeners();
  }
}
