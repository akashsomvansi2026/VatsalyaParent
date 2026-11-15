# Google Maps family map setup

## Device diagnosis (18 October 2026)

Connected Android device: installed the diagnostic debug APK with `adb install -r` (existing data preserved), opened Nearby and reproduced the failure in School and Hospital searches. Native SDK response: `API_ERROR_NEARBY_SEARCH: 9011: The caller does not have permission`. Google defines 9011 as REQUEST_DENIED, an authorization error. This confirms a Places service authorization rejection; it does not identify which Google Cloud setting is wrong. Cloud settings have not been inspected or changed.

Check Places API (New) enablement, billing, API restrictions, and Android application restrictions for the key's project. The installed debug package is `com.vrajranitech.solution`; its signer SHA-1 is `D3:9B:FA:23:DB:B7:BF:20:39:E6:BA:E6:5A:EC:5F:47:21:68:6B:48`. This is a public signing fingerprint, not an API key. Production/Play builds have their own signing fingerprints.

Sanitized device evidence: `verification/nearby-device-diagnostic.txt`; screenshot: `verification/nearby-device.png`. Debug-only SDK error logging was added with API-key redaction; raw errors remain excluded from user-facing UI. Static analysis and seven Nearby tests passed. No backend changes are needed for this observed failure.

## Nearby key-loading fix (18 October 2026)

Android Nearby now reads `com.google.android.geo.API_KEY` from the installed application metadata over the private `vatsalya/maps` channel. This is the same key used by map tiles, so omitting a Dart define no longer gives Nearby a different key. The source default remains a placeholder; real keys stay in ignored local configuration. iOS still reads the Dart define.

Nearby has a bounded request timeout and separate sanitized messages for configuration, network, quota and unsupported-platform failures. Retrying a failed request does not cache the error. Google Cloud Places API enablement, billing, and package/signing restrictions still have to allow the installed app. These cannot be confirmed by a build alone.

The marker-only live tracking behavior is documented in `family_map_live_tracking.md`; the historical route checklist below does not apply to the current Family Map screen.

Full implementation: `lib/features/family_map/`. The former screen path exports the new screen to preserve routes and imports. The feature retains authenticated Parent children loading, permission-gated actions, 30-second refresh, tracking-enabled coordinate validation, and account-scoped snapshot fallback. Initial avatars use the child's name over a gradient, with status dots. Native Google Maps targets Android and iOS; desktop shows an explanatory panel.

## Dependencies

```yaml
dependencies:
  google_maps_flutter: ^2.6.0
  google_places_sdk_plus: ^1.1.0
  flutter_polyline_points: ^3.0.1
  flutter_riverpod: ^3.4.3
  dio: ^5.11.1
  geolocator: ^14.0.0
```

The caret ranges resolve newer compatible releases. The current Places iOS implementation requires iOS 16; project deployment targets have been raised accordingly. iOS compilation requires macOS/Xcode.

## Enable Google Cloud APIs

Select the same billing-enabled project in each link:

