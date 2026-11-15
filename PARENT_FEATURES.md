# Parent app features and setup

Implemented against the shared VatsalyaGuardPlatform SimpleRbac API. No backend business rules or Child protocol were changed.

## Features
- Permission-aware dashboard and feature navigation using the account permissions from `/admin/auth/me`.
- Account profile, password change, verification email, password recovery and reset-link/token entry.
- Child creation, edit/profile, activation, deactivation and archive.
- Device profiles, assign/unassign, rename/remove and status/location/battery/network telemetry.
- Pairing code creation with child identity, QR display/share, reachable server validation, expiry and revoke. Enrollment credits are consumed by the server only at successful pairing.
- Child supervision: location/history, installed apps search/filter and sorted inventory, consistent allow/block state, custom daily limits, usage, tracking, protection and device/parent PIN controls; SOS history and resolution.
- Family map with all reported child positions. Select a child to show distances to other children. Optional Parent position is requested only on tap and used locally for distance.
- Permission-aware records for controls, screen-time plans, approvals, web filters, website decisions, geofences, alerts, activity/history, reports/JSON sharing, notifications, subscription, payment requests, invoices and support.
- Realtime websocket reconnection, account-isolated data caches and rejection of responses from a previous account/session revision.
- Optional Firebase push permission, installation/token registration and refresh, foreground alerts, notification-open refresh, background refresh marker and token revocation at logout.

## Existing backend limits
Generic resource endpoints save records and expose actions granted by the backend. Web filters, website decisions, geofence monitoring and schedule enforcement need compatible Child-side support; saving these records alone does not enforce them. Subscription/payment records do not activate billing or charge funds. App approval and website rules expose existing records and authorized decisions; the current Parent catalog does not grant creation of those records. These limitations are explained in the relevant screens.

## Run against your server
Use a LAN/public address reachable by both phones:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://YOUR_LAN_IP:7078
```

The existing project default server address is preserved. Recovery email links can be pasted into Account recovery; app-link domain hosting/association is not assumed.

## Firebase push setup (configuration currently unavailable)
Register Android package `com.vrajranitech.solution` in your Firebase project. Put its matching `google-services.json` at `android/app/google-services.json`; Gradle applies the Google Services plugin only when this file exists. Do not reuse the Child package configuration.

Alternatively supply matching Firebase options through `--dart-define` values `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_SENDER_ID`, `FIREBASE_PROJECT_ID` and, for iOS, `FIREBASE_IOS_BUNDLE_ID`. For iOS add the matching `GoogleService-Info.plist` to the Runner target and configure Push Notifications, Background remote notifications and APNs credentials in Firebase. iOS compilation was not verified on Windows.

Configure the backend's Firebase push provider for the same project, then tap Settings > Enable notifications. Permission denial and missing configuration are reported in the app. Native Firebase options, backend delivery and foreground/background/terminated delivery must be checked on a real phone.

## Validation
`flutter analyze --no-pub lib test`, `flutter test --no-pub`, and `flutter build apk --debug --no-pub` are the required local checks. Mocked mobile widget tests cover feature visibility, child/editor layout, resource forms and recovery; API adapter tests cover nested realtime data, pairing security, SOS confirmation and stale-account responses. This is not a claim of authenticated live backend or real-device enforcement testing.

Release signing remains the project's existing setup; the supplied APK is a debug build.
## Device approvals

Open a child > Device approvals. The Child app now has an **Ask Parent for permission** button for phone shutdown, location OFF and airplane mode ON. Parent approvals default to 15 minutes (5/15/30/60 selectable), can be denied/revoked, and expire. Pending requests expire after 30 minutes. You need `parent.control.view` to read approvals and `parent.control.update` to decide or restore settings.

**Enable & protect location** revokes location-off permission and requests GPS/location ON on Android 11+ Device Owner devices. **Disable & protect airplane mode** revokes airplane permission and applies the Android 9+ Device Owner airplane-mode restriction. Native grants use Android elapsed realtime and are invalidated at reboot; an Android alarm and regular sync restore restrictions after expiry. Android may defer alarms during power-saving/Doze, so expiry enforcement is best effort and must be tested on the target phone.

Device reports show observed location/airplane state, Device Owner status, applied guards and command acknowledgement. A saved Parent command is not a claim that an offline phone received or applied it. Airplane mode can disconnect the phone; new remote commands need the phone to reconnect. The local expiry alarm can restore supported restrictions without internet.

Hardware shutdown/forced restart cannot be reliably blocked by a regular app. Shutdown approval is an explicit Child request/Parent decision and instructions to use the hardware power button; the app always reports shutdown enforcement unavailable. This feature does not silently enable kiosk mode, root the phone, grant privileged settings permission or perform factory-reset/device-owner provisioning.

Install both updated apps and deploy/restart the backend with `DeviceSafetyController.cs` and the two Child safety routes in its trusted-device middleware. No schema migration or new hardcoded role is needed. Push notifications use the existing push queue/provider; Parent Firebase configuration is still required for background push delivery. In-app approval polling works while connected without Firebase.
