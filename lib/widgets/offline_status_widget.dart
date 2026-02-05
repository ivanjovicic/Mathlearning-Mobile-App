import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/connectivity_service.dart';
import '../state/quiz_provider.dart';

class OfflineStatusWidget extends StatefulWidget {
  const OfflineStatusWidget({super.key});

  @override
  State<OfflineStatusWidget> createState() => _OfflineStatusWidgetState();
}

class _OfflineStatusWidgetState extends State<OfflineStatusWidget> {
  late ConnectivityService _connectivity;
  bool _isOnline = true;
  int _pendingAnswers = 0;

  @override
  void initState() {
    super.initState();
    _connectivity = ConnectivityService.instance;
    _isOnline = _connectivity.isOnline;
    _loadPendingCount();

    _connectivity.onConnectivityChanged.listen((isOnline) {
      if (!mounted) return;
      setState(() {
        _isOnline = isOnline;
      });
      if (isOnline) {
        _loadPendingCount();
      }
    });
  }

  Future<void> _loadPendingCount() async {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final count = await quizProvider.getPendingAnswersCount();
    if (!mounted) return;
    setState(() {
      _pendingAnswers = count;
    });
  }

  Future<void> _syncNow() async {
    if (!_isOnline) return;

    final colorScheme = Theme.of(context).colorScheme;
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Sinhronizujem offline podatke...'),
        backgroundColor: colorScheme.primary,
      ),
    );

    await quizProvider.syncOfflineData();
    await _loadPendingCount();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Sinhronizacija zavrsena!'),
        backgroundColor: colorScheme.tertiary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline && _pendingAnswers == 0) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final statusBg = _isOnline ? colorScheme.secondary : colorScheme.error;
    final statusFg = _isOnline ? colorScheme.onSecondary : colorScheme.onError;

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isOnline ? Icons.cloud_sync : Icons.cloud_off,
            color: statusFg,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            _isOnline ? 'Na cekanju: $_pendingAnswers' : 'Offline rezim',
            style: TextStyle(
              color: statusFg,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_isOnline && _pendingAnswers > 0) ...[
            IconButton(
              onPressed: _syncNow,
              tooltip: 'Sinhronizuj',
              icon: Icon(Icons.sync, color: statusFg, size: 18),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }
}
