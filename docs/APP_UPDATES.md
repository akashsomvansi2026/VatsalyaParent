# App update checks

The Android app checks the public update endpoint after startup restoration, on foreground return (five-minute cooldown), and from Settings > Check for Updates. Concurrent requests are coalesced. A successful link launch allows one immediate recheck on return. Installed version and package name come from package_info_plus.

Optional releases show Update Now and Later. Later suppresses that release for the current app session; a manual check can show it again. Mandatory releases show Update Now and Retry, block outside taps/back, and redirect feature deep links to /app-update. A successful no-update response removes the gate. Network failures before any confirmed mandatory response do not block the app. A confirmed mandatory response is retained only in memory during temporary failures; it is not a durable backend security control.

## Release destinations

Default trusted host: joinus.akashdreamer.uk. Exact HTTPS hosts only, no credentials, custom ports or fragments. Play links must identify the installed package. The operator must ensure trusted destinations and their redirects lead only to trusted releases; opening an external browser cannot constrain later server redirects.

Add a reviewed operator-owned CDN with:

    flutter build appbundle --release --dart-define=APP_UPDATE_TRUSTED_HOSTS=joinus.akashdreamer.uk,downloads.example.com

Only after confirming the installed package is published on Google Play, enable missing-link fallback:

    flutter build appbundle --release --dart-define=APP_PUBLISHED_ON_PLAY=true

No listing is assumed by default. Missing or rejected destinations and launch failures show an error and leave Retry available. No APK installation permissions or silent installation are added.

Google Play In-App Updates is suitable when distribution is confirmed to be exclusively via Google Play and Play owns the available release. It is not wired in because publication is unconfirmed and the supplied API supports operator-hosted downloads. See https://developer.android.com/guide/playcore/in-app-updates.

## Test scenarios

Run `flutter test test/app_update_test.dart`. Tests mock API and package metadata, never change production release settings.

For controlled staging/device verification, install version 1.0.1:

- Current: latestVersion=1.0.1, minimumVersion=1.0.0 -> no update UI.
- Optional: latestVersion=1.1.0, minimumVersion=1.0.0 -> Update Now/Later.
- Mandatory: latestVersion=1.1.0, minimumVersion=1.1.0 -> no Later; outside tap, Android Back and feature deep links must remain blocked.
- Publish a trusted downloadUrl and releaseNotes. Test a missing link, invalid link, unavailable server, slow server and browser launch failure.
- Return from the store, install the supported release and reopen the app; a successful no-update response clears the gate.
- Verify compact screens, enlarged text, and light/dark Material themes. The update UI inherits the existing application theme; this feature does not change the app's global theme selection.

## Backend requirement still outstanding

The inspected ASP.NET endpoint computes metadata from AppReleaseStore and minimumVersion. No protected-feature API enforcement was found in the inspected SimpleRbac source. Metadata alone does not reject unsupported clients.

After package detection the shared API client adds X-App-Version and X-App-Platform to authenticated requests without changing Authorization/session handling. Server middleware still needs to apply the same AppReleaseStore minimum policy to mobile feature endpoints and return HTTP 426 with update metadata for unsupported versions. Exempt the public update endpoint, release download and recovery/support routes as appropriate. Do not infer trusted client identity from spoofable version headers; treat version gates as support policy and retain existing authentication/RBAC. Missing-version behavior must preserve existing web/Child integrations deliberately. This Flutter checkout does not modify or deploy that separate backend.

Live check on 17 October 2026: version 1.0.1 returned updateAvailable=false, latestVersion=1.0.0, minimumVersion=1.0.0, downloadUrl=null. Backend uses publishedAtUtc, which is informational and does not affect the app's decision. The no-release-config backend response omits mandatory/latest/minimum; the client treats that as unavailable metadata and fails open instead of reporting a verified current release.

## Files

- lib/core/app_update/app_update.dart: model, service, URL policy, controller and Riverpod provider.
- lib/core/app_update/app_update_manager.dart: startup/resume lifecycle and theme-aware update surface.
- lib/app.dart: manager above the existing router.
- lib/presentation/router/app_router.dart: mandatory route guard.
- lib/presentation/screens/settings/settings_screen.dart: manual check with loading and result feedback.
- lib/data/remote/api_client.dart: public unauthenticated metadata GET and mobile version headers.
- pubspec.yaml / pubspec.lock: package_info_plus and url_launcher.
- test/app_update_test.dart: mocked behavior and UI regression coverage.

Package documentation: https://pub.dev/packages/package_info_plus and https://pub.dev/packages/url_launcher.

## Validation completed

- 22 targeted update/privacy/family/main-screen tests passed; the final 15 update-specific tests also passed after lint/header changes.
- Analysis of all changed Dart sources and the update test: no issues. Full-project analysis found an existing unused auth_footer_link import in login_screen.dart; it was left unchanged.
- Signed release AAB built successfully: build/app/outputs/bundle/release/app-release.aab (59.4 MB).
- Actual installed-device/store-return behavior and a live mandatory release have not been tested. Production release settings were not changed.
