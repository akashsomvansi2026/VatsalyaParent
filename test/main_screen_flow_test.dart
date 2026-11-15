import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vrajrani_tech_solution/core/theme/app_theme.dart';
import 'package:vrajrani_tech_solution/data/models/child.dart';
import 'package:vrajrani_tech_solution/data/models/parent_user.dart';
import 'package:vrajrani_tech_solution/data/remote/api_client.dart';
import 'package:vrajrani_tech_solution/data/repositories/parents_repository.dart';
import 'package:vrajrani_tech_solution/presentation/providers/infra_providers.dart';
import 'package:vrajrani_tech_solution/presentation/providers/session_provider.dart';
import 'package:vrajrani_tech_solution/presentation/screens/workspace/familymap/family_map_screen.dart';

class MapSession extends SessionNotifier {
  @override
  SessionState build() => SessionState.authenticated(
    ParentUser(
      id: 1,
      name: 'Parent',
      email: 'parent@example.test',
      permissions: {'child.view', 'location.view'},
    ),
  );
}

class MapChildren extends ParentsRepository {
  MapChildren()
    : super(
        apiClient: ApiClient(
          tokenProvider: () async => null,
          onUnauthorized: () {},
        ),
      );
  @override
  Future<List<Child>> getChildren() async => [
    Child.fromJson({
      'id': 1,
      'name': 'Riya',
      'isOnline': true,
      'latestLocation': {'latitude': 11.0168, 'longitude': 76.9558},
    }),
    Child.fromJson({'id': 2, 'name': 'Aarav', 'isOnline': false}),
  ];
}

void main() {
  testWidgets('main screen lets a parent search and select a child', (
    tester,
  ) async {
    const addressChannel = MethodChannel('vatsalya/location');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      addressChannel,
      (call) async => call.method == 'reverseGeocode'
          ? {'area': 'Hazratganj', 'city': 'Lucknow'}
          : true,
    );
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(MapSession.new),
          parentsRepositoryProvider.overrideWithValue(MapChildren()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const FamilyMapScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.scrollUntilVisible(find.byKey(const Key('choose-child')), 180);
    expect(find.text('Your family, at a glance'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('choose-child')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('choose-child')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(
      find.widgetWithText(TextField, 'Search children'),
      'Riy',
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Riya'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Aarav'),
      ),
      findsNothing,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Riya'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('View child details'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      addressChannel,
      null,
    );
  });
}
