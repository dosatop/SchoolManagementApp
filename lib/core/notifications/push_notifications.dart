import 'dart:async';
import 'dart:io' show Platform;

import 'package:app/features/announcements/provider/announcement_provider.dart';
import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ====================================================================
// PUSH NOTIFICATIONS (Firebase Cloud Messaging)
// ====================================================================
// What this does:
//   • asks for permission (iOS + Android 13+)
//   • registers this phone's FCM token with the API after login
//     (and again whenever Firebase rotates it)
//   • removes the token on logout, so a signed-out phone gets nothing
//   • app open      → shows an in-app banner with "View"
//   • app in back / closed → the system shows the notification; tapping
//     it opens the announcement
//
// Wiring (see main.dart snippet):
//   1. main(): Firebase.initializeApp + onBackgroundMessage
//   2. MaterialApp.router(scaffoldMessengerKey: pushMessengerKey, ...)
//   3. In your root widget: ref.watch(pushNotificationsProvider)
//      and PushNotifications.attachRouter(router)

/// Give this to MaterialApp.router so banners can show from anywhere.
final pushMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Runs in a separate isolate when a message arrives while the app is
/// in the background / closed. The system already shows the
/// notification; nothing else is needed. Must be top-level.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Watch this once in the root widget. It keeps the device token in
/// sync with login / logout.
final pushNotificationsProvider = Provider<PushNotifications>((ref) {
  final push = PushNotifications(ref);

  ref.listen<bool>(
    authProvider.select((s) => s.valueOrNull?.isAuthenticated ?? false),
    (wasSignedIn, isSignedIn) {
      if (isSignedIn && wasSignedIn != true) push.onSignedIn();
    },
    fireImmediately: true,
  );

  ref.onDispose(push.dispose);
  return push;
});

class PushNotifications {
  PushNotifications(this._ref);

  final Ref _ref;

  static GoRouter? _router;
  static bool _listenersReady = false;

  String? _token;
  StreamSubscription<String>? _tokenSub;

  /// Call once with your GoRouter so taps can open the announcement.
  static void attachRouter(GoRouter router) => _router = router;

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  // ------------------------------------------------------------------
  // SIGN IN → permission, token, listeners
  // ------------------------------------------------------------------

  Future<void> onSignedIn() async {
    if (kIsWeb) return;

    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('PUSH: permission denied by the user');
        return;
      }

      // iOS: show banners even while the app is open.
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: false, // we show our own in-app banner instead
        badge: true,
        sound: true,
      );

      // iOS needs the APNs token before an FCM token exists.
      if (Platform.isIOS) {
        var apns = await _fcm.getAPNSToken();
        for (var i = 0; apns == null && i < 5; i++) {
          await Future<void>.delayed(const Duration(seconds: 1));
          apns = await _fcm.getAPNSToken();
        }
        if (apns == null) {
          debugPrint('PUSH: no APNs token (simulator, or push capability missing)');
          return;
        }
      }

      final token = await _fcm.getToken();
      if (token != null) await _register(token);

      _tokenSub ??= _fcm.onTokenRefresh.listen(_register);

      _setUpMessageListeners();
    } catch (e) {
      debugPrint('PUSH: setup failed: $e');
    }
  }

  Future<void> _register(String token) async {
    _token = token;
    try {
      await _ref
          .read(announcementApiProvider)
          .registerDevice(token, Platform.isIOS ? 'ios' : 'android');
      debugPrint('PUSH: device registered');
    } catch (e) {
      debugPrint('PUSH: register failed: $e');
    }
  }

  // ------------------------------------------------------------------
  // SIGN OUT — call BEFORE the auth token is cleared
  // ------------------------------------------------------------------

  Future<void> onSigningOut() async {
    final token = _token ?? await _safeGetToken();
    if (token == null) return;

    try {
      await _ref.read(announcementApiProvider).unregisterDevice(token);
    } catch (_) {
      // Logout must never fail because of this.
    }
    _token = null;
  }

  Future<String?> _safeGetToken() async {
    try {
      return await _fcm.getToken();
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------------------
  // INCOMING MESSAGES
  // ------------------------------------------------------------------

  void _setUpMessageListeners() {
    if (_listenersReady) return;
    _listenersReady = true;

    // App open: refresh the badge + show a banner.
    FirebaseMessaging.onMessage.listen((message) {
      _ref.read(unreadAnnouncementsProvider.notifier).refresh();
      for (final f in AnnouncementFilter.values) {
        if (_ref.exists(announcementFeedProvider(f))) {
          _ref.invalidate(announcementFeedProvider(f));
        }
      }
      _showBanner(message);
    });

    // Tapped while the app was in the background.
    FirebaseMessaging.onMessageOpenedApp.listen(_open);

    // Tapped while the app was closed.
    _fcm.getInitialMessage().then((message) {
      if (message != null) {
        // Give the router a moment to finish the login redirect.
        Future<void>.delayed(const Duration(milliseconds: 600), () {
          _open(message);
        });
      }
    });
  }

  void _open(RemoteMessage message) {
    final id = message.data['announcementId'];
    final router = _router;
    if (router == null) return;

    if (message.data['type'] == 'announcement' && id is String && id.isNotEmpty) {
      router.push('/announcements/$id');
    } else {
      router.push('/announcements');
    }
  }

  void _showBanner(RemoteMessage message) {
    final messenger = pushMessengerKey.currentState;
    final title = message.notification?.title ?? 'New announcement';
    final body = message.notification?.body ?? '';
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          backgroundColor: const Color(0xFF091993),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              const Icon(Icons.campaign_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (body.isNotEmpty)
                      Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () => _open(message),
          ),
        ),
      );
  }

  void dispose() {
    _tokenSub?.cancel();
  }
}
