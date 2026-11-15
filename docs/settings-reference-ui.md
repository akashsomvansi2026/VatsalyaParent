# Settings reference UI

The Settings screen retains Riverpod session, app-update and push-service dependencies. Presentation components in `settings_reference_widgets.dart` provide a responsive illustrated header, account initials/profile card, softly tinted action rows and readable wrapping. Content is centered within a 900px pane. The Privacy Policy action is retained in About.

The notification switch reads the existing push service state. Turning it off calls `disable()`, persists opt-out to the existing secure-storage preference, and uses the existing stop/revoke lifecycle. Notification permission/configuration errors stay visible through the service status. Installed app version/build comes from the app-update controller's package-info provider; unavailable metadata is labeled explicitly.

Confirmation dialogs now dismiss using their own dialog navigator context and scroll at enlarged text sizes. Existing confirmation copy and confirmed actions remain unchanged.

## Artwork

Built-in imagegen output: `assets/illustrations/settings_shield.png`.

Prompt: "Create a polished friendly 3D illustration for a family safety mobile app Settings header: a warm orange shield with peach beveled rim and a white gear cog centered on it, slight three-quarter tilt, surrounded by three small floating orange spheres. Soft warm studio lighting, clean rounded shapes, transparent background. No text, no letters, no border. Compact square composition with the entire shield visible."

## Validation

`test/settings_reference_test.dart` covers 390px, 320px with 3x text, landscape and tablet; update dispatch, actual-version display, notification enable/disable, permission refresh, cancelled/confirmed sign-out and existing profile/features/privacy navigation. A service test verifies opt-out persistence and suppressed restore. Rendered screenshots are widget previews; physical-device Firebase permission/delivery and native appearance remain separate checks.

Status feedback is height-bounded and scrollable, using fixed snackbars on compact-height or enlarged-text layouts to stay inside the navigation shell.
