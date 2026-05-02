# Hidden Adventures iOS Workflow Policy

This file is the authoritative workflow override for AI coding agents working in this repository.

Use [Agent.md](/Users/josephsanfilippo/Documents/projects/hidden-adventures-rebuild/hidden-adventures-ios/Agent.md) for repo architecture, runtime, and testing guidance. Use this file for workflow-routing decisions.

## Default Path

For simple and medium repo-local work, default to:

1. ground in the repo
2. classify the task
3. use the lightweight path unless a heavyweight trigger is present

`ground + do` is the default for normal bugfixes, enhancements, and straightforward feature slices.

## Lightweight Path

Use lightweight inline execution when all of these are true:

- work is repo-local
- accepted product or design direction already exists
- no migration, schema, or public contract redesign is needed
- no major ambiguity requires design exploration
- the work is a bugfix, enhancement, or small/medium feature slice

Behavior:

- inspect the relevant code and docs first
- state assumptions briefly
- implement inline
- run targeted verification

Do not automatically invoke brainstorming, design-doc workflows, plan-doc workflows, or subagent-heavy execution for this path.

## Concise Inline Plan

Use a short in-chat plan when the work is moderately complex but still local and clear.

Behavior:

- ground in the repo
- write a brief inline execution plan
- implement directly in this session

This is still part of the lightweight path. It is not full Superpowers mode.

## Heavyweight Process Gate

Heavyweight process means any of:

- `superpowers:brainstorming`
- `superpowers:writing-plans`
- `superpowers:subagent-driven-development`
- formal design-doc workflow
- formal implementation-plan-doc workflow

If the task appears to need heavyweight process, pause and ask the user before entering it.

Use this exact prompt:

```text
This looks like it may need the full Superpowers process. Do you want:
1. lightweight inline execution
2. concise inline plan
3. full Superpowers workflow?
```

Do not proceed into option 3 without explicit user approval.

## Heavyweight Triggers

Prompt before full Superpowers workflow when any of these are true:

- cross-repo work or cross-repo coordination is required
- migrations, schemas, or public contracts need redesign
- product, UX, or architecture decisions are materially ambiguous
- the feature spans multiple systems or large parts of the app
- the user explicitly asks for a design doc, formal implementation plan, or subagent execution

## Start-From-Master-Plan Rule

`start-from-master-plan` may be used to choose the next slice, but it must not automatically trigger full Superpowers workflow.

After the next slice is identified:

- use lightweight inline execution for small accepted-design work
- use a concise inline plan for moderate but clear work
- ask the user before invoking heavyweight Superpowers process

## Preference

For this repo, ask every time before escalating into full Superpowers mode. Do not silently treat prior approval as a standing preference for future tasks.
