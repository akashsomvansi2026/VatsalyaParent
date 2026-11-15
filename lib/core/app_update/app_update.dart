import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/remote/api_client.dart';
import '../../presentation/providers/infra_providers.dart';
import 'apk_updater.dart';

bool validAppVersion(String value) => RegExp(
  r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$',
).hasMatch(value);

class AppUpdate {
  const AppUpdate({
    required this.available,
    required this.mandatory,
    required this.installed,
    required this.latest,
    this.downloadUrl,
    this.notes,
  });
  final bool available, mandatory;
  final String installed, latest;
  final String? downloadUrl, notes;
  factory AppUpdate.parse(Map<String, dynamic> json, String installed) {
    final data = json['data'];
    if (json['success'] != true ||
        json['statusCode'] != 200 ||
        data is! Map<String, dynamic> ||
        data['platform'] != 'android' ||
        data['updateAvailable'] is! bool ||
        data['mandatory'] is! bool ||
        data['latestVersion'] is! String ||
        !validAppVersion(data['latestVersion'] as String) ||
        data['minimumVersion'] is! String ||
        !validAppVersion(data['minimumVersion'] as String) ||
        (data['downloadUrl'] != null && data['downloadUrl'] is! String) ||
        (data['releaseNotes'] != null && data['releaseNotes'] is! String)) {
      throw const FormatException('Invalid update response');
    }
    return AppUpdate(
      available: data['updateAvailable'] as bool,
      mandatory: data['mandatory'] as bool,
      installed: installed,
      latest: data['latestVersion'] as String,
      downloadUrl: data['downloadUrl'] as String?,
      notes: data['releaseNotes'] as String?,
    );
  }
}

class AppUpdateService {
  AppUpdateService(this.client);
  final ApiClient client;
  Future<AppUpdate> check(String version) async {
    client.setInstalledAppVersion(version);
    return AppUpdate.parse(
      await client.getPublicObject(
        'https://joinus.akashdreamer.uk/api/app/update-check',
        query: {'platform': 'android', 'version': version},
      ),
      version,
    );
  }
}

/// Exact hosts only. Add an operator-controlled CDN via a reviewed build setting.
Uri? updateDestination(
  AppUpdate update,
  String packageName, {
  bool playPublished = const bool.fromEnvironment('APP_PUBLISHED_ON_PLAY'),
  String trustedHosts = const String.fromEnvironment(
    'APP_UPDATE_TRUSTED_HOSTS',
    defaultValue: 'joinus.akashdreamer.uk',
  ),
}) {
  final raw = update.downloadUrl?.trim();
  if (raw == null || raw.isEmpty) {
    return playPublished && packageName.isNotEmpty
        ? Uri.https('play.google.com', '/store/apps/details', {
            'id': packageName,
          })
        : null;
  }
  final uri = Uri.tryParse(raw);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.userInfo.isNotEmpty ||
      !uri.hasAuthority ||
      uri.port != 443 ||
      uri.fragment.isNotEmpty) {
    return null;
  }
  if (uri.host == 'play.google.com') {
    return uri.path == '/store/apps/details' &&
            uri.queryParameters['id'] == packageName
        ? uri
        : null;
  }
  return trustedHosts
          .split(',')
          .map((s) => s.trim().toLowerCase())
          .contains(uri.host)
      ? uri
      : null;
}

class AppUpdateController extends ChangeNotifier {
  AppUpdateController({
    required this.fetch,
    required this.packageInfo,
    required this.launch,
    DateTime Function()? now,
    this.enabled = true,
    this.apkUpdater,
  }) : now = now ?? DateTime.now;
  final Future<AppUpdate> Function(String) fetch;
  final Future<PackageInfo> Function() packageInfo;
  final Future<bool> Function(Uri) launch;
  final DateTime Function() now;
  final bool enabled;
  final ApkUpdater? apkUpdater;
  double? downloadProgress;
  String? updateStatus;
  bool _cancelled = false;
  AppUpdate? update;
  String? error;
  bool checking = false, launching = false, _disposed = false;
  bool _returnFromStore = false;
  String _packageName = '';
  DateTime? _lastCheck;
  final _deferred = <String>{};
  Future<void>? _pending;
  bool get blocked => update?.available == true && update?.mandatory == true;
  bool get visible => update?.available == true;