- [Maps SDK for Android](https://console.cloud.google.com/flows/enableapi?apiid=maps-android-backend.googleapis.com)
- [Maps SDK for iOS](https://console.cloud.google.com/flows/enableapi?apiid=maps-ios-backend.googleapis.com)
- [Places API (New)](https://console.cloud.google.com/flows/enableapi?apiid=places.googleapis.com)
- [Directions API (Legacy)](https://console.cloud.google.com/flows/enableapi?apiid=directions-backend.googleapis.com)
- [Credentials](https://console.cloud.google.com/apis/credentials)

Directions is a legacy service and might not be available to newly enabled projects. This implementation requests the Directions JSON contract; use a backend adapter to Routes API where required.

## Single Dart key source

`lib/core/config/api_keys.dart`:

```dart
const kGoogleMapsApiKey = String.fromEnvironment(
  'GOOGLE_MAPS_API_KEY',
  defaultValue: 'YOUR_GOOGLE_MAPS_API_KEY_HERE',
);
```

The literal placeholder occurs only in that file. Android reads its fallback from that file. Keep actual keys out of source. Set `GOOGLE_MAPS_API_KEY=<actual Android key>` in ignored `android/local.properties`, alongside existing Flutter and Android SDK paths. Android Nearby reads this same packaged key automatically. A Dart define is optional on Android for Nearby; retain it where other Dart consumers require it. On iOS pass the iOS key through that Dart define; AppDelegate reads Flutter's encoded build settings. Rebuild after key changes.

## Android Kotlin DSL (actual project)

Put the import at the top of the file, and add the values before `android {` in `android/app/build.gradle.kts`:

```kotlin
import java.util.Properties

val mapsProperties = Properties().apply {
    val propertiesFile = rootProject.file("local.properties")
    if (propertiesFile.exists()) propertiesFile.inputStream().use { load(it) }
}
val mapsKeyDefault = Regex("defaultValue: '([^']+)'")
    .find(rootProject.file("../lib/core/config/api_keys.dart").readText())!!.groupValues[1]
```

Inside `android.defaultConfig`:

```kotlin
manifestPlaceholders["GOOGLE_MAPS_API_KEY"] =
    mapsProperties.getProperty("GOOGLE_MAPS_API_KEY", mapsKeyDefault)
```

## Equivalent build.gradle (Groovy)

Use this only if converting this project's `.kts` file to Groovy:

```groovy
def mapsProperties = new Properties()
def propertiesFile = rootProject.file('local.properties')
if (propertiesFile.exists()) {
    propertiesFile.withInputStream { mapsProperties.load(it) }
}
def keySource = rootProject.file('../lib/core/config/api_keys.dart').text
def mapsKeyDefault = (keySource =~ /defaultValue: '([^']+)'/)[0][1]
android {
    defaultConfig {
        manifestPlaceholders += [GOOGLE_MAPS_API_KEY:
            mapsProperties.getProperty('GOOGLE_MAPS_API_KEY', mapsKeyDefault)]
    }
}
```

Inside AndroidManifest.xml's `<application>`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${GOOGLE_MAPS_API_KEY}" />
```

`.gitignore`:

```gitignore
/android/local.properties
```

## iOS

Add inside the root dictionary of `ios/Runner/Info.plist`:

```xml
<key>DART_DEFINES</key>
<string>$(DART_DEFINES)</string>
```

Exact `ios/Runner/AppDelegate.swift`:

```swift
import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let encoded = (Bundle.main.object(forInfoDictionaryKey: "DART_DEFINES") as? String),
       let value = encoded.split(separator: ",").compactMap({ Data(base64Encoded: String($0)) })
         .compactMap({ String(data: $0, encoding: .utf8) })
         .first(where: { $0.hasPrefix("GOOGLE_MAPS_API_KEY=") }) {
      GMSServices.provideAPIKey(String(value.dropFirst("GOOGLE_MAPS_API_KEY=".count)))
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
```

## Key restrictions

1. Create a separate Android key. Choose **Application restrictions > Android apps**. Add package `com.vrajranitech.solution` with the debug signing SHA-1, release signing SHA-1, and Play App Signing SHA-1 as separate entries. Obtain local fingerprints with `cd android` then `./gradlew signingReport`; Play's fingerprint is in Play Console > App integrity. Under **API restrictions**, allow Maps SDK for Android and the Places API (New) services needed by the native SDK.
2. Create a separate iOS key. Choose **iOS apps**, add bundle identifier `com.vrajranitech.solution` (verify each flavor's identifier). Restrict APIs to Maps SDK for iOS and Places API (New). Supply this key through the iOS Dart define.
3. Directions REST is a web service: Android SHA-1/iOS bundle restrictions are not a substitute for server-side restrictions. For production set `--dart-define=GOOGLE_DIRECTIONS_PROXY_URL=https://your-public-api.example/directions`. The service sends only origin/destination/mode to that endpoint; no Google key is sent. Implement that endpoint in your authenticated backend, keep a separate Directions key server-side, IP-restrict it, restrict it to Directions, and return Google's Directions JSON response. Inject the existing authenticated backend Dio through `directionsServiceProvider` when the proxy requires login. The default direct endpoint is provided for local integration; do not ship an unrestricted key to make it work. No backend endpoint is created by this mobile refactor.
4. Set quotas/budget alerts, monitor usage and rotate compromised keys. Never commit real keys or log Directions request URLs.

References: [native Places SDK](https://pub.dev/packages/google_places_sdk_plus), [Google key security](https://developers.google.com/maps/api-security-best-practices), [Nearby Search](https://developers.google.com/maps/documentation/places/web-service/nearby-search).

## 12-item device testing checklist

1. Android debug and signed release render tiles with their own signing SHA-1 entries.
2. iOS 16+ renders maps with the restricted bundle ID key and native Places initializes.
3. Normal, satellite, terrain and hybrid choices all change map rendering.
4. Parent location is a blue dot; allow, deny, permanently deny and disabled location-service paths behave correctly.
5. Every valid tracking-enabled child gets an initial avatar with online/offline dot; missing/invalid coordinates never produce markers.
6. Selected child avatar increases exactly 15%, glows, and updates after selecting another child.
7. Tap a child marker: obtain parent location, show road distance and ETA; missing GPS or route failure has a clear fallback.
8. Nearby opens a draggable sheet; each of School, Hospital, Park, Restaurant, Mall and Pharmacy returns the appropriate category within 3 km.
9. Repeat the same category/location inside five minutes without another SDK request; after five minutes or movement, request fresh results.
10. Choosing a nearby place draws the route and opens its detail sheet; verify the 10px 15% glow and 5px core with round caps/joints.
11. Turn-by-turn sheet scrolls through all instructions, distances, durations and copyright; empty/no-route and offline errors can be retried.
12. Run compact-screen family selection, authenticated Parent family flow, full tests, analyzer and Android APK build; check refresh, cached snapshots, permissions, account changes, rapid selections and navigation during requests on real devices.

## Configured local build

The supplied key is saved only in ignored `android/local.properties` and `config/google_maps.local.json`. Build or run Android with:

```powershell
flutter run --dart-define-from-file=config/google_maps.local.json
flutter build apk --debug --dart-define-from-file=config/google_maps.local.json
```

For iOS use a separately restricted iOS key in your local define file before building. The secret values are intentionally omitted from this document.

## Validation results

- Android debug APK built successfully; a final local-key build is run with the define file above.
- Map selection, authenticated family flow, Directions parsing/error handling and Nearby cache/category tests passed (10 targeted tests).
- Changed files passed Dart analyzer with no issues. Full-project analysis reports an existing unused import in the login screen.
- Full suite initially reported an unrelated login-screen signup-text expectation failure; the map failure from that run was fixed and the targeted map test then passed.
- Native map rendering, billing/API enablement, key restrictions, real-device routing and iOS compilation remain unverified.
