# Hidden Adventures iOS

SwiftUI iOS client for the Hidden Adventures rebuild.

## Repo Intent

- keep this repo focused on mobile app implementation
- use Xcode as the primary IDE
- link global roadmap and release context back to `hidden-adventures-plan`

## Current State

- the repo contains a native Slice 1 shell for welcome, profile setup, unified explore feed and map, and adventure detail
- the repo includes a deterministic UI-gallery and walkthrough harness under `UITests`
- the default app runtime now targets the locked Slice 1 server contracts for auth bootstrap, handle selection, feed, adventure detail, and profile
- the UI-gallery and walkthrough harness still run in explicit fixture-preview mode so screenshots and acceptance captures remain deterministic
- temporary fallbacks are explicit in the UI:
  - live Slice 1 profile setup only reserves the public handle until a profile-write contract lands
  - live media cards use a documented placeholder until a locked media-delivery route lands
  - map explore in live mode derives cards from the real feed because no locked map endpoint exists yet

## Local Workflow

1. Run `xcodegen generate` after changing `project.yml`.
2. Open `HiddenAdventures.xcodeproj` in Xcode.
3. Use the sibling `hidden-adventures-server` repo as the local backend target.
4. Keep the UI harness green while integrating real network clients.

## Runtime Configuration

- `HA_RUNTIME_MODE=live` runs the app against the server-backed Slice 1 clients. This is the default outside UI tests.
- `HA_RUNTIME_MODE=fixture` forces explicit fixture-preview mode for screenshots, previews, and deterministic walkthrough coverage.
- `HA_SERVER_MODE=dev_test` uses the server's local-identity workflow. This is inferred automatically for `localhost` and `127.0.0.1` API hosts.
- `HA_SERVER_MODE=production` expects production-style bearer auth.
- `HA_API_BASE_URL` overrides the backend base URL. The default is `http://127.0.0.1:3000/api`.
- `HA_TEST_AUTH_TOKEN` overrides the dev/test bearer token. The default local token is `local:connected_viewer`.
- Use `HA_TEST_AUTH_TOKEN=local:new_user` when you want to exercise the bootstrap and handle-selection flow explicitly.
- `HA_AUTH_TOKEN` supplies the production bearer token and is also accepted as an explicit override in dev/test mode.

## Acceptance Path

1. Run the simulator build.
2. Run `Scripts/run_ui_gallery.sh`.
3. Validate the local happy path against the live server for auth bootstrap, feed, detail, and profile when a valid auth token is available.

## Suggested App Structure

- `App/`: app entrypoint and root composition
- `Packages/`: local Swift packages or extracted modules
- `Docs/`: repo-local architecture and implementation notes
- `Resources/`: shared non-generated assets
- `project.yml`: source of truth for the generated Xcode project

## Program Context

The global roadmap, workstreams, release slices, and acceptance criteria live in the `hidden-adventures-plan` repo.
