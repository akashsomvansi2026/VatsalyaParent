# UI refinement and validation

Implemented directly in the existing Flutter application. No service, repository, model, provider, permission guard, or route contract was changed.

## Changes

- Shared Material defaults: consistent typography, rail selection, tooltips, and 48 dp icon targets.
- Authentication: system-font typography consistent with workspace; password visibility uses an accessible button with an explicit tooltip.
- Dashboard: safety overview before profiles, fewer nested surfaces, intrinsic-height child cards on larger layouts, wrapping last-seen text, and scalable metric values.
- Workspace shell: bounded content width for dashboard, features and settings; map retains its available space.
- Feature hub: descriptive navigation rows, semantic SOS tint, shared cards and typography.
- Settings: clearer introductory hierarchy.
- Record details: stacked field labels and selectable values; nested expanders have their own Material surface.

## Verification

- flutter analyze --no-pub: no issues.
- flutter test --reporter expanded: 84 passed.
- Added compact-width and enlarged-text regression coverage for metrics and nested record details.
- Existing auth test expected a registration footer already commented out in the app. Updated its assertion to preserve the current hidden-link behavior.
- Screen-flow captures cover feature hub, child profiles/editors, records, recovery and pairing. Test captures do not establish native-device rendering quality.

## Remaining acceptance

This is a shared-system and targeted-layout refinement, not a bespoke visual replacement of every screen. Splash, legal, map, child-detail and several management screens retain their existing layouts and inherit shared styles where applicable. Physical Android visual checks, keyboard/inset behavior, TalkBack and live authenticated API/device flows remain to be reviewed. Automated checks do not establish production readiness.
