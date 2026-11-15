# Application UX audit and design system

## Existing flow inventory
- Launch: splash, required terms acceptance, session restoration.
- Access: sign in, registration, password recovery, email verification and password reset links.
- Primary workspace: family map, dashboard, feature directory, settings.
- Family setup: child profiles, device management, pairing setup and QR/code sheet.
- Child workspace: overview, approved apps, usage, location, lock settings, content filtering and device safety approvals.
- Operations: SOS alerts/history and permission-dependent record modules in ParentFeature.all.
- Account: profile, account settings and recovery.

All routes, permission guards, backend payloads, providers and destructive-action confirmations must be preserved. Legacy login and terms implementations also exist outside the active authentication routes; do not remove them without checking their consumers.

## Findings and implemented changes
Authentication had a separate peach palette and theme. The map had hardcoded orange colors and the dashboard used a warm gradient. These now share a restrained teal/slate palette. Authentication theme delegates to the application theme. Primary auth actions now use Material buttons, providing keyboard focus, disabled states and semantic activation. Fields have persistent labels. Shared editors validate on interaction and name their default action Save Changes.

Home and Dashboard were ambiguous sibling labels. The first destination now explicitly says Family map; existing routes remain unchanged. Bottom navigation becomes a rail at 840 logical pixels, extending labels at 1200. Dashboard statistic height accommodates text scaling. Shared error states explain the failure and retain retry; loading indicators provide semantic labels.

## Tokens
- Primary: #176B61; pressed/dark: #104B45; tint: #E7F3EF.
- Background: #F5F7FA; surface: #FFFFFF; border: #DFE7EC.
- Text: #172B3A; secondary text: #586A78.
- Success: #176B49; warning: #9A5800; error: #C62828; info: #365F91.
- Spacing scale: 4, 8, 12, 16, 24, 32, 48 logical pixels.
- Type: display 36, page 28, title 22, section 16, body 14–16, caption 12. Body line height 1.5. Respect system text scaling.
- Controls: minimum 48 logical pixel hit area; fields/buttons 16 radius; cards 20; sheets 28.

Use Material state behavior for focus, hover, selected and disabled. Loading belongs to asynchronous actions and data regions; success/error belongs to meaningful outcomes, not every decorative component. Never use color alone for statuses. Preserve visible field labels, entered data, cancel actions and contextual recovery.

## Remaining production acceptance
This is a shared foundation pass, not completed screen-by-screen production certification. Feature directory grouping/search, large record lists, dashboard content priority, fixed child grids, password toggle touch targets, all modal keyboard layouts and comprehensive visual consistency still require review. Validate every routed screen at 320, 390, 768 and 1280 logical pixels, at 200% text scale, with keyboard and screen reader. Exercise loading, empty, stale-data, network error and successful mutation states with isolated test accounts. Verify real device pairing and safety workflows without changing policy behavior. Do not infer backend/device correctness from widget tests.

## Main screen direction
The family map (/) now follows a destination-first interaction inspired by Rapido: a prominent child selector opens a searchable sheet; permitted quick actions follow; then the map, route control, selected-child status, and family list. The screen keeps its own brand and parenting language rather than ride-booking labels. Child selection, permissions, location lookup, routing, and device pairing use the existing services and routes. Empty-state entry goes to add-child or pairing according to account permission. The compact-phone widget test covers search and selection.

