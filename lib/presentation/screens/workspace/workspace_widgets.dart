import 'package:flutter/material.dart';

String fieldLabel(String key) => key
    .replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m[0]!.toLowerCase()}')
    .replaceAll('_', ' ');

class EditorField {
  const EditorField(
    this.key,
    this.label, {
    this.required = false,
    this.secret = false,
    this.numeric = false,
    this.multiline = false,
    this.choices,
    this.validate,
  });
  final String key, label;
  final bool required, secret, numeric, multiline;
  final Map<String, String>? choices;
  final String? Function(String)? validate;
}

Future<Map<String, String>?> editValues(
  BuildContext context,
  String title,
  List<EditorField> fields, {
  Map<String, dynamic> initial = const {},
  String? notice,
  String submitLabel = 'Save Changes',
}) => showDialog<Map<String, String>>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _Editor(
    title: title,
    fields: fields,
    initial: initial,
    notice: notice,
    submitLabel: submitLabel,
  ),
);

class _Editor extends StatefulWidget {
  const _Editor({
    required this.title,
    required this.fields,
    required this.initial,
    this.notice,
    this.submitLabel = 'Save Changes',
  });
  final String title;
  final List<EditorField> fields;
  final Map<String, dynamic> initial;
  final String? notice;
  final String submitLabel;
  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  final key = GlobalKey<FormState>();
  late final Map<String, TextEditingController> controllers = {
    for (final field in widget.fields)
      field.key: TextEditingController(
        text: widget.initial[field.key]?.toString() ?? '',
      ),
  };
  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: Color(0xFFDFE7EC)),
    ),
    titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
    contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
    actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
    title: Text(
      widget.title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    ),
    content: SizedBox(
      width: 460,
      child: SingleChildScrollView(
        child: Form(
          key: key,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.notice != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F3EF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x33176B61)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Color(0xFF176B61),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.notice!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF176B61),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              for (final field in widget.fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: field.choices != null
                      ? DropdownButtonFormField<String>(
                          initialValue:
                              field.choices!.containsKey(
                                controllers[field.key]!.text,
                              )
                              ? controllers[field.key]!.text
                              : null,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: field.required
                                ? '${field.label} *'
                                : field.label,
                          ),
                          items: field.choices!.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(
                                    e.value,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              controllers[field.key]!.text = v ?? '',
                          validator: (v) => field.required && (v ?? '').isEmpty
                              ? 'Select ${field.label}'
                              : null,
                        )
                      : TextFormField(
                          controller: controllers[field.key],
                          obscureText: field.secret,
                          textInputAction: field.multiline
                              ? TextInputAction.newline
                              : TextInputAction.next,
                          maxLines: field.multiline ? 4 : 1,
                          maxLength: field.multiline ? 4000 : 320,
                          keyboardType: field.numeric
                              ? const TextInputType.numberWithOptions(
                                  decimal: true,
                                  signed: true,
                                )
                              : field.multiline
                              ? TextInputType.multiline
                              : TextInputType.text,
                          decoration: InputDecoration(
                            labelText: field.required
                                ? '${field.label} *'
                                : field.label,
                          ),
                          validator: (v) {
                            final value = field.secret
                                ? (v ?? '')
                                : (v ?? '').trim();
                            if (field.required && value.isEmpty) {
                              return '${field.label} is required';
                            }
                            return field.validate?.call(value);
                          },
                        ),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (key.currentState!.validate()) {
            Navigator.pop(context, {
              for (final entry in controllers.entries)
                entry.key:
                    widget.fields.firstWhere((f) => f.key == entry.key).secret
                    ? entry.value.text
                    : entry.value.text.trim(),
            });
          }
        },
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        child: Text(widget.submitLabel),
      ),
    ],
  );
}

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFDFE7EC)),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Color(0xFF172B3A),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ??
    false;

void workspaceMessage(BuildContext context, Object message) {
  if (context.mounted) {
    final compactFeedback =
        MediaQuery.sizeOf(context).height < 500 ||
        MediaQuery.textScalerOf(context).scale(13) > 20;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .3,
            ),
            child: SingleChildScrollView(
              child: Text(
                message.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          behavior: compactFeedback
              ? SnackBarBehavior.fixed
              : SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: compactFeedback ? null : const EdgeInsets.all(16),
        ),
      );
  }
}

String? passwordValidation(String value) =>
    value.length < 12 ||
        value.length > 128 ||
        !RegExp(r'[A-Za-z]').hasMatch(value) ||
        !RegExp(r'[0-9]').hasMatch(value)
    ? 'Use 12–128 characters, letters and numbers.'
    : null;
String? emailValidation(String value) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)
    ? null
    : 'Enter a valid email.';
String? dateValidation(String value) =>
    value.isEmpty ||
        DateTime.tryParse(value) != null &&
            RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)
    ? null
    : 'Use YYYY-MM-DD.';
String? numberValidation(String value, double min, double max) {
  final n = double.tryParse(value);
  return n != null && n >= min && n <= max
      ? null
      : 'Enter a number from $min to $max.';
}

class RecordDetails extends StatelessWidget {
  const RecordDetails(this.value, {super.key});
  final Map<String, dynamic> value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: value.entries
        .where((e) => e.value != null)
        .map(
          (entry) => Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: entry.value is Map
                ? Material(
                    color: Colors.transparent,
                    child: ExpansionTile(
                      title: Text(
                        fieldLabel(entry.key),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      tilePadding: EdgeInsets.zero,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: RecordDetails(
                            Map<String, dynamic>.from(entry.value as Map),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        fieldLabel(entry.key),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        '${entry.value is List ? (entry.value as List).join(', ') : entry.value}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
          ),
        )
        .toList(),
  );
}
