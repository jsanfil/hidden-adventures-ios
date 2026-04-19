# Manual QA Results

Use this file to record manual QA outcomes for plan-based features after implementation.

Keep one entry per feature or slice, and update the notes as verification progresses from in-progress to complete.

## Entry Format

| Date | Plan Feature | Build / Branch | QA Environment | Tested Areas | Result | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| YYYY-MM-DD | Feature or slice name | Commit, branch, or build number | Simulator, local manual QA, production, etc. | Screens, flows, edge cases, regressions | Pass / Partial / Fail | What was observed, bugs found, follow-up items |

## Recommended Notes

- Record the exact feature or slice name from the plan.
- Note the app scheme, backend mode, and any special auth state used during testing.
- Capture the specific screen or user flow that was exercised.
- Call out anything that was blocked, ambiguous, or intentionally deferred.
- Mark the entry complete only when the feature has been manually verified and any required follow-ups are resolved or tracked elsewhere.

## Example Entry

| 2026-04-18 | Slice 1: Adventure Detail media carousel | `codex/qa-log` | `HiddenAdventures-LocalManualQA` on iPhone 16 simulator | Detail screen open, media swipe, retry after offline toggle | Pass | Verified carousel loads, swipes correctly, and recovers after reconnect. No new issues found. |

## Completion Checklist

- The feature name matches the plan item being verified.
- The tested build or commit is recorded.
- The QA environment is clear and reproducible.
- The result is explicit.
- Any follow-up work has a linked issue, note, or owner.
- The entry is easy to scan later when reviewing release readiness.
