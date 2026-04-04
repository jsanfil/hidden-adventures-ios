# iOS Setup

## Recommended Local Workflow

1. Regenerate the Xcode project with `xcodegen generate` when `project.yml` changes.
2. Use the sibling `hidden-adventures-server` repo for local backend work.
3. Use live server mode for normal development and reserve fixture-preview mode for the UI harness and deterministic screenshots.
4. Point the app at the local Slice 1 backend with `HA_API_BASE_URL` when needed. The default is `http://127.0.0.1:3000/api`.
5. Use `HiddenAdventures-LocalManualQA` when the sibling server is running `npm run dev:manual-qa`.
6. Use `HiddenAdventures-LocalAutomation` when the sibling server is running `npm run dev:automation`.
7. Use `HiddenAdventures-Production` only for production configuration and release validation.
8. Provide `HA_COGNITO_REGION` and `HA_COGNITO_CLIENT_ID` for native manual-QA and production email-code auth.
9. Provide `HA_TEST_AUTH_TOKEN` for automation mode, or `HA_AUTH_TOKEN` for manual QA and production when you need an explicit bearer-token override.

## Runtime Modes

- live server mode:
  - default when `UITEST_START_SCREEN` is not present
  - uses the locked Slice 1 routes for auth bootstrap, handle selection, feed, detail, and profile
  - infers `local_automation` server mode automatically for `localhost` and `127.0.0.1`
- fixture preview mode:
  - automatic for the UI-gallery and walkthrough harness
  - can be forced with `HA_RUNTIME_MODE=fixture`
  - keeps deterministic viewer identity, map cards, and media for screenshots

## Server Modes

- `local_manual_qa`:
  - expects the sibling server to use real Cognito plus the `hidden_adventures_qa` database
  - uses native email-code auth when Cognito env vars are present
  - uses `HA_AUTH_TOKEN` only when an explicit token is injected into the app runtime
- `local_automation`:
  - expects the sibling server to use deterministic test JWT auth plus the `hidden_adventures_test` database
  - uses `HA_TEST_AUTH_TOKEN` first, then falls back to `HA_AUTH_TOKEN` if provided explicitly
- `production`:
  - expects production base URLs, production Cognito, and production media configuration
  - never assumes a local default token

## Current Explicit Fallbacks

- adventure media remains a visible placeholder in live mode until a locked media-delivery route lands
- map explore uses feed-derived cards in live mode because no locked map endpoint exists yet

## Local Development Expectations

- the server should be runnable on the laptop
- the app should be testable without cloud deploys
- local manual QA and local automation should be selectable by scheme rather than hand-editing env vars
- release slices should be validated locally before any cloud smoke flow
- the UI harness should remain part of the acceptance path while moving from fixtures to real APIs
