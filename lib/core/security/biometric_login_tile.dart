import 'package:app/core/security/biometric_service.dart';
import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ====================================================================
// SETTINGS: "Log in with fingerprint" switch
// ====================================================================
// Drop into any profile / settings page:
//     const BiometricLoginTile()
// Hidden on phones with no fingerprint / face enrolled.

class BiometricLoginTile extends ConsumerStatefulWidget {
  const BiometricLoginTile({super.key, this.color = const Color(0xFF091993)});

  final Color color;

  @override
  ConsumerState<BiometricLoginTile> createState() => _BiometricLoginTileState();
}

class _BiometricLoginTileState extends ConsumerState<BiometricLoginTile> {
  bool _busy = false;

  String? get _myEmail {
    final email = (ref.read(authProvider).value?.user?.email as String?)?.trim();
    return (email == null || email.isEmpty) ? null : email;
  }

  Future<void> _toggle(BiometricStatus status, bool turnOn) async {
    if (_busy) return;
    HapticFeedback.selectionClick();
    final service = ref.read(biometricServiceProvider);

    setState(() => _busy = true);
    try {
      if (!turnOn) {
        await service.disable();
        _snack('${status.label} login turned off');
        return;
      }

      final email = _myEmail;
      if (email == null) {
        _snack('Could not find your account email.', error: true);
        return;
      }

      // 1. Password, so the fingerprint can log in for you later.
      final password = await _askPassword(status.label);
      if (password == null || !mounted) return;

      // 2. Prove it's the phone owner.
      final outcome = await service.authenticate(
        'Confirm to turn on ${status.label.toLowerCase()} login',
      );
      if (outcome != BiometricOutcome.success) {
        if (outcome != BiometricOutcome.cancelled) {
          _snack('${status.label} check failed. Try again.', error: true);
        }
        return;
      }

      await service.enable(email, password);
      _snack('${status.label} login is on. Use it next time you log in.');
    } finally {
      ref.invalidate(biometricStatusProvider);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askPassword(String label) {
    final controller = TextEditingController();
    var hidden = true;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            'Turn on $label login',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your password once. It stays locked on this phone and '
                'is only used after your scan.',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                obscureText: hidden,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () => setLocal(() => hidden = !hidden),
                    icon: Icon(
                      hidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                onSubmitted: (v) {
                  if (v.isNotEmpty) Navigator.pop(dialogContext, v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: widget.color),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Navigator.pop(dialogContext, controller.text);
                }
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? Colors.red.shade700 : widget.color,
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(biometricStatusProvider).valueOrNull;
    if (status == null || !status.available) return const SizedBox.shrink();

    final myEmail = _myEmail?.toLowerCase();
    final on = status.enabled && status.email?.toLowerCase() == myEmail;
    final isFace = status.label == 'Face ID';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              isFace ? Icons.face_retouching_natural : Icons.fingerprint_rounded,
              color: widget.color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Log in with ${isFace ? 'Face ID' : 'fingerprint'}',
                  style: const TextStyle(
                    color: Color(0xFF20232E),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  on
                      ? 'On for this phone'
                      : status.enabled
                      ? 'Set up for another account on this phone'
                      : 'Skip typing your password',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
                ),
              ],
            ),
          ),
          _busy
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Switch.adaptive(
                  value: on,
                  activeTrackColor: widget.color,
                  onChanged: (v) => _toggle(status, v),
                ),
        ],
      ),
    );
  }
}
