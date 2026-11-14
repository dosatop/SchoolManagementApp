import 'package:app/core/network/dio_provider.dart';
import 'package:app/core/notifications/push_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class SchoolManagementApp extends ConsumerWidget {
  const SchoolManagementApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Keeps the phone's push token in sync with login / logout,
    // and lets a tapped notification open the announcement.
    ref.watch(pushNotificationsProvider);
    PushNotifications.attachRouter(router);

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: pushMessengerKey,
      theme: ThemeData(fontFamily: GoogleFonts.exo2().fontFamily),
    );
  }
}
