import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'infra_providers.dart';

/// Device-level acknowledgement, retained when the account signs out.
class TermsNotifier extends Notifier<bool?> {
  @override
  bool? build() => null;

  Future<void> restore() async {
    try {
      final accepted = await ref.read(tokenStorageProvider).readTermsAccepted();
      if (ref.mounted) state = accepted;
    } catch (_) {
      if (ref.mounted) state = false;
    }
  }

  Future<void> accept() async {
    await ref.read(tokenStorageProvider).writeTermsAccepted();
    if (ref.mounted) state = true;
  }
}

final termsProvider = NotifierProvider<TermsNotifier, bool?>(TermsNotifier.new);
