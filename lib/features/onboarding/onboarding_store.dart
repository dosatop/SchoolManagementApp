import 'package:app/core/storage/storage_service.dart';

// ==================================================================
// ONBOARDING STORE
// ==================================================================
// In-memory copy of StorageService's "onboarding seen" flag, so the
// router can check it synchronously.
//
// Call `await OnboardingStore.load()` in main() BEFORE runApp.

class OnboardingStore {
  OnboardingStore._();

  static final StorageService _storage = StorageService();

  static bool _seen = false;

  /// True once the user has finished onboarding on this device.
  static bool get seen => _seen;

  static Future<void> load() async {
    try {
      _seen = await _storage.hasSeenOnboarding();
    } catch (_) {
      _seen = false;
    }
  }

  static Future<void> markSeen() async {
    _seen = true;
    try {
      await _storage.setOnboardingSeen();
    } catch (_) {
      // Worst case the slides show once more next launch.
    }
  }
}
