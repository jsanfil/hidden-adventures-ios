# iOS Setup

## Recommended Local Workflow

1. Regenerate the Xcode project with `xcodegen generate` when `project.yml` changes.
2. Use the sibling `hidden-adventures-server` repo for local backend work.
3. Use live server mode for normal development and reserve fixture-preview mode for the UI harness and deterministic screenshots.
4. Point the app at the local Slice 1 backend with `HA_API_BASE_URL` when needed. The default is `http://127.0.0.1:3000/api`.
5. Use `HA_SERVER_MODE=dev_test` for the local-identity workflow or `HA_SERVER_MODE=production` for Cognito-style auth.
6. Provide `HA_TEST_AUTH_TOKEN` to override the dev/test bearer token, or `HA_AUTH_TOKEN` for production. The local default is `local:connected_viewer`.
7. Use `HA_TEST_AUTH_TOKEN=local:new_user` when you want to step through bootstrap and handle selection against the seeded local identity.

## Runtime Modes

- live server mode:
  - default when `UITEST_START_SCREEN` is not present
  - uses the locked Slice 1 routes for auth bootstrap, handle selection, feed, detail, and profile
  - infers `dev_test` server auth mode automatically for `localhost` and `127.0.0.1`
- fixture preview mode:
  - automatic for the UI-gallery and walkthrough harness
  - can be forced with `HA_RUNTIME_MODE=fixture`
  - keeps deterministic viewer identity, map cards, and media for screenshots

## Current Explicit Fallbacks

- profile setup only persists the public handle in live Slice 1 because no broader profile-write contract is locked yet
- adventure media remains a visible placeholder in live mode until a locked media-delivery route lands
- map explore uses feed-derived cards in live mode because no locked map endpoint exists yet

## Local Development Expectations

- the server should be runnable on the laptop
- the app should be testable without cloud deploys
- release slices should be validated locally before staging
- the UI harness should remain part of the acceptance path while moving from fixtures to real APIs
