# Hidden Adventures iOS

SwiftUI iOS client for the Hidden Adventures rebuild.

## Repo Intent

- keep this repo focused on mobile app implementation
- use Xcode as the primary IDE
- link global roadmap and release context back to `hidden-adventures-plan`

## Bootstrap Status

This repo now includes a minimal SwiftUI app scaffold plus a checked-in `xcodegen` spec.

Local workflow:

1. Run `xcodegen generate` after changing `project.yml`.
2. Open `HiddenAdventures.xcodeproj` in Xcode.
3. Point the app at the sibling `hidden-adventures-server` repo during local development.

## Suggested App Structure

- `App/`: app entrypoint and root composition
- `Packages/`: local Swift packages or extracted modules
- `Docs/`: repo-local architecture and implementation notes
- `Resources/`: shared non-generated assets
- `project.yml`: source of truth for the generated Xcode project

## Program Context

The global roadmap, workstreams, and release slices live in the `hidden-adventures-plan` repo.
