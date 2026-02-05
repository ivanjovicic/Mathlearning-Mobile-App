import 'package:flutter/material.dart';

import '../models/progress_overview.dart';
import '../services/api_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  ProgressOverview? _progress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  void _loadProgress() async {
    try {
      final apiService = ApiService();
      final progress = await apiService.getProgressOverview();
      setState(() {
        _progress = progress;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greska pri ucitavanju napretka: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Napredak'),
        backgroundColor: colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _progress == null
              ? const Center(
                  child: Text(
                    'Nema dostupnih podataka o napretku',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ukupan napredak',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatCard(
                                    'Ukupno kvizova',
                                    '${_progress!.totalQuizzes}',
                                    Icons.quiz,
                                    colorScheme.primary,
                                  ),
                                  _buildStatCard(
                                    'Zavrseno',
                                    '${_progress!.completedQuizzes}',
                                    Icons.check_circle,
                                    colorScheme.tertiary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rezultati',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatCard(
                                    'Prosecan rezultat',
                                    '${(_progress!.averageScore * 100).toStringAsFixed(1)}%',
                                    Icons.analytics,
                                    colorScheme.secondary,
                                  ),
                                  _buildStatCard(
                                    'Najbolji rezultat',
                                    '${(_progress!.bestScore * 100).toStringAsFixed(1)}%',
                                    Icons.star,
                                    colorScheme.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Stopa zavrsetka',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 16),
                              LinearProgressIndicator(
                                value: _progress!.totalQuizzes > 0
                                    ? _progress!.completedQuizzes / _progress!.totalQuizzes
                                    : 0,
                                minHeight: 8,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_progress!.completedQuizzes}/${_progress!.totalQuizzes} kvizova zavrseno',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
