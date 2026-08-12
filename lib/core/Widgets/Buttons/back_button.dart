import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BackButtonFilled extends ConsumerWidget {
  const BackButtonFilled({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return IconButton.filled(
      onPressed: authState.isLoading ? null : () => Navigator.of(context).pop(),

      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF091993),
      ),
      icon: Icon(Icons.arrow_back),
    );
  }
}
