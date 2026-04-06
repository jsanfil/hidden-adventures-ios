# v0 Screen Porting Workflow

Use this workflow for every remaining screen port from `v0-hidden-adventures-ui` into `hidden-adventures-ios`.

## Goal

Turn each approved v0 screen into a native SwiftUI implementation without skipping the artifacts that reduce ambiguity:

- React screen code for structure and interaction
- supporting React components for local behavior details
- screenshots for visual fidelity
- UX spec notes for intent, semantics, and data requirements

## Canonical Source Repo

- source repo: `../v0-hidden-adventures-ui`

Treat `v0-hidden-adventures-ui` as the canonical visual reference for approved Slice 1 and later screen work unless the plan repo says otherwise.

## Artifact Lookup Pattern

For each screen, gather all four artifact classes before implementing:

1. Primary screen implementation
   - `../v0-hidden-adventures-ui/components/screens/<screen-name>.tsx`
2. Supporting interaction components
   - `../v0-hidden-adventures-ui/components/**/*.tsx`
   - include any carousel, sheet, composer, card, or modal used by the screen
3. Screenshot references
   - `../v0-hidden-adventures-ui/docs/screenhots/<ScreenName>*.png`
   - note the folder name is intentionally `screenhots`
4. UX or design spec
   - `../v0-hidden-adventures-ui/docs/ux-specs/<ScreenName>Design.md`
   - if a screen-specific spec does not exist, use the nearest approved UX note and record that gap in the handoff

## Artifact Precedence

When the artifacts disagree, resolve conflicts in this order:

1. screenshots for visual decisions
2. UX spec for intent, semantics, and expected behavior
3. React code for hierarchy, local state, and conditional rendering

Do not silently invent behavior that conflicts with those sources. If native iOS should diverge for ergonomics or accessibility, record the divergence explicitly in the screen handoff or plan doc.

## Per-Screen Workflow

1. Identify the screen in `v0-hidden-adventures-ui`.
2. Read the primary React screen and list:
   - section ordering
   - local UI state
   - conditional rendering rules
   - interaction expectations
3. Read every supporting React component used for:
   - carousels
   - bottom bars
   - input composers
   - modal or sheet interactions
   - reusable cards or rows that affect layout rhythm
4. Open the screenshot references and lock:
   - spacing
   - overlap behavior
   - corner radii
   - vertical rhythm
   - chip/button density
   - comment or card shape
5. Read the UX spec and lock:
   - section semantics
   - copy intent
   - native handoff expectations such as Maps or Share
   - screen-level data requirements
6. Build the first SwiftUI pass against mock data only.
7. Create a native screen model instead of binding the view directly to server DTOs.
8. Keep the screen available through fixture previews and the UI gallery/debug path.
9. Add stable `accessibilityIdentifier` coverage for visually critical and interactive elements.
10. Compare native screenshots against the v0 screenshots before starting live-data hookup.
11. After visual signoff, add a mapper from live payloads into the native screen model.
12. Keep fixture mode intact after live hookup so parity checks remain fast.

## Native Implementation Rules

- default to a screen-specific model such as `<ScreenName>ScreenModel`
- map server payloads into the screen model later instead of exposing DTOs directly to SwiftUI
- keep fixture-backed previews for:
  - happy path
  - long-text path
  - single-image or no-media path when applicable
  - empty-state path such as no comments or no activity
- prefer small SwiftUI subviews for major sections instead of one giant body
- preserve the `UITEST_START_SCREEN` gallery route whenever the screen already participates in it

## Accessibility Baseline

Every screen port should add stable identifiers for:

- primary navigation controls
- section headers used in regression tests
- hero media or carousels
- title and location labels
- primary CTA or bottom bar controls
- interactive controls such as favorite, share, follow, rating stars, filters, or send actions
- list containers or repeated content areas that are likely to appear in UI tests

## Mock-First Then Live

Use the same two-phase delivery pattern on every screen:

### Phase 1: Mock-data parity

- build SwiftUI against fixtures only
- match v0 layout and interactions
- keep previews and gallery coverage deterministic

### Phase 2: Live-data hookup

- keep the SwiftUI surface driven by the screen model
- add a dedicated mapper from live data into the screen model
- add explicit loading, success, empty, and error states
- rerun fixture screenshots after integration to confirm visual parity did not regress

## Acceptance Checklist

Before marking a screen port done:

1. screen renders in fixture mode
2. required previews exist for the main variants
3. the gallery or direct-launch route still works
4. identifiers exist for critical interactive elements
5. screenshots have been compared against the v0 references
6. any native divergence has been documented explicitly
7. live hookup does not remove fixture coverage

## Handoff Template

For each screen, record:

- primary v0 screen file used
- supporting component files used
- screenshot files used
- UX spec file used
- native model introduced
- fixture variants added
- identifiers added
- native deviations from v0, if any
- visual signoff status
- live-data hookup status