  Future<void> check({bool manual = false, bool returnedFromStore = false}) {
    if (_disposed || !enabled || launching) return Future.value();
    if (_pending != null) return _pending!;
    final force = manual || (returnedFromStore && _returnFromStore);
    if (!force &&
        _lastCheck != null &&
        now().difference(_lastCheck!) < const Duration(minutes: 5)) {
      return Future.value();
    }
    _returnFromStore = false;
    _lastCheck = now();
    final work = _check(manual);
    _pending = work;
    return work.whenComplete(() => _pending = null);
  }

  Future<void> _check(bool manual) async {
    checking = true;
    error = null;
    notifyListeners();
    try {
      final info = await packageInfo().timeout(const Duration(seconds: 5));
      if (!validAppVersion(info.version.trim())) throw const FormatException();
      final result = await fetch(
        info.version.trim(),
      ).timeout(const Duration(seconds: 12));
      if (_disposed) return;
      _packageName = info.packageName;
      update =
          result.available &&
              (result.mandatory || manual || !_deferred.contains(result.latest))
          ? result
          : null;
    } catch (e) {
      if (_disposed) return;
      // Keep only a previously confirmed mandatory policy during transient failure.
      if (!blocked) update = null;
      error = e is FormatException
          ? 'Update information is unavailable or invalid. Please retry.'
          : e is DioException
          ? 'Could not check for updates. Check your connection and retry.'
          : 'Could not check for updates. Please try again.';
    } finally {
      if (!_disposed) {
        checking = false;
        notifyListeners();
      }
    }
  }

  void later() {
    if (blocked || launching || update == null) return;
    _deferred.add(update!.latest);
    update = null;
    notifyListeners();
  }

  Future<void> openUpdate() async {
    if (launching || checking || update == null || _disposed) return;
    final uri = updateDestination(update!, _packageName);
    if (uri == null) {
      error =
          'No trusted update destination is available. Please contact your service operator or retry.';
      notifyListeners();
      return;
    }
    launching = true;
    _cancelled = false;
    downloadProgress = null;
    error = null;
    notifyListeners();
    try {
      if (apkUpdater != null && uri.host != 'play.google.com') {
        updateStatus = 'Downloading update…';
        notifyListeners();
        await apkUpdater!.download(uri, (received, total) {
          if (_disposed) return;
          downloadProgress = total > 0 ? (received / total).clamp(0, 1) : null;
          notifyListeners();
        });
        if (_disposed || _cancelled) return;
        updateStatus = 'Opening Android installer…';
        notifyListeners();
        final opened = await apkUpdater!.install();
        if (_disposed) return;
        updateStatus = opened
            ? 'Confirm the update in Android. If cancelled, tap Update Now to retry.'
            : 'Allow updates from this app in Settings, then return and tap Update Now.';
        _returnFromStore = true;
        return;
      }
      if (!await launch(uri).timeout(const Duration(seconds: 10))) {
        throw StateError('Launch failed');
      }
      _returnFromStore = true;
    } catch (_) {
      if (!_disposed) {
        updateStatus = null;
        error = _cancelled
            ? 'Download cancelled. You can retry anytime.'
            : apkUpdater != null && uri.host != 'play.google.com'
            ? 'Could not download or install this update. Check your connection, storage, and that the server provides a newer APK for this app.'
            : 'Could not open the update link. Please try again.';
      }
    } finally {
      if (!_disposed) {
        launching = false;
        notifyListeners();
      }
    }
  }

  void cancelDownload() {
    _cancelled = true;
    apkUpdater?.cancel();
  }

  @override
  void dispose() {
    _disposed = true;
    apkUpdater?.cancel();
    super.dispose();
  }
}

final appUpdateProvider = Provider<AppUpdateController>((ref) {
  final service = AppUpdateService(ref.watch(apiClientProvider));
  final controller = AppUpdateController(
    fetch: service.check,
    packageInfo: PackageInfo.fromPlatform,
    launch: (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
    apkUpdater: const bool.fromEnvironment('APP_PUBLISHED_ON_PLAY')
        ? null
        : ApkUpdater(),
    enabled: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
  );
  ref.onDispose(controller.dispose);
  return controller;
});
