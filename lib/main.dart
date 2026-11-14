import 'package:app/app.dart';
import 'package:app/core/notifications/push_notifications.dart';
import 'package:app/features/onboarding/onboarding_store.dart';
import 'package:app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

  // ...your existing setup (storage, onboarding store, etc.)...
  // Read "has seen onboarding" so the router knows on the first frame.
  await OnboardingStore.load();

  runApp(const ProviderScope(child: SchoolManagementApp()));
}
