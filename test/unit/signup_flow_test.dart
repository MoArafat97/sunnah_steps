import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sunnah_steps/services/user_flags_service.dart';

void main() {
  group('Signup Flow Tests', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('Admin user can bypass signup requirements', () async {
      // Set admin flag
      await UserFlagsService.setAdminUser(true);
      
      // Check if user can bypass signup
      final canBypass = await UserFlagsService.canBypassSignup();
      
      expect(canBypass, isTrue);
    });

    test('Testing user can bypass signup requirements', () async {
      // Set testing flag
      await UserFlagsService.setTestingUser(true);
      
      // Check if user can bypass signup
      final canBypass = await UserFlagsService.canBypassSignup();
      
      expect(canBypass, isTrue);
    });

    test('Regular user cannot bypass signup requirements', () async {
      // Don't set any flags (regular user)
      
      // Check if user can bypass signup
      final canBypass = await UserFlagsService.canBypassSignup();
      
      expect(canBypass, isFalse);
    });

    test('Admin flag can be set and retrieved', () async {
      // Initially should be false
      expect(await UserFlagsService.isAdminUser(), isFalse);
      
      // Set admin flag
      await UserFlagsService.setAdminUser(true);
      expect(await UserFlagsService.isAdminUser(), isTrue);
      
      // Unset admin flag
      await UserFlagsService.setAdminUser(false);
      expect(await UserFlagsService.isAdminUser(), isFalse);
    });

    test('Testing flag can be set and retrieved', () async {
      // Initially should be false
      expect(await UserFlagsService.isTestingUser(), isFalse);
      
      // Set testing flag
      await UserFlagsService.setTestingUser(true);
      expect(await UserFlagsService.isTestingUser(), isTrue);
      
      // Unset testing flag
      await UserFlagsService.setTestingUser(false);
      expect(await UserFlagsService.isTestingUser(), isFalse);
    });

    test('Reset all flags clears admin and testing flags', () async {
      // Set both flags
      await UserFlagsService.setAdminUser(true);
      await UserFlagsService.setTestingUser(true);
      
      // Verify they are set
      expect(await UserFlagsService.isAdminUser(), isTrue);
      expect(await UserFlagsService.isTestingUser(), isTrue);
      
      // Reset all flags
      await UserFlagsService.resetAllFlags();
      
      // Verify they are cleared
      expect(await UserFlagsService.isAdminUser(), isFalse);
      expect(await UserFlagsService.isTestingUser(), isFalse);
    });
  });
}
