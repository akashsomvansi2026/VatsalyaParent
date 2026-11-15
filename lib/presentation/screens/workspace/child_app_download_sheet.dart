import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/app_config.dart';
import '../../providers/infra_providers.dart';

Future<bool> showChildAppDownload(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => const _DownloadDialog(),
    ) ??
    false;

class _DownloadDialog extends ConsumerStatefulWidget {
  const _DownloadDialog();
  @override
  ConsumerState<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends ConsumerState<_DownloadDialog> {
  bool loading = true;
  String? error;
  Uri? url;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final apk = await ref
          .read(apiClientProvider)
          .getPublicObject('/api/apk/latest', query: {'appName': 'child'});
      if (!(apk['appName'] is String &&
          (apk['appName'] as String).toLowerCase().contains('child'))) {
        throw const FormatException('No Child app package is available.');
      }
      final raw = apk['landingUrl'] ?? apk['downloadUrl'];
      if (raw is! String || raw.trim().isEmpty) {
        throw const FormatException('Child app download link is unavailable.');
      }
      final link = Uri.parse(AppConfig.apiBaseUrl).resolve(raw);
      if (!['https', 'http'].contains(link.scheme) ||
          link.host.isEmpty ||
          link.userInfo.isNotEmpty) {
        throw const FormatException('Invalid Child app download link.');
      }
      if (mounted) setState(() => url = link);
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Child app download is unavailable. Retry, or continue if the app is already installed.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('1. Install Child app'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Scan this QR with the child phone’s camera, download and install the Child app. Then continue to enter child details.',
            ),
            const SizedBox(height: 16),
            if (loading) const CircularProgressIndicator(),
            if (error != null) ...[
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              TextButton(onPressed: load, child: const Text('Retry')),
            ],
            if (!loading && error == null && url != null) ...[
              QrImageView(
                data: url.toString(),
                size: 220,
                backgroundColor: Colors.white,
              ),
              TextButton(
                onPressed: () async {
                  try {
                    if (!await launchUrl(
                      url!,
                      mode: LaunchMode.externalApplication,
                    )) {
                      throw StateError('Could not open download');
                    }
                  } catch (_) {
                    if (mounted) {
                      setState(
                        () => error =
                            'Could not open the download. Scan the QR from the child phone or retry.',
                      );
                    }
                  }
                },
                child: const Text('Open download link'),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Installed / Already installed — Continue'),
      ),
    ],
  );
}
