import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/dialogs.dart';
import '../../../providers/child_detail_provider.dart';

/// Remote lock settings for a child device.
///
/// Two controls mirror the child-app locks:
///  - "Device screen lock"  -> Android keyguard password (4-16 chars). Requires
///    the child app to be provisioned as a Device Owner; the device locks now.
///  - "Launcher parent PIN" -> the PIN that unlocks the parent area inside the
///    child launcher (4-8 digits; overwritten remotely).
Future<void> showLockSettingsSheet(BuildContext context, int childId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LockSettingsSheet(childId: childId),
  );
}

class _LockSettingsSheet extends ConsumerStatefulWidget {
  const _LockSettingsSheet({required this.childId});

  final int childId;

  @override
  ConsumerState<_LockSettingsSheet> createState() => _LockSettingsSheetState();
}

class _LockSettingsSheetState extends ConsumerState<_LockSettingsSheet> {
  final _deviceLockController = TextEditingController();
  final _parentPinController = TextEditingController();
  bool _deviceSending = false;
  bool _parentSending = false;

  @override
  void dispose() {
    _deviceLockController.dispose();
    _parentPinController.dispose();
    super.dispose();
  }

  static const _parentPinRegex = r'^\d{4,8}$';

  Future<void> _setDeviceLock() async {
    final pin = _deviceLockController.text.trim();
    if (pin.isEmpty) {
      showAppMessage(
        context,
        'Enter a device lock PIN (4-16 characters).',
        isError: true,
      );
      return;
    }
    if (pin.length < 4 || pin.length > 16) {
      showAppMessage(
        context,
        'Device lock PIN must be 4-16 characters.',
        isError: true,
      );
      return;
    }
    setState(() => _deviceSending = true);
    try {
      await ref
          .read(childDetailProvider(widget.childId).notifier)
          .setDeviceLockPin(pin);
      if (mounted) {
        showAppMessage(
          context,
          'Device lock pin sent.\nThe child device will lock itself now.',
        );
      }
    } on AppException catch (error) {
      if (mounted) showAppMessage(context, error.message, isError: true);
    } catch (_) {
      if (mounted) {
        showAppMessage(
          context,
          'Could not update the device lock pin.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _deviceSending = false);
    }
  }

  Future<void> _setParentPin() async {
    final pin = _parentPinController.text.trim();
    if (pin.isEmpty) {
      showAppMessage(
        context,
        'Enter a launcher parent PIN (4-8 digits).',
        isError: true,
      );
      return;
    }
    if (!RegExp(_parentPinRegex).hasMatch(pin)) {
      showAppMessage(
        context,
        'Launcher parent PIN must be 4-8 digits.',
        isError: true,
      );
      return;
    }
    setState(() => _parentSending = true);
    try {
      await ref
          .read(childDetailProvider(widget.childId).notifier)
          .setParentAreaPin(pin);
      if (mounted) {
        showAppMessage(
          context,
          'Launcher parent PIN updated with the new value.',
        );
      }
    } on AppException catch (error) {
      if (mounted) showAppMessage(context, error.message, isError: true);
    } catch (_) {
      if (mounted) {
        showAppMessage(
          context,
          'Could not update the parent PIN.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _parentSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Remote lock',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Set the device screen-lock PIN and the launcher parent PIN from here.',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 16),

            _section('Device screen lock', Icons.screen_lock_portrait),
            const SizedBox(height: 8),
            _sectionNote(
              'This PIN replaces whatever the phone currently uses '
              '(none, PIN or pattern) with a new PIN/password. '
              'Requires the child app to be provisioned as a Device Owner '
              '(see Setup guide). If the phone is screen-locked right now, '
              'it takes effect on the next unlock; otherwise it locks now. '
              'Android patterns cannot be pushed remotely — only PIN/password.',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _deviceLockController,
              obscureText: true,
              maxLength: 16,
              decoration: const InputDecoration(
                labelText: 'New device lock PIN',
                hintText: '4-16 characters',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
                counterText: '',
              ),
              onSubmitted: (_) => _setDeviceLock(),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _deviceSending ? null : _setDeviceLock,
              icon: _deviceSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_reset, size: 18),
              label: const Text('Set & lock now'),
            ),
            const SizedBox(height: 20),

            _section('Launcher parent PIN', Icons.vpn_key),
            const SizedBox(height: 8),
            _sectionNote(
              'PIN that unlocks the parent-control area inside the child '
              'launcher. The new PIN overwrites the current one.',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _parentPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: 'New launcher parent PIN',
                hintText: '4-8 digits',
                prefixIcon: Icon(Icons.pin_outlined),
                border: OutlineInputBorder(),
                counterText: '',
              ),
              onSubmitted: (_) => _setParentPin(),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: _parentSending ? null : _setParentPin,
              icon: _parentSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check, size: 18),
              label: const Text('Set parent PIN'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _sectionNote(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: AppColors.muted),
    );
  }
}
