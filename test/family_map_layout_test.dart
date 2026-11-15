import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vrajrani_tech_solution/core/theme/app_theme.dart';
import 'package:vrajrani_tech_solution/data/models/parent_user.dart';
import 'package:vrajrani_tech_solution/features/family_map/widgets/family_glance_card.dart';
import 'package:vrajrani_tech_solution/features/family_map/widgets/nearby_banner_card.dart';
import 'package:vrajrani_tech_solution/features/family_map/widgets/quick_action_grid.dart';
import 'package:vrajrani_tech_solution/features/family_map/widgets/family_summary_strip.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'Family cards fit ${scale == 1 ? 390 : 320}px with text scale $scale and keep actions',
      (tester) async {
        tester.view.physicalSize = Size(scale == 1 ? 390 : 320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        var selected = 0;
        final boundary = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(scale == 1 ? 390 : 320, 700),
                textScaler: TextScaler.linear(scale),
              ),
              child: Scaffold(
                body: RepaintBoundary(
                  key: boundary,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        NearbyBannerCard(onTap: () => selected++),
                        const SizedBox(height: 12),
                        const FamilySummaryStrip(
                          onlineCount: 0,
                          totalCount: 0,
                          hasParentLocation: false,
                          synchronized: false,
                        ),
                        const SizedBox(height: 12),
                        QuickActionGrid(
                          account: ParentUser(
                            id: 1,
                            name: 'Parent',
                            email: '',
                            permissions: {'parent.device.add'},
                          ),
                          onAddChild: () => selected++,
                          onOpenChildren: () {},
                          onOpenPairing: () {},
                          onOpenSos: () {},
                        ),
                        const SizedBox(height: 12),
                        FamilyGlanceCard(onTap: () => selected++),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        if (const bool.fromEnvironment('CAPTURE_FAMILY_MAP')) {
          await tester.runAsync(() async {
            final font = FontLoader('Roboto')
              ..addFont(
                File(
                  '${Platform.environment['WINDIR']}/Fonts/arial.ttf',
                ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
              );
            await font.load();
            final icons = FontLoader('MaterialIcons')
              ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
            await icons.load();
            await precacheImage(
              const AssetImage('assets/illustrations/family_portrait.png'),
              boundary.currentContext!,
            );
          });
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Active'), findsNothing);
        expect(find.text('Synced'), findsNothing);
        await tester.ensureVisible(find.text('Find child'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Find child'));
        expect(selected, 1);
        if (scale == 1 && const bool.fromEnvironment('CAPTURE_FAMILY_MAP')) {
          await tester.runAsync(() async {
            final render =
                boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final capture = await render.toImage(pixelRatio: 2);
            final bytes = await capture.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory('verification/family_map').create(recursive: true);
            await File(
              'verification/family_map/cards-preview.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            capture.dispose();
          });
        }
      },
    );
  }
}
