# Hidden Adventures iOS Agent Guide

This repository is the SwiftUI iOS client for the Hidden Adventures rebuild. Use this file as the quick-start operating guide for AI coding agents working in this repo.

## Repo Boundaries

- Keep this repo focused on the native iOS app.
- Keep repo-local implementation notes in `Docs/`.
- Treat the sibling `hidden-adventures-plan` repo as the source of truth for the broader roadmap, release slices, and cross-repo acceptance criteria.
- Local backend work depends on the sibling `hidden-adventures-server` repo.

## Architecture Direction

- SwiftUI-first app architecture.
- Feature-oriented code under `App/Features/`.
- Async and await for effects.
- Explicit design system and token layer under `App/DesignSystem/`.
- Server-driven data mapped into app-facing models instead of exposing backend DTOs directly to SwiftUI.

## Repo Landmarks

- `project.yml`: source of truth for the generated Xcode project
- `App/`: app code
- `Tests/`: unit tests
- `UITests/`: UI tests, screen harnesses, and regression coverage
- `Resources/`: shared assets
- `Docs/`: repo-local setup, architecture, QA, and implementation notes

## Core Workflow

- Run `xcodegen generate` after editing `project.yml`.
- Use Xcode with `HiddenAdventures.xcodeproj` for normal development.
- Prefer live runtime mode for normal app work.
- Reserve fixture mode for deterministic previews, screenshots, UI gallery runs, and walkthrough coverage.
- Use explicit schemes instead of hand-editing runtime assumptions:
  - `HiddenAdventures-LocalManualQA`
  - `HiddenAdventures-LocalAutomation`
  - `HiddenAdventures-Production`

## Runtime Guardrails

- Preserve the locked Slice 1 contracts for auth bootstrap, handle selection, profile write, feed, adventure detail, profile, detail media, and authenticated media delivery.
- Do not silently invent fallback behavior or undocumented contract assumptions.
- Do not add `viewerHandle`, direct-S3 client behavior, or unapproved map endpoints.
- Keep the current live-mode map fallback explicit: map explore derives cards from the feed until a real locked map endpoint exists.
- Treat media IDs as the contract. Do not construct client image URLs from storage keys.

## Contribution Expectations

- Keep the UI harness and walkthrough coverage healthy while changing app behavior.
- When touching UI, preserve deterministic fixture coverage and stable `accessibilityIdentifier` usage where tests depend on it.
- For UI-facing work, default acceptance is:
  1. simulator build
  2. targeted tests
  3. `Scripts/run_ui_gallery.sh` when the change affects screens, flows, or layout
- For focused screen work, use `Scripts/run_ui_screen_tests.sh` before broader gallery coverage.
- Follow the existing mock-first, then live-hookup pattern for screen work.

## Preferred References

- Read `README.md` for the current repo state, schemes, runtime modes, and acceptance path.
- Read `Docs/setup.md` for local environment and backend wiring details.
- Read `Docs/architecture.md` for app direction and contract guardrails.
- Read `Docs/v0-screen-porting-workflow.md` before porting or refining screens from `v0-hidden-adventures-ui`.
- Read `Docs/manual-qa-results.md` when a task depends on prior manual QA evidence.

## Working Style

- Keep changes aligned with the existing feature-first structure.
- Prefer small focused changes over broad reshuffles unless a task explicitly calls for refactoring.
- Avoid duplicating setup or architecture guidance across docs; link back to the canonical repo docs instead.
- If a server contract is unclear, stop and confirm it in the plan/docs rather than guessing in code.
