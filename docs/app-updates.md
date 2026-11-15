# Server APK updates

Live verification on 2026-11-03: the Android feed advertised `latestVersion=1.0.0`, `minimumVersion=1.0.0`; its download endpoint returned HTTP 200 with APK content type and filename `Vatsalya_Guard_Child-v1.0.0.apk`. Correct the release metadata to a newer Parent APK before rollout. No server release settings were changed during implementation.

The Android Parent app checks the existing public `/api/app/update-check?platform=android&version=...` endpoint at launch and resume (five-minute cooldown). Settings provides a manual check. Optional updates can be deferred; required updates retain the existing navigation gate.

Update Now downloads the APK into private cache with progress and cancellation, then opens Android's installer. Downloads carry no account token, reject redirects, and accept only the HTTPS hosts allowed by `APP_UPDATE_TRUSTED_HOSTS` (default `joinus.akashdreamer.uk`). Serve APK bytes directly from the configured URL, including extensionless download endpoints. Downloads above 300 MB are rejected. Retry reuses a successfully validated download in the current process; restarting the app permits a fresh download.

Android may first open “Install unknown apps” Settings. Enable the source, return, and tap Update Now again. Installation is user-confirmed; cancelling installation does not report success or remove a required-update gate. Reopening the updated app checks its actual installed version.

## Publishing a release

1. Increase both the semantic version and Android build number in `pubspec.yaml` (for example `1.0.2+3`). The existing API compares semantic versions; increasing only the build number is insufficient for detection.
2. Build with `flutter build apk --release` using the existing Parent signing key.
3. Upload the **Parent APK**, package `com.vrajranitech.solution`, to the existing server. Never point this Parent feed at the Child/DPC APK.
4. In the existing app-update administration, set Android latestVersion, minimumVersion, downloadUrl, and releaseNotes. Keep minimumVersion at the oldest supported version for optional updates; raise it only when an update must be required.
5. On an older release-signed installation, test download, cancel/retry, source permission denial/grant, installer cancellation, successful update, retained login, and the next version check.

The native bridge rejects another package, an equal/older version code, or a different signing certificate. Android performs the final package verification. Certificate rotation needs a separately tested signing-lineage implementation. Debug-signed installations cannot install release-signed updates over themselves.

This configuration is for server-distributed APKs. `APP_PUBLISHED_ON_PLAY=true` retains the external store-link flow; a future Play distribution build must also remove the direct-install permission and follow Play distribution requirements. No Play in-app-update SDK is integrated.

Checks/downloads run while the app process is alive; this is not a silent installer or scheduled background update service. A required-update dialog is a client UX gate, not a replacement for backend version enforcement.
