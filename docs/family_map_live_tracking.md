# Family Map marker tracking

Implemented in the existing Parent app, shared backend, and Flutter Child checkout; verified and hardened again on 19 October 2026.

## Follow-up hardening (19 October 2026)

The implementation remains marker-based on Google Maps. The follow-up audit found and fixed:

- Complete authorized snapshots now pass through one location merge policy: invalid, future-dated and older-than-seven-day coordinates cannot replace a usable last-known position. A different device cannot inherit the previous installation's rejected fix. Timestamp-less legacy fixes are last-known only. Authoritative null still removes a position immediately.
- All Family Map status surfaces (marker ring/bearing, selected panel, member list, selector, summary and open details sheet) use Parent synchronization state. A failed refresh or expired synchronization cannot show Tracking Active, even if the last child snapshot claimed online. This is separate from a Child device being offline.
- The existing WebSocket gateway now times out a stalled handshake after 15 seconds and a silent established connection after 45 seconds, then reconnects using its existing backoff. Disconnect/logout cancels receive timers and prevents reconnect. Valid frames renew the receive watchdog; malformed frames do not.
- HTTP refresh results and failures are scoped to the requesting account. Realtime frames with mismatched child identifiers are ignored. Successfully merged positions, rather than rejected raw fixes, are written to the encrypted cache.
- Internal backend device-record updates now refresh their DeviceId association. Otherwise a new installation could successfully sync while the Parent's current-device lookup continued to see the older installation. Device model reads are also current-device scoped. Ownership and credential checks remain unchanged.
- The Child location service clears its running flag when the position stream ends, can be restarted by the existing monitoring policy loop, accepts only actual foreground/background location grants, and prevents an old asynchronous start/upload from changing a later tracking session. Unusable current fixes do not prevent existing queued measurements from being retried.

## Behavior

- Family Map keeps Google Maps and displays each child's actual latest reported coordinates. A marker tap selects that child and immediately opens an updating details sheet without requesting the parent's location.
- Details include the name, photo when supplied by the API (person fallback otherwise), device, battery when reported, heartbeat, capture time, coordinates, reported accuracy, and permission/service/background checks. The current backend has no child photo-upload contract; no new upload feature was introduced.
- Child selection is independent. Socket `child_updated` snapshots update existing children directly, without another HTTP request per frame. HTTP loads at entry/resume, every 60 seconds for membership/permission reconciliation, and every 15 seconds while the socket is disconnected. The app's existing gateway owns connection/reconnection and authentication.
- Periodic work pauses when the Parent app is backgrounded. Returning refreshes the authorized snapshot. The existing account-scoped encrypted cache supplies clearly labeled offline positions. Authorization failures clear displayed data instead of loading cached coordinates.
- Null locations in authoritative snapshots clear the marker (including revoked location access). Invalid, future, expired and out-of-order location replacements retain a usable previous fix from the same installation, otherwise they clear the position. Missing JSON coordinates are invalid, never defaulted to (0,0); real (0,0) is valid.
- Initial load and explicit selection/fit/location controls can move the camera. Location frames do not recenter it.
- Original gradient avatar markers have a status ring. Measured reliable bearing adds a separate pointer. Position and shortest-angle rotation interpolate over 800 ms only for fresh, verified updates no more than 30 seconds and 100 metres apart. Large gaps, large jumps and date-line crossings display the actual new fix directly. Intermediate render positions are never saved or sent as measurements.
- Reported horizontal accuracy draws a circle up to 10 km; larger uncertainty remains visible in details. Accuracy is a device estimate, not a claim of exact position or a correction to coordinates.
- Family Map makes no Directions/OSRM/Valhalla requests and draws no road polylines. Nearby Places discovery remains available; choosing a place centers the map. Existing Directions services and their tests remain outside this screen.

## Status rules

- Tracking Disabled: parent policy is off, or a recent device check reports missing location permission/services.
- Device Offline: no current online heartbeat within 2 minutes (future/unknown heartbeats also cannot establish online state).
- Location Stale: a usable fix is older than the server-provided `locationStaleAfterSeconds` (default 180) or has no capture timestamp. Future and over-retention fixes are unavailable and are not rendered.
- Temporarily unavailable: no valid fix or no recent positive device capability report. Older clients without telemetry remain unverified.
- Location quality limited: accuracy is absent, non-positive, non-finite, over 100 metres, or the device marks a simulated location.
- Tracking Active: fresh heartbeat and fix, recent positive permission/services/background-running report (within 2 minutes), and acceptable reported accuracy. A toggle or heartbeat alone cannot establish active tracking.

Background location permission is displayed separately. A running Android foreground location service can operate with a while-in-use grant; the permission flag alone is not treated as proof that a service is running.

## Existing APIs extended, no new endpoints

- `POST /api/children/device-info`: optional `trackingStatus` containing booleans `locationPermissionGranted`, `locationServicesEnabled`, `backgroundLocationPermissionGranted`, `backgroundTrackingActive`.
- `POST /api/child/sync`: the same optional `trackingStatus` contract on DeviceSyncRequest.
- `POST /api/children/location`: optional `speed`, `heading`, `headingAccuracy`, `isMocked`. Speed must be finite and non-negative; heading is [0,360); heading accuracy is [0,180]. Existing coordinate, horizontal-accuracy, timestamp and battery validation remains.
- Parent children/detail responses and existing WebSocket `child_updated` snapshots add `trackingStatus` and expose the already configured staleness threshold. The report timestamp is assigned by the backend. Status reads are restricted to the current paired device; old-device fixes cannot establish active tracking for a new device.
- Existing parent scope/RBAC, location permissions and `X-Device-Token` child authentication remain enforced.

## Storage and configuration

