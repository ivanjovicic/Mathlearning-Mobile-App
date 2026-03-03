import 'dart:async';
import 'auth_repository.dart';
import '../../models/api_result.dart';

class AuthController {
  final AuthRepository _authRepository;
  final StreamController<AuthState> _stateController = StreamController<AuthState>.broadcast();

  AuthController(this._authRepository);

  AuthState _state = AuthState.unauthenticated;

  AuthState get state => _state;
  Stream<AuthState> get stateStream => _stateController.stream;

  Future<ApiResult<bool>> login(String username, String password) async {
    _updateState(AuthState.authenticating);
    final result = await _authRepository.login(username, password);
    if (result is ApiSuccess) {
      _updateState(AuthState.authenticated);
    } else {
      _updateState(AuthState.failed);
    }
    return result;
  }

  Future<void> autoLogin() async {
    final refreshToken = await _authRepository.refreshToken();
    if (refreshToken is ApiSuccess) {
      _updateState(AuthState.authenticated);
    } else {
      _updateState(AuthState.unauthenticated);
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _updateState(AuthState.unauthenticated);
  }

  void _updateState(AuthState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  void dispose() {
    _stateController.close();
  }
}

enum AuthState {
  unauthenticated,
  authenticating,
  authenticated,
  refreshing,
  failed,
}