# Hidden Adventures iOS

SwiftUI iOS client for the Hidden Adventures rebuild.

## Repo Intent

- keep this repo focused on mobile app implementation
- use Xcode as the primary IDE
- link global roadmap and release context back to `hidden-adventures-plan`

## Current State

- the repo contains a native Slice 1 shell for welcome, profile setup, unified explore feed and map, and adventure detail
- the repo includes a deterministic UI-gallery and walkthrough harness under `UITests`
- the current Slice 1 shell is still fixture-backed for data and viewer identity
- the next milestone is real server and auth bootstrap integration against the sibling `hidden-adventures-server` repo

## Local Workflow

1. Run `xcodegen generate` after changing `project.yml`.
2. Open `HiddenAdventures.xcodeproj` in Xcode.
3. Use the sibling `hidden-adventures-server` repo as the local backend target for the next integration step.
4. Keep the UI harness green while replacing fixture-backed services with real network clients.

## Suggested App Structure

- `App/`: app entrypoint and root composition
- `Packages/`: local Swift packages or extracted modules
- `Docs/`: repo-local architecture and implementation notes
- `Resources/`: shared non-generated assets
- `project.yml`: source of truth for the generated Xcode project

## Program Context

The global roadmap, workstreams, release slices, and acceptance criteria live in the `hidden-adventures-plan` repo.