No migration or new table is required; this follow-up adds no new API endpoint or configuration key. Existing `family.location` JSON records retain the optional movement fields. New internal `family.tracking_status` JSON records hold capability reports and their server receipt time. Unknown battery is stored as null instead of fabricating 100 percent. Existing idempotency and bounded history are preserved, including capture timestamps for delayed history.

Deploy the backend first, then the Child update, then the Parent update. All new input fields are optional for older clients. Keep the existing Maps key and Places configuration; this feature needs no routing key or routing proxy. `LocationTracking:StaleAfterSeconds` remains the backend staleness setting.

The Child checkout used is `D:/Android Work Space/Projects/vatshalyachildapp`; the old memory path no longer exists. The Child reports actual permission/services and LocationService running state via the existing 30-second policy sync, and retains measured speed/heading/heading accuracy/mock flag in its existing location queue. Existing permission onboarding, consent, Android foreground notification, and background permission flow remain intact.

## Modified files

Parent (`D:/Android Work Space/Projects/untitled`):
- lib/features/family_map/family_map_screen.dart
- lib/features/family_map/widgets/google_map_view.dart
- lib/features/family_map/widgets/child_detail_sheet.dart
- lib/features/family_map/widgets/selected_child_panel.dart
- lib/features/family_map/widgets/child_selector_sheet.dart
- lib/features/family_map/widgets/family_summary_strip.dart
- lib/core/utils/child_location_status.dart
- lib/core/utils/location_snapshot.dart (new)
- lib/data/remote/realtime_gateway.dart
- lib/data/models/child.dart
- lib/data/models/location_point.dart
- lib/data/local/children_snapshot_cache.dart
- test/child_location_status_test.dart
- test/family_map_realtime_test.dart (new)
- test/marker_movement_test.dart (new)
- test/location_snapshot_test.dart (new)
- test/realtime_gateway_test.dart (new)
- docs/family_map_live_tracking.md (this file)

Backend (`D:/dot_net_workspace/VatsalyaGuardPlatform`):
- SimpleRbac/FamilyIntegration.cs
- SimpleRbac/ChildMobileController.cs
- tools/HierarchyChecks/Program.cs

Child (`D:/Android Work Space/Projects/vatshalyachildapp`):
- lib/services/location_service.dart
- lib/services/server_sync_service.dart
- lib/providers/monitoring_provider.dart
- test/location_service_lifecycle_test.dart (new)

## Verification

- Parent changed-source/test static analysis: clean.
- Parent targeted tests: 14 passed across child_location_status_test, main_screen_flow_test, family_map_realtime_test, marker_movement_test, location_snapshot_test and realtime_gateway_test. Checks include disabled/missing permissions, offline/stale/future fixes, bad accuracy, simulated fixes, missing coordinates, bearing validation, child selection, live details, sibling isolation, older snapshot rejection, authoritative location removal, interpolation limits, and marker identity. New checks cover real loopback WebSocket handshake/silence timeouts and reconnect, logout/disconnect cancellation, Parent network failures, ignored events during pause and reload on resume, future/expired fixes and device-installation separation.
- Child changed-source static analysis: clean; 12 tests passed: 9 existing permission setup checks and 3 new location-service lifecycle checks (ended stream/restart, denied/unknown permission or GPS disabled, and stop during permission lookup).
- Backend build: zero errors and warnings with SkipFrontendBuild=true, UseAppHost=false, configuration TrackingBuild.
- Local authenticated API and WebSocket family integration: 187 checks passed in an isolated temporary PostgreSQL schema with outgoing delivery disabled. Added tests cover telemetry persistence, server timestamps, invalid speed/heading, permission-loss reports without location, unauthorized parent reads and wrong-child device reports, and current-installation heartbeat reassociation. Existing checks cover tracking-off storage, idempotent retry, delayed history, permission-scoped reads and WebSockets. Results: backend verification/tracking-api-results.txt.
- Parent and Child debug APK builds succeeded. Gradle emits existing Kotlin plugin migration warnings.

## Requested scenario coverage

| Scenario | Evidence in this verification |
| --- | --- |
| Correct child details on marker tap | Parent widget test exercises the map callback and sheet; marker-state test verifies child identity |
| Fresh live marker updates | WebSocket snapshot widget tests plus native marker-state interpolation checks |
| Tracking off / missing permission | Parent status tests, Child permission/lifecycle tests, backend tracking-off and capability-report checks |
| Device offline | Independent heartbeat-age/status unit tests |
| Stale, poor, invalid or future fixes | Status and snapshot-policy tests; backend numeric/time validation and delayed-history checks |
| Multiple children | Parent widget test updates siblings independently without changing the selected details |
| Smooth markers without routing | Marker position/bearing transitions; tracking screen/view contain no route-service calls or polylines |
| Unauthorized location reads / wrong child reports | Authenticated isolated API checks return forbidden and preserve scope restrictions |
| Network loss, reconnect, lifecycle | Real loopback WebSocket silence/handshake timeout/reconnect tests; pause/resume widget tests; Child stream closure/restart tests |
| Actual GPS, process death, OEM power behavior | Pending hardware acceptance; no device was connected during this follow-up |

## Remaining acceptance gates

ADB reports no connected device, and the user confirmed that hardware is currently unavailable. Native Maps rendering/key restrictions, real GPS movement, OEM battery restrictions, Android foreground/background transitions, process death, real-network reconnection, and installed Parent/Child interaction require device testing. iOS was not built. There is no claim of complete real-device end-to-end verification. Automated marker tests inspect generated marker state using a platform fallback; they do not replace native map rendering tests. No running backend was deployed or restarted, and no production database was migrated. Deploy the updated backend and Child app before expecting the new telemetry to appear in the installed Parent app.
