import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/quiz_provider.dart';
import '../services/connectivity_service.dart';

class OfflineStatusWidget extends StatefulWidget {
  const OfflineStatusWidget({Key? key}) : super(key: key);

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

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
        if (isOnline) {
          _loadPendingCount();
        }
      }
    });
  }

  Future<void> _loadPendingCount() async {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final count = await quizProvider.getPendingAnswersCount();
    if (mounted) {
      setState(() {
        _pendingAnswers = count;
      });
    }
  }

  Future<void> _syncNow() async {
    if (!_isOnline) return;

    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔄 Syncing offline data...')),
    );

    await quizProvider.syncOfflineData();
    await _loadPendingCount();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Sync completed!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline && _pendingAnswers == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isOnline ? Colors.orange : Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isOnline ? Icons.cloud_sync : Icons.cloud_off,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            _isOnline 
              ? 'Pending: $_pendingAnswers'
              : 'Offline Mode',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_isOnline && _pendingAnswers > 0) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _syncNow,
              child: const Icon(
                Icons.sync,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}