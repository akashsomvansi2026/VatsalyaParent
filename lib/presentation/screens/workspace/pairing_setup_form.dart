import 'package:flutter/material.dart';
import 'workspace_widgets.dart';

class PairingSetupForm extends StatefulWidget {
  const PairingSetupForm({
    super.key,
    required this.children,
    this.initialChildId,
  });
  final List<Map<String, dynamic>> children;
  final int? initialChildId;
  @override
  State<PairingSetupForm> createState() => _PairingSetupFormState();
}

class _PairingSetupFormState extends State<PairingSetupForm> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  int? childId;
  int hours = 24;
  @override
  void initState() {
    super.initState();
    final child = widget.children
        .where((c) => c['id'] == widget.initialChildId)
        .firstOrNull;
    if (child != null) {
      childId = child['id'] as int;
      name.text = child['name']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Connect a child’s phone'),
    content: SizedBox(
      width: 460,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose a child, then scan the generated QR code from the Child app.',
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                initialValue: childId ?? 0,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Child profile',
                  prefixIcon: Icon(Icons.child_care),
                ),
                items: [
                  const DropdownMenuItem(
                    value: 0,
                    child: Text('Create during pairing'),
                  ),
                  for (final c in widget.children)
                    DropdownMenuItem(
                      value: c['id'] as int,
                      child: Text(
                        '${c['name']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (id) => setState(() {
                  childId = id == 0 ? null : id;
                  name.text =
                      widget.children
                          .where((c) => c['id'] == childId)
                          .firstOrNull?['name']
                          ?.toString() ??
                      '';
                }),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: name,
                readOnly: childId != null,
                decoration: const InputDecoration(labelText: 'Child name'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter the child’s name.'
                    : v.trim().length > 120
                    ? 'Use at most 120 characters.'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Child email',
                  helperText: 'Required for the child pairing profile.',
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter the child’s email.'
                    : emailValidation(v.trim()),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                initialValue: hours,
                decoration: const InputDecoration(labelText: 'Code expires in'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 hour')),
                  DropdownMenuItem(value: 24, child: Text('24 hours')),
                  DropdownMenuItem(value: 168, child: Text('7 days')),
                ],
                onChanged: (v) => hours = v ?? 24,
              ),
              const SizedBox(height: 16),
              const Text(
                'Creating a code is free. One enrollment token is used only when the child phone pairs successfully.',
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (form.currentState!.validate()) {
            Navigator.pop(context, <String, dynamic>{
              'childId': childId,
              'childName': name.text.trim(),
              'childEmail': email.text.trim().toLowerCase(),
              'validForHours': hours,
            });
          }
        },
        child: const Text('Generate code'),
      ),
    ],
  );
}
