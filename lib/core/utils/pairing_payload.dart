import 'dart:convert';
import '../../data/models/pairing_code.dart';

String validatePairingServer(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null ||
      !['http', 'https'].contains(uri.scheme) ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      !['', '/'].contains(uri.path)) {
    throw const FormatException(
      'Use the HTTP/HTTPS server address without credentials, paths or query parameters.',
    );
  }
  if ([
    'localhost',
    '127.0.0.1',
    '::1',
    '0.0.0.0',
    '10.0.2.2',
  ].contains(uri.host)) {
    throw const FormatException(
      'Use a LAN or public address reachable by the child phone.',
    );
  }
  return uri.origin;
}

String pairingPayload(PairingCode code, String server) {
  if (!RegExp(r'^[A-Z2-9]{6}$').hasMatch(code.code)) {
    throw const FormatException('Invalid pairing code.');
  }
  return jsonEncode({
    'code': code.code,
    'apiUrl': validatePairingServer(server),
    if (code.isActive && code.accessToken != null) ...{
      'child': {'name': code.childName, 'email': code.childEmail},
      'parent': code.parent,
      'accessToken': code.accessToken,
    },
  });
}
