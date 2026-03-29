# iOS Architecture Notes

## Direction

- SwiftUI-first
- feature-oriented modules
- async and await for effects
- explicit design system and token layer
- server-driven data with clean view models

## Current State

- the current app shell covers the Slice 1 happy path for welcome, profile setup, explore, and detail
- the current service layer is still fixture-backed
- the current viewer identity is still fixture-backed
- the UI harness is already part of the accepted debugging and review surface

## Immediate Priority

- replace fixture-backed services with real network clients
- wire auth bootstrap and handle selection into the app shell
- preserve the current direct-launch and walkthrough UI-test coverage while integrating real data

## Guardrails

- avoid rebuilding the legacy storyboard or tab structure directly
- keep repo-local notes here and global program notes in `hidden-adventures-plan`
- do not silently introduce fallback contract assumptions that are not documented in the program plan
