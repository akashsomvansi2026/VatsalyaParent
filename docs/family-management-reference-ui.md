# Family management reference UI

The Children/Devices screen uses the existing Riverpod session and workspace repository. The reference layout is implemented through presentation widgets in `widgets/family_management_widgets.dart`: a family hero with actual count/account name, rounded search, illustrated empty/no-match states, orange creation actions and wrapping record cards. Existing family artwork is reused; the empty illustration uses Flutter shapes/icons.

Both Children and Devices modes retain their original permission checks, APIs, mutations, profile/device menus, supervision routes and pairing actions. Child creation continues to use the existing download-first sequence and saved-child pairing retry. Creation controls remain hidden for read-only accounts. The search-clear state is distinct from a genuinely empty list, and failed loading retains an error/retry view rather than showing an empty result.

Content is centered within a 960px maximum pane. Compact widths, landscape and enlarged text use natural-height layouts and bounded artwork; the search controller is disposed with the screen. The back action returns to the existing navigation stack, with Features as the root-route fallback.

`test/family_management_reference_test.dart` exercises Children and Devices at 390px, 320px with 3x text, landscape and desktop/tablet width, including refresh, search, clearing, error recovery, child supervision navigation and read-only access. Existing family/download tests cover creation and pairing retry without duplicate child creation. Widget previews do not replace device/API acceptance checks.
