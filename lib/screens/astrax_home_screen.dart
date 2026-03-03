import 'package:flutter/material.dart';
import '../theme/astrax_theme.dart';
import '../widgets/astrax_app_bar.dart';
import '../widgets/astrax_bottom_nav.dart';
import '../widgets/astrax_card.dart';
import '../widgets/astrax_xp_bar.dart';
import '../widgets/astrax_buttons.dart';

class AstraHomeScreen extends StatefulWidget {
  const AstraHomeScreen({super.key});

  @override
  State<AstraHomeScreen> createState() => _AstraHomeScreenState();
}

class _AstraHomeScreenState extends State<AstraHomeScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: const AstraAppBar(title: 'MathLearning'),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AstraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good evening, Ivan',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Ready to continue your streak?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const AstraXPBar(
              progress: 0.65,
              label: 'Today XP',
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: AstraGlassButton(
                    text: 'Start Quiz',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AstraSoftButton(
                    text: 'Daily Review',
                    icon: Icons.school_rounded,
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Focus tracks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  AstraCard(
                    child: ListTile(
                      title: Text(
                        'Multiplication master',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Level 3 - 14/20 lessons',
                        style: TextStyle(color: Colors.white54),
                      ),
                      trailing: Icon(Icons.chevron_right, color: Colors.white54),
                    ),
                  ),
                  SizedBox(height: 12),
                  AstraCard(
                    child: ListTile(
                      title: Text(
                        'Fractions basics',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Level 1 - 5/10 lessons',
                        style: TextStyle(color: Colors.white54),
                      ),
                      trailing: Icon(Icons.chevron_right, color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AstraBottomNav(
        currentIndex: _tabIndex,
        onChanged: (i) => setState(() => _tabIndex = i),
      ),
    );
  }
}
