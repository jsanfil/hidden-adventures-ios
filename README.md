# Hidden Adventures iOS

SwiftUI iOS client for the Hidden Adventures rebuild.

## Repo Intent

- keep this repo focused on mobile app implementation
- use Xcode as the primary IDE
- link global roadmap and release context back to `hidden-adventures-plan`

## Current State

- the repo contains a native Slice 1 shell for welcome, profile setup, unified explore feed and map, and adventure detail
- the repo includes a deterministic UI-gallery and walkthrough harness under `UITests`
- the default app runtime now targets the locked Slice 1 server contracts for auth bootstrap, handle selection, profile write, feed, adventure detail, and profile
- live feed cards now load a single authenticated image from `primaryMedia.id` through `GET /api/media/:id`
- live adventure detail now loads ordered media refs from `GET /api/adventures/:id/media` and renders them as a carousel through `GET /api/media/:id`
- the UI-gallery and walkthrough harness still run in explicit fixture-preview mode so screenshots and acceptance captures remain deterministic
- the app now has explicit live server modes for `LocalManualQA`, `LocalAutomation`, and `Production`
- manual QA and production now support a native email-code auth flow backed by Cognito, while local automation still accepts deterministic bearer-token injection
- remaining temporary fallbacks are explicit in the UI:
  - map explore in live mode derives cards from the real feed because no locked map endpoint exists yet

## Local Workflow

1. Run `xcodegen generate` after changing `project.yml`.
2. Open `HiddenAdventures.xcodeproj` in Xcode.
3. Use the sibling `hidden-adventures-server` repo as the local backend target.
4. Pick an explicit app scheme:
   - `HiddenAdventures-LocalManualQA` for local server plus real non-prod Cognito and S3
   - `HiddenAdventures-LocalAutomation` for local server plus deterministic test JWT auth
   - `HiddenAdventures-Production` for production configuration
5. Keep the UI harness green while integrating real network clients.

## Runtime Configuration

- `HA_RUNTIME_MODE=live` runs the app against the server-backed Slice 1 clients. This is the default outside UI tests.
- `HA_RUNTIME_MODE=fixture` forces explicit fixture-preview mode for screenshots, previews, and deterministic walkthrough coverage.
- `HA_SERVER_MODE=local_manual_qa` targets the local server in Cognito-backed manual-QA mode.
- `HA_SERVER_MODE=local_automation` targets the local server in deterministic test-JWT mode. This is inferred automatically for `localhost` and `127.0.0.1` API hosts.
- `HA_SERVER_MODE=production` expects production-style bearer auth.
- `HA_API_BASE_URL` overrides the backend base URL. The default is `http://127.0.0.1:3000/api`.
- `HA_COGNITO_REGION` configures the Cognito region for native email-code auth.
- `HA_COGNITO_CLIENT_ID` configures the Cognito app client ID for native email-code auth.
- `HA_TEST_AUTH_TOKEN` supplies a deterministic automation bearer token when `HA_SERVER_MODE=local_automation`.
- `HA_AUTH_TOKEN` supplies the bearer token for `LocalManualQA` and `Production`.
- The app no longer injects a default local token. Manual QA should use real Cognito-backed sign-in, or an explicit token override for troubleshooting.
- Cognito manual-QA sign-up has a known delivery constraint in the current non-prod pool: once a specific email address has already been used for sign-up confirmation testing, deleting and recreating the Cognito user may still fail to send a new confirmation email to that same address. For reliable `Get Started` QA, use a brand-new email address that has not previously been used in this pool.
- Gmail delivery can also block confirmation codes from the Cognito sender address `no-reply@verificationemail.com`, so a missing code in Gmail does not necessarily mean Cognito failed to send it.
- S3 bucket keys remain server-internal; the app should treat media IDs as the contract and should never build image URLs from `storageKey`.

## Acceptance Path

1. Run the simulator build.
2. Run `Scripts/run_ui_gallery.sh`.
3. Validate the local automation happy path against `HiddenAdventures-LocalAutomation`.
4. Validate the manual QA path against `HiddenAdventures-LocalManualQA` and the sibling server's `local-manual-qa` mode with native email-code auth or an explicit troubleshooting token.
5. For manual QA of `Get Started`, prefer a fresh email address that has never been used in the non-prod Cognito pool if confirmation delivery does not arrive after recreating a deleted user.

## Suggested App Structure

- `App/`: app entrypoint and root composition
- `Packages/`: local Swift packages or extracted modules
- `Docs/`: repo-local architecture and implementation notes
- `Resources/`: shared non-generated assets
- `project.yml`: source of truth for the generated Xcode project

## Program Context

The global roadmap, workstreams, release slices, and acceptance criteria live in the `hidden-adventures-plan` repo.
