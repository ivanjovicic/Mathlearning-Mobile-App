import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static ConnectivityService? _instance;
  static ConnectivityService get instance => _instance ??= ConnectivityService._();
  
  ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _controller.stream;

  void initialize() {
    // Check initial connectivity
    checkConnectivity();
    
    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });
  }

  Future<void> checkConnectivity() async {
    try {
      final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _isOnline = false;
      _controller.add(false);
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    bool wasOnline = _isOnline;
    
    // Consider online if any connection type is available (except none)
    _isOnline = results.any((result) => result != ConnectivityResult.none);
    
    debugPrint('Connectivity changed: ${_isOnline ? "Online" : "Offline"}');
    
    // Only emit if status actually changed
    if (wasOnline != _isOnline) {
      _controller.add(_isOnline);
    }
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}