import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/state/daily_run_provider.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('daily chest state transitions locked -> ready -> opened', () async {
    final provider = DailyRunProvider();
    await provider.load('user-1');

    expect(provider.chestState, DailyChestState.locked);

    await provider.markCompleted();
    expect(provider.chestState, DailyChestState.ready);

    final reward = await provider.openChest();
    expect(reward, isNotNull);
    expect(provider.chestState, DailyChestState.opened);
  });

  test('opened chest persists for current day', () async {
    final provider = DailyRunProvider();
    await provider.load('user-1');
    await provider.markCompleted();
    await provider.openChest();

    final second = DailyRunProvider();
    await second.load('user-1');

    expect(second.chestState, DailyChestState.opened);
  });
}
