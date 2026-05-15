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
- After a successful build, update DocC output before finalizing documentation changes:

```bash
swift package dump-symbol-graph --minimum-access-level public
rm -rf .build/docc-symbolgraphs
mkdir -p .build/docc-symbolgraphs
find .build -path '*/symbolgraph/LaunchingView*.symbols.json' \
  ! -name 'LaunchingViewPackageTests.symbols.json' \
  -exec cp {} .build/docc-symbolgraphs/ \;
xcrun docc convert Sources/LaunchingView/LaunchingView.docc \
  --additional-symbol-graph-dir .build/docc-symbolgraphs \
  --fallback-display-name LaunchingView \
  --fallback-bundle-identifier com.swift-man.LaunchingView \
  --fallback-bundle-version 0.8.3 \
  --output-path LaunchingView.doccarchive
./GeneratingDocumentationSite
```

- `./GeneratingDocumentationSite` transforms the temporary `LaunchingView.doccarchive/` into `docs/` and removes the archive afterward.
- Commit generated DocC changes under `docs/` only. Do not commit `LaunchingView.doccarchive/`.

## Pull Request Review Handling

- Inspect PR review comments and review threads before finalizing a PR.
- For each review item, identify whether it is fixed, intentionally left unchanged, obsolete, or a hallucination.
- Reply to the relevant review thread when one exists.
- If there are no inline review threads, add a top-level PR comment summarizing the review state and the changes made.
- Do not mark a review item as resolved unless the code, tests, or documentation clearly support that conclusion.
