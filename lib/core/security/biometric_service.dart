import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

// ====================================================================
// BIOMETRIC LOGIN (fingerprint / Face ID)
// ====================================================================
// Turned on from Settings (BiometricLoginTile). When on, the email and
// password are kept in the phone's secure storage (Android Keystore /
// iOS Keychain) and only released after a successful fingerprint scan.
// Logging out keeps them, so the next login can use the fingerprint.

enum BiometricOutcome { success, cancelled, lockedOut, unavailable, failed }

class BiometricCredentials {
  const BiometricCredentials(this.email, this.password);
  final String email;
  final String password;
}

class BiometricStatus {
  const BiometricStatus({
    required this.available,
    required this.enabled,
    required this.label,
    this.email,
  });

  /// The phone has a fingerprint / face enrolled.
  final bool available;

  /// The user turned it on in Settings.
  final bool enabled;

  /// "Fingerprint" or "Face ID".
  final String label;

  /// Account that the fingerprint logs into.
  final String? email;

  bool get canUse => available && enabled && email != null;
}

class BiometricService {
  BiometricService({LocalAuthentication? auth, FlutterSecureStorage? storage})
    : _auth = auth ?? LocalAuthentication(),
      _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  final LocalAuthentication _auth;
  final FlutterSecureStorage _storage;

  static const _kEnabled = 'biometric_enabled';
  static const _kEmail = 'biometric_email';
  static const _kPassword = 'biometric_password';

  // ---------------------------------------------------------------- status

  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<String> label() async {
    try {
      final types = await _auth.getAvailableBiometrics();
      if (types.contains(BiometricType.face) &&
          !types.contains(BiometricType.fingerprint)) {
        return 'Face ID';
      }
    } catch (_) {}
    return 'Fingerprint';
  }

  Future<BiometricStatus> status() async {
    final available = await isAvailable();
    final enabled = await _read(_kEnabled) == 'true';
    final email = await _read(_kEmail);
    return BiometricStatus(
      available: available,
      enabled: enabled,
      label: await label(),
      email: (email == null || email.isEmpty) ? null : email,
    );
  }

  // ---------------------------------------------------------------- scan

  Future<BiometricOutcome> authenticate(String reason) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return ok ? BiometricOutcome.success : BiometricOutcome.cancelled;
    } on PlatformException catch (e) {
      switch (e.code) {
        case auth_error.lockedOut:
        case auth_error.permanentlyLockedOut:
          return BiometricOutcome.lockedOut;
        case auth_error.notAvailable:
        case auth_error.notEnrolled:
        case auth_error.passcodeNotSet:
          return BiometricOutcome.unavailable;
        default:
          return BiometricOutcome.failed;
      }
    } catch (_) {
      return BiometricOutcome.failed;
    }
  }

  // ---------------------------------------------------------------- data

  Future<void> enable(String email, String password) async {
    await _storage.write(key: _kEmail, value: email.trim());
    await _storage.write(key: _kPassword, value: password);
    await _storage.write(key: _kEnabled, value: 'true');
  }

  Future<void> disable() async {
    await _storage.delete(key: _kEnabled);
    await _storage.delete(key: _kEmail);
    await _storage.delete(key: _kPassword);
  }

  /// After a normal password login, keep the saved password current
  /// (only for the same account that turned fingerprint on).
  Future<void> refreshPassword(String email, String password) async {
    if (await _read(_kEnabled) != 'true') return;
    final saved = await _read(_kEmail);
    if (saved?.toLowerCase() != email.trim().toLowerCase()) return;
    await _storage.write(key: _kPassword, value: password);
  }

  Future<BiometricCredentials?> credentials() async {
    final email = await _read(_kEmail);
    final password = await _read(_kPassword);
    if (email == null || password == null) return null;
    return BiometricCredentials(email, password);
  }

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null; // corrupted keystore after OS restore, etc.
    }
  }
}

final biometricServiceProvider = Provider<BiometricService>(
  (_) => BiometricService(),
);

final biometricStatusProvider = FutureProvider.autoDispose<BiometricStatus>(
  (ref) => ref.read(biometricServiceProvider).status(),
);
