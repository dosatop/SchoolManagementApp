import 'package:app/app.dart';
import 'package:app/features/onboarding/onboarding_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  // Needed before using plugins (secure storage) ahead of runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Read "has seen onboarding" so the router knows on the first frame.
  await OnboardingStore.load();

  runApp(const ProviderScope(child: SchoolManagementApp()));
}