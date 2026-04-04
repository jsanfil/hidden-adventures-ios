# iOS Architecture Notes

## Direction

- SwiftUI-first
- feature-oriented modules
- async and await for effects
- explicit design system and token layer
- server-driven data with clean view models

## Current State

- the current app shell covers the Slice 1 happy path for welcome, profile setup, explore, and detail
- the default runtime now composes real server-backed clients for auth bootstrap, handle selection, profile write, feed, detail, and profile
- the live runtime now distinguishes `LocalManualQA`, `LocalAutomation`, and `Production` server modes
- manual QA and production now use a native Cognito email-code auth path with persisted local session state
- fixture preview remains a deliberate runtime mode for deterministic screenshots and walkthrough captures
- the UI harness is already part of the accepted debugging and review surface

## Immediate Priority

- keep local server validation healthy for auth bootstrap, profile write, feed, detail, and profile
- keep explicit Xcode scheme switching healthy so manual QA and automation are easy to select
- preserve the current direct-launch and walkthrough UI-test coverage while integrating real data
- remove explicit temporary fallbacks only when the corresponding server contracts are locked

## Guardrails

- avoid rebuilding the legacy storyboard or tab structure directly
- keep repo-local notes here and global program notes in `hidden-adventures-plan`
- do not silently introduce fallback contract assumptions that are not documented in the program plan
- do not add `viewerHandle`, map endpoints, or media-delivery behavior that are not part of the locked Slice 1 contract
