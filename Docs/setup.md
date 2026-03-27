# iOS Setup

## Recommended Local Workflow

1. Regenerate the Xcode project with `xcodegen generate` when `project.yml` changes.
2. Use the sibling `hidden-adventures-server` repo for local backend work.
3. Point the app at local server URLs during development.
4. Keep Cognito and S3 configured through environment-specific app settings.

## Local Development Expectations

- the server should be runnable on the laptop
- the app should be testable without cloud deploys
- release slices should be validated locally before staging
