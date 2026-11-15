# Parent–Child safety implementation status

This document records the scope of the current Parent Flutter, Child Flutter, and shared backend changes. A successful build is not proof that a paired phone has received a policy or that a push notification arrived.

| Flow | Current behavior | Device / production check still needed |
| --- | --- | --- |
| Parent home | Map-first Rapido-inspired family overview with named child markers, child search, quick actions, selected-child details, and offline snapshot warning. | Compact phones, accessibility services, and real map tile provider terms. |
| Child location | Latest reported fix shows timestamp, accuracy, battery, and best-effort nearby address. Stale fixes are labeled last known even when the device is online. Parent can open the location in an external maps app. | Compare displayed fix with the installed Child app; test Android geocoder success/failure. iOS address lookup is currently unavailable. |
| Offline location | Child securely queues bounded fixes for up to seven days and submits their original timestamps when connected. Parent securely caches a bounded child snapshot per account for seven days. | Disconnect/reconnect a paired device and verify chronological server history. Parent cache is a fallback snapshot, never a live position. |
| Safe zones | Backend detects zone entry/exit from two fresh, ordered fixes for active zones attached to the family/child and records an alert plus a Parent push event. Fixes with accuracy worse than the zone radius are ignored. | Validate zone setup, boundary jitter, push delivery, and delayed/offline behavior on a paired device. Alerts require two fixes within 30 minutes; this is not continuous background geofencing. |
| Device safety | Parent sees reported safety state; new airplane-mode-on and location-off report transitions enqueue Parent push events. | Test Device Owner policy on supported Android versions and actual notification delivery. Power-off and every OEM setting cannot be forcibly prevented. |
| Web controls | Parent exposes existing safe-browser/domain, network-filtering, and managed-network-settings controls. | Verify policy refresh and browser enforcement on the installed Child app. Unsupported browsers or OS configurations must not be described as blocked. |

## Known gaps

- Left-behind/separation detection needs an independent reference location or reliable proximity signal. A single Child GPS stream cannot establish separation from a Parent.
- Notification preference controls and advanced content classification are not implemented in this pass. Existing push delivery and filtering remain subject to the configured backend and Android capabilities.
- Nearby address is a best-effort display label, not evidence of the Child's safety or precise location.
- Production rollout should check authenticated pairing, saved backend state, Child policy refresh, Parent push delivery, and the installed APKs over the public HTTPS backend.
