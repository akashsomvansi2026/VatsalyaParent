# Family Map reference UI

The Family Map uses a Riverpod auto-disposed Notifier (`familyMapProvider`) for children, selected child, parent location, loading, errors, cached snapshots and synchronization. The screen owns navigation, permission prompts, lifecycle observation and map camera actions. Existing account/revision guards and location-snapshot merging are retained.

The reference is adapted with a floating brand header, status pill, layer/GPS/zoom controls, nearby family selection, illustrated action cards, family banner and rounded primary navigation. Map tiles and markers use the existing Google Maps integration; displayed location/status values are real app state.

## Illustration

Built-in imagegen generated `assets/illustrations/family_portrait.png` with a transparent background. Prompt: "Create a transparent background 3D stylized friendly Indian family illustration for a mobile family safety app: father left in orange knit sweater, young boy center in yellow hoodie, mother right in cream sweater, all smiling warmly, waist-up close grouped portrait, polished rounded animated movie aesthetic, soft studio lighting, front view. No text, no logos, no background, no border. Subjects fill canvas and bottom crop at waist. High quality illustration."

## Validation

Run `flutter test test/family_map_layout_test.dart test/family_map_realtime_test.dart test/main_screen_flow_test.dart`. The layout tests cover compact width and enlarged text; the flow tests cover selection, realtime updates, network failure and lifecycle refresh. Android/iOS map rendering and live device services require device checks.

## Dashboard reference

The dashboard screen retains its existing dashboardProvider and realtime dispatch. DashboardReferenceHeader, DashboardGreeting, DashboardMetricCard, DashboardEmptyChildren and DashboardOrangeButton isolate the presentation. Counts, parent name, SOS messaging and action visibility use actual state and permissions. Existing children cards, pairing navigation and provisioning sheet remain connected.

The built-in imagegen tool generated `assets/illustrations/dashboard_child.png`. Prompt: "A single cheerful young Indian boy with big brown eyes and tousled dark brown hair, wearing a warm yellow hoodie, resting chin on both hands with elbows on an invisible tabletop, looking directly at viewer with a sweet smile. Waist-up portrait crop, polished friendly 3D animated family safety mobile app illustration, warm soft studio lighting. Transparent background. No text, no logos, no frame, no extra people. Fill canvas with the boy."

`test/dashboard_reference_test.dart` checks compact/enlarged text, parent greeting, real empty counts, refresh and existing pairing route navigation. Rendered previews under verification are widget renders, not live native map or backend acceptance evidence.

## Responsive layout

Family Map and Dashboard center lower content within a 1120px maximum pane. Cards use actual available constraints and text scaling for columns, readable status wrapping, and bounded illustrations. Map toolbar/control spacing grows with text size. Compact landscape uses a scrollable navigation rail, and enlarged mobile text retains navigation destinations through icons and accessible labels. Pairing status moves below the title on narrow enlarged-text layouts.

`test/responsive_screens_test.dart` exercises both screens with the real navigation shell at 320x568 (1x and 3x), 390x844 (1.3x), 844x390 (2x), 768x1024 (2x), and 1280x800 (1x), checking overflow, map header/control separation, and pairing navigation.
