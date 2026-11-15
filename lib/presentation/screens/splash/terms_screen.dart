import 'package:vrajrani_tech_solution/branding/brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/terms_provider.dart';

class TermsScreen extends ConsumerStatefulWidget {
  const TermsScreen({super.key});
  @override
  ConsumerState<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends ConsumerState<TermsScreen> {
  bool agreed = false;
  bool saving = false;
  String? error;

  Future<void> accept() async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await ref.read(termsProvider.notifier).accept();
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Could not save your acceptance. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFF7EE),
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: const Text('Terms & Conditions'),
      backgroundColor: const Color(0xFFFFF7EE),
      foregroundColor: const Color(0xFF1A1208),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const BrandMark(size: 64),
          const SizedBox(height: 20),
          const Text(
            'Before you get started',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Please review these app usage conditions before continuing.',
          ),
          const SizedBox(height: 24),
          const Text(
            'Responsible family supervision',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use this app only to supervise children and devices you are authorized to manage. Explain location tracking and device controls to your child. Keep your account credentials private.',
          ),
          const SizedBox(height: 20),
          const Text(
            'Location and routing',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'The map shows the latest reported child locations, which may be delayed or inaccurate. When you use your location to calculate a route, your and the selected child’s coordinates are sent to the public OSRM routing service. Map tiles are provided by OpenStreetMap.',
          ),
          const SizedBox(height: 20),
          const Text(
            'Service availability',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tracking, alerts, and routes depend on network access, device permissions, battery, and server availability. Do not rely on this app as your only way to respond to an emergency.',
          ),
          const SizedBox(height: 20),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: const Color(0xFFF36F1F),
            value: agreed,
            onChanged: saving
                ? null
                : (value) => setState(() => agreed = value ?? false),
            title: const Text(
              'I have read and agree to these Terms & Conditions.',
            ),
          ),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF36F1F),
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: agreed && !saving ? accept : null,
            child: Text(saving ? 'Saving…' : 'Agree & Continue'),
          ),
        ],
      ),
    ),
  );
}
