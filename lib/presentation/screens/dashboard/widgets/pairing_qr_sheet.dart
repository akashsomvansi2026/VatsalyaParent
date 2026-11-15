import 'dart:ui' as ui;
import 'package:share_plus/share_plus.dart';
import '../../../../../core/utils/pairing_payload.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../../core/config/app_config.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/dialogs.dart';
import '../../../../../data/models/pairing_code.dart';

/// Shows the pairing code as a scannable QR. The child app scans it to
/// prefill the code + server URL and pair in one tap.
Future<void> showPairingQrSheet(
  BuildContext context,
  PairingCode code, {
  void Function()? onRevoke,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PairingQrSheet(code: code, onRevoke: onRevoke),
  );
}

class _PairingQrSheet extends StatelessWidget {
  const _PairingQrSheet({required this.code, this.onRevoke});

  final PairingCode code;
  final void Function()? onRevoke;

  String get _payload =>
      pairingPayload(code, code.apiUrl ?? AppConfig.apiBaseUrl);

  Future<void> _share(BuildContext context) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)
        ..drawRect(
          const Rect.fromLTWH(0, 0, 720, 720),
          Paint()..color = Colors.white,
        )
        ..translate(32, 32);
      QrPainter(
        data: _payload,
        version: QrVersions.auto,
      ).paint(canvas, const Size(656, 656));
      final picture = recorder.endRecording();
      final image = await picture.toImage(720, 720);
      picture.dispose();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (!context.mounted || bytes == null) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(bytes.buffer.asUint8List(), mimeType: 'image/png'),
          ],
          fileNameOverrides: ['child-pairing.png'],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (error) {
      if (context.mounted) showAppMessage(context, error.toString());
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
      child: Material(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      children: [
                        Icon(Icons.qr_code_2, color: AppColors.primary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Scan to pair a device',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Open the child app, tap "Scan QR" and point it at this code. '
                      'Review the child details and confirm pairing.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: _payload,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(0),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      code.code,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 6,
                        fontFamily: 'monospace',
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You can also type this code · expires '
                      '${Formatters.dateTime(code.expiresAtUtc)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.copy, color: AppColors.primary),
                  title: const Text(
                    'Copy pairing code',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code.code));
                    if (context.mounted) {
                      showAppMessage(context, 'Pairing code copied.');
                    }
                  },
                ),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const Icon(Icons.share),
                title: const Text('Share pairing QR'),
                subtitle: const Text(
                  'Share only with the person enrolling this child device.',
                ),
                onTap: () => _share(context),
              ),
              if (onRevoke != null)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  leading: const Icon(Icons.close, color: AppColors.sos),
                  title: const Text(
                    'Revoke code',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.sos,
                    ),
                  ),
                  onTap: () async {
                    final confirmed = await showConfirmDialog(
                      context,
                      title: 'Revoke code ${code.code}?',
                      message:
                          'The code will be deactivated and can no longer be used to pair a device.',
                      confirmLabel: 'Revoke',
                      danger: true,
                    );
                    if (confirmed && context.mounted) {
                      Navigator.of(context).pop();
                      onRevoke?.call();
                    }
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
