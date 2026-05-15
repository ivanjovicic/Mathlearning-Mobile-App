import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/models/cosmetic_item.dart';
import 'package:mathlearning/models/social_cosmetic_loadout.dart';
import 'package:mathlearning/screens/profile_screen.dart';
import 'package:mathlearning/state/avatar_provider.dart';
import 'package:mathlearning/state/auth_provider.dart';
import 'package:mathlearning/state/badge_provider.dart';
import 'package:mathlearning/state/cosmetic_target_provider.dart';
import 'package:mathlearning/state/progress_provider.dart';
import 'package:mathlearning/theme/theme_controller.dart';
import 'package:mathlearning/theme/theme_preferences_service.dart';

import '../helpers/test_fakes.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('profile shows current target chase compactly', (tester) async {
    final progress = ProgressProvider();
    final targetProvider = CosmeticTargetProvider();
    await targetProvider.load(userId: '1');
    await targetProvider.setTargetFromFlexItem(
      item: const SocialCosmeticFlexItem(
        itemId: 'frame_comet',
        name: 'Comet Frame',
        rarity: CosmeticRarity.rare,
        slotLabel: 'Frame',
        hasActualName: true,
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => ThemeController(ThemePreferencesService()),
          ),
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => TestAuthProvider(),
          ),
          ChangeNotifierProvider<ProgressProvider>.value(value: progress),
          ChangeNotifierProvider(create: (_) => BadgeProvider(progress)),
          ChangeNotifierProvider(create: (_) => AvatarProvider()),
          ChangeNotifierProvider<CosmeticTargetProvider>.value(
            value: targetProvider,
          ),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chasing Comet Frame 0/5'), findsOneWidget);
    expect(find.byKey(const Key('cosmetic_target_chip')), findsOneWidget);
  });
}
