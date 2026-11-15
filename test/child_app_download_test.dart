import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vrajrani_tech_solution/data/remote/api_client.dart';
import 'package:vrajrani_tech_solution/presentation/providers/infra_providers.dart';
import 'package:vrajrani_tech_solution/presentation/screens/workspace/child_app_download_sheet.dart';

class DownloadApi extends ApiClient {
  DownloadApi(this.appName)
    : super(tokenProvider: () async => null, onUnauthorized: () {});
  String appName;
  int calls = 0;
  @override
  Future<Map<String, dynamic>> getPublicObject(
    String url, {
    required Map<String, dynamic> query,
  }) async {
    calls++;
    expect(url, '/api/apk/latest');
    expect(query, {'appName': 'child'});
    return {
      'appName': appName,
      'landingUrl': 'https://example.test/apk-download/7',
    };
  }
}

void main() {
  testWidgets(
    'Download QR uses Child package and cancellation does not advance',
    (tester) async {
      final api = DownloadApi('Vatsalya Child');
      bool? result;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiClientProvider.overrideWithValue(api)],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await showChildAppDownload(context);
                  },
                  child: const Text('Add'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(tester.widget<QrImageView>(find.byType(QrImageView)).size, 220);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, false);
      expect(api.calls, 1);
    },
  );
  testWidgets(
    'Wrong APK is rejected, retry recovers and installed users can continue',
    (tester) async {
      final api = DownloadApi('Parent');
      bool? result;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiClientProvider.overrideWithValue(api)],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await showChildAppDownload(context);
                  },
                  child: const Text('Add'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsNothing);
      api.appName = 'Vatsalya Child';
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsOneWidget);
      await tester.tap(find.text('Installed / Already installed — Continue'));
      await tester.pumpAndSettle();
      expect(result, true);
      expect(api.calls, 2);
    },
  );
}
