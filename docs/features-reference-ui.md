# Features reference UI

The Features screen watches the existing Riverpod session provider. Its primary cards retain all previous permission conditions and destinations, including the `/family-map` alias. All existing ParentFeature record modules remain available in a separate More features grid using the original view/create/export rules. Presentation-only widget components live in `widgets/feature_hub_widgets.dart`.

The responsive grid uses one to three columns based on available pane width and text scaling. Rows size to their content. The existing family/child illustrations are reused, and decorative imagery is excluded from accessibility semantics.

## Generated artwork

Built-in imagegen output is saved as `assets/illustrations/features_artwork.png`. The widget draws the correct quadrant without modifying the source image. The QR-like pattern is decorative; tapping the pairing card opens the existing pairing workflow.

Prompt: "Create one square transparent PNG illustration sheet with exactly four equal square quadrants, a strict 2 by 2 grid, no gutters and no visible dividers. Each illustration stays entirely inside its own quadrant with generous transparent padding around it; no overlap between cells. Unified polished friendly 3D mobile family safety app aesthetic, soft studio lighting, no words or labels. TOP LEFT: a dark blue tablet and a pale blue smartphone leaning together. TOP RIGHT: a hand holding a smartphone with a simple decorative QR-like pattern on its screen and mint green scanning corners. BOTTOM LEFT: a tiny isometric pastel green neighborhood map with a winding blue path and an orange location pin, soft blue trees. BOTTOM RIGHT: a glossy red emergency siren with red light rays on a small dark red base, plain dome without lettering. These are decorative UI illustrations, not functional QR codes. Transparent background throughout all four cells."

## Checks

`test/features_reference_test.dart` covers phone/tablet/landscape layouts, 3x text, navigation for every granted card, report export access, hidden payment access, and no-grants state. The rendered preview is a widget render; physical-device rendering is a separate acceptance check.
