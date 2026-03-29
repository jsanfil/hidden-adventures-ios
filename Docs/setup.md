# iOS Setup

## Recommended Local Workflow

1. Regenerate the Xcode project with `xcodegen generate` when `project.yml` changes.
2. Use the sibling `hidden-adventures-server` repo for local backend work.
3. Treat the current app shell as fixture-backed until the real Slice 1 integration lands.
4. Point the app at local server URLs during development once network services are wired.
5. Keep Cognito and S3 configured through environment-specific app settings when auth integration begins.

## Local Development Expectations

- the server should be runnable on the laptop
- the app should be testable without cloud deploys
- release slices should be validated locally before staging
- the UI harness should remain part of the acceptance path while moving from fixtures to real APIs
