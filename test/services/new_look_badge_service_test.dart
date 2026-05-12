import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mathlearning/services/new_look_badge_service.dart';

void main() {
  group('NewLookBadgeService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('isActive returns false when never set', () async {
      expect(await NewLookBadgeService.instance.isActive(), isFalse);
    });

    test('isActive returns true after markEquipped', () async {
      await NewLookBadgeService.instance.markEquipped();
      expect(await NewLookBadgeService.instance.isActive(), isTrue);
    });

    test('isActive returns false after clear', () async {
      await NewLookBadgeService.instance.markEquipped();
      await NewLookBadgeService.instance.clear();
      expect(await NewLookBadgeService.instance.isActive(), isFalse);
    });

    test('isActive returns false when timestamp is older than 24 hours', () async {
      final past = DateTime.now()
          .subtract(const Duration(hours: 25))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({'new_look_badge_set_at': past});
      expect(await NewLookBadgeService.instance.isActive(), isFalse);
    });

    test('isActive returns true when timestamp is within 24 hours', () async {
      final recent = DateTime.now()
          .subtract(const Duration(hours: 23))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({'new_look_badge_set_at': recent});
      expect(await NewLookBadgeService.instance.isActive(), isTrue);
    });
  });
}
