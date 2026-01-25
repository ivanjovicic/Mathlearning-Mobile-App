import 'package:flutter/material.dart';
import 'package:mathlearning/screens/badge_screen.dart';
import 'package:mathlearning/screens/profile_screen.dart';
import 'package:mathlearning/state/badge_provider.dart';
import 'package:mathlearning/state/leaderboard_provider.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/reward_screen.dart';
import 'screens/heatmap_screen.dart';
import 'state/auth_provider.dart';
import 'state/quiz_provider.dart';
import 'state/progress_provider.dart';
import 'state/heatmap_provider.dart';
import 'state/coin_provider.dart';
import 'services/offline_manager.dart';
import 'services/auth_service.dart';
import 'widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  AuthService.instance.initialize();
  OfflineManager.instance.initialize();
  
  runApp(const MathLearningApp());
}

class MathLearningApp extends StatelessWidget {
  const MathLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => CoinProvider()),
        ChangeNotifierProxyProvider<ProgressProvider, BadgeProvider>(
          create: (context) => BadgeProvider(Provider.of<ProgressProvider>(context, listen: false)),
          update: (_, progress, __) => BadgeProvider(progress),
        ),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => HeatmapProvider()),
        ChangeNotifierProvider(create: (_) => LeaderboardProvider()),
      ],
      child: AuthCheckWidget(
        child: MaterialApp(
          title: 'Math Learning',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const AuthWrapper(),
          routes: {
            "/home": (_) => const HomeScreen(),
            "/quiz": (_) => const QuizScreen(),
            "/heatmap": (_) => const HeatmapScreen(),
            "/reward": (ctx) => const RewardScreen(),
            "/badges": (_) => const BadgesScreen(),
            "/profile": (_) => const ProfileScreen(),
            "/login": (_) => const LoginScreen(),
          },
        ),
      ),
    );
  }
}
