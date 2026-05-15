# AGENTS.md

## Repository Guidelines

- This repository is a Swift Package for `LaunchingView`, a SwiftUI launch/update view built with The Composable Architecture.
- Keep changes small, focused, and consistent with the existing package layout under `Sources/LaunchingView` and `Tests/LaunchingViewTests`.
- Preserve the public API unless the task explicitly asks for a breaking change.
- Follow SOLID design principles. Keep SwiftUI views focused on presentation, keep state transitions in reducers, inject dependencies through `Dependencies`, and prefer behavior that can be tested without live Firebase or App Store calls.
- Do not commit local Xcode user state or generated workspace noise unless it is intentionally shared project configuration.

## Build, Test, and Documentation

- Run `swift build` after code changes.
- Run `swift test` for verification.
- After documentation changes, regenerate the local DocC static site before finalizing:

```bash
./GeneratingDocumentationSite
```

- `./GeneratingDocumentationSite` builds the package, emits symbol graphs, converts `Sources/LaunchingView/LaunchingView.docc`, transforms the archive into static `docs/`, and removes temporary DocC artifacts afterward.
- Do not commit generated DocC output. `docs/` and `LaunchingView.doccarchive/` are local/CI artifacts.
- The `Deploy DocC` GitHub Actions workflow publishes generated documentation to `swift-man/docs` under `LaunchingView/`.
- `swift-man/docs` uses the `docs.gorani.me` custom domain, so DocC static hosting base path should remain `LaunchingView`, not `docs/LaunchingView`.
- Configure `DOCS_DEPLOY_KEY` with a private deploy key in this repository, and add the matching public key with write access to `swift-man/docs`.

## Pull Request Review Handling

- Inspect PR review comments and review threads before finalizing a PR.
- For each review item, identify whether it is fixed, intentionally left unchanged, obsolete, or a hallucination.
- Reply to the relevant review thread when one exists.
- If there are no inline review threads, add a top-level PR comment summarizing the review state and the changes made.
- Do not mark a review item as resolved unless the code, tests, or documentation clearly support that conclusion.
