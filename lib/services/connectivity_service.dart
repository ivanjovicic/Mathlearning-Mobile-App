import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static ConnectivityService? _instance;
  static ConnectivityService get instance =>
      _instance ??= ConnectivityService._();

  ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// The most recent raw [ConnectivityResult] (e.g. wifi, mobile, none).
  ConnectivityResult _lastResult = ConnectivityResult.none;
  ConnectivityResult get lastResult => _lastResult;

  // Bool stream (true/false) – used by most consumers.
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _controller.stream;

  // Raw ConnectivityResult stream – for consumers that need connection type.
  final StreamController<ConnectivityResult> _resultController =
      StreamController<ConnectivityResult>.broadcast();
  Stream<ConnectivityResult> get statusStream => _resultController.stream;

  Future<void> initialize() async {
    // Emit initial status immediately so listeners can react on app start.
    await checkConnectivity();
    _controller.add(_isOnline);
    _resultController.add(_lastResult);

    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });
  }

  Future<void> checkConnectivity() async {
    try {
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _isOnline = false;
      _lastResult = ConnectivityResult.none;
      _controller.add(false);
      _resultController.add(ConnectivityResult.none);
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Consider online if any connection type is available (except none)
    _isOnline =
        results.any((result) => result != ConnectivityResult.none);

    // Pick the best result for the raw stream.
    _lastResult = _isOnline
        ? results.firstWhere((r) => r != ConnectivityResult.none,
            orElse: () => ConnectivityResult.none)
        : ConnectivityResult.none;

    debugPrint(
        'Connectivity changed: ${_isOnline ? "Online ($_lastResult)" : "Offline"}');
    _controller.add(_isOnline);
    _resultController.add(_lastResult);
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
    _resultController.close();
  }
}
