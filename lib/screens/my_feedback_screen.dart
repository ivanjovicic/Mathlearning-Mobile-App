import 'package:flutter/material.dart';

import '../models/bug_report.dart';
import '../services/bug_report_service.dart';
import '../widgets/ui/app_section.dart';
import '../widgets/ui/state_scaffold.dart';

class MyFeedbackScreen extends StatefulWidget {
  const MyFeedbackScreen({super.key});

  @override
  State<MyFeedbackScreen> createState() => _MyFeedbackScreenState();
}

class _MyFeedbackScreenState extends State<MyFeedbackScreen> {
  bool _loading = true;
  String? _error;
  List<BugReport> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final feedback = await BugReportService.instance.fetchMyFeedback();
      if (!mounted) return;
      setState(() {
        _items = feedback;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final d = date.toLocal();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$day.$m.${d.year} $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('My Feedback')),
      body: StateScaffold(
        isLoading: _loading,
        isEmpty: !_loading && _error == null && _items.isEmpty,
        error: _error,
        onRetry: _load,
        emptyTitle: 'Nemas poslat UX/UI feedback',
        emptySubtitle: 'Posalji prvi feedback iz bug report dugmeta.',
        emptyIcon: Icons.rate_review_outlined,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: _items.length + 1,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return AppSection(
                  title: 'Poslati feedback',
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${_items.length} prijava',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }
              final item = _items[index - 1];
              final liked = item.liked ?? false;
              final rating = item.uxRating ?? 0;
              final status = item.status.toLowerCase();

              Color statusColor;
              switch (status) {
                case 'fixed':
                case 'closed':
                  statusColor = Colors.green;
                  break;
                case 'in_progress':
                case 'planned':
                  statusColor = Colors.orange;
                  break;
                default:
                  statusColor = colorScheme.primary;
              }

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          liked
                              ? Icons.thumb_up_alt_outlined
                              : Icons.thumb_down_alt_outlined,
                          size: 18,
                          color: liked ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Ocena: $rating/5',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.description,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if ((item.suggestion ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Predlog: ${item.suggestion}',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Ekran: ${item.screen}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    Text(
                      _formatDate(item.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
