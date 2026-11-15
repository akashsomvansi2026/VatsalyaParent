import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:vrajrani_tech_solution/core/app_update/apk_updater.dart';
import 'package:vrajrani_tech_solution/core/app_update/app_update.dart';
import 'app_update_test.dart' show info, update;

class FakeApkUpdater extends ApkUpdater {
  Completer<void>? pending;
  bool allowed = false, cancelled = false, fail = false;
  int installs = 0;
  @override
  Future<void> download(Uri uri, void Function(int, int) progress) async {
    progress(50, 100);
    if (fail) throw StateError('Invalid APK');
    if (pending != null) await pending!.future;
  }

  @override
  Future<bool> install() async {
    installs++;
    return allowed;
  }

  @override
  void cancel() {
    cancelled = true;
    if (pending != null && !pending!.isCompleted) {
      pending!.completeError(StateError('cancelled'));
    }
  }
}

void main() {
  AppUpdateController create(FakeApkUpdater apk) => AppUpdateController(
    fetch: (_) async => update(
      mandatory: true,
      url: 'https://joinus.akashdreamer.uk/api/apk/download/release',
    ),
    packageInfo: () async => info(),
    launch: (_) async => throw StateError('Must use APK installer'),
    apkUpdater: apk,
  );

  test(
    'Permission return supports install retry and retains mandatory gate',
    () async {
      final apk = FakeApkUpdater();
      final c = create(apk);
      await c.check();
      await c.openUpdate();
      expect(c.downloadProgress, .5);
      expect(c.updateStatus, contains('Settings'));
      expect(c.blocked, true);
      apk.allowed = true;
      await c.openUpdate();
      expect(apk.installs, 2);
      expect(c.updateStatus, contains('Confirm'));
      expect(c.blocked, true);
      c.dispose();
    },
  );

  test(
    'Cancellation stops installation, preserves gate and allows retry',
    () async {
      final apk = FakeApkUpdater()..pending = Completer<void>();
      final c = create(apk);
      await c.check();
      final work = c.openUpdate();
      await Future<void>.delayed(Duration.zero);
      expect(c.launching, true);
      c.cancelDownload();
      await work;
      expect(apk.installs, 0);
      expect(c.error, contains('cancelled'));
      expect(c.blocked, true);
      apk.pending = null;
      await c.openUpdate();
      expect(apk.installs, 1);
      c.dispose();
    },
  );

  test('Invalid APK never opens installer and provides retry', () async {
    final apk = FakeApkUpdater()..fail = true;
    final c = create(apk);
    await c.check();
    await c.openUpdate();
    expect(apk.installs, 0);
    expect(c.error, contains('newer APK'));
    expect(c.launching, false);
    apk.fail = false;
    await c.openUpdate();
    expect(apk.installs, 1);
    c.dispose();
  });
}
