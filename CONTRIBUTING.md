# Contributing

Thanks for taking a look. This is a small app with strong conventions — most of
them are written down, so read the two style documents before making changes.

## Setup

```sh
git clone https://github.com/JCTec/Tapper.git
cd Tapper
bundle install          # fastlane and its dependencies
open Tapper.xcodeproj
```

Requires Xcode 16 or newer and macOS. Swift Package Manager resolves
[ColorKit](https://github.com/Boris-Em/ColorKit) on first build.

Verify your setup:

```sh
bundle exec fastlane lanes
bundle exec fastlane test
```

## Conventions

Two documents govern how code here is written:

- **[APP_DEVELOPMENT_STYLE.md](APP_DEVELOPMENT_STYLE.md)** — the app-agnostic
  spec this project is built to: SwiftUI + SwiftData, typed navigation routes,
  design tokens as enums, minimal dependencies, adaptive contrast, haptics
  without sound, accessibility identifiers everywhere.
- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** — how those principles are
  actually realised in this codebase.

Points worth repeating because they are easy to miss:

- **Two-space indentation** in Swift. Match the surrounding file.
- **Design tokens, not magic numbers.** Use `.spacing.medium`,
  `.cornerRadius.large`, `.iconSize.small` from `Tapper/Utilities/`. If you need
  a value that does not exist, add it to the token enum rather than inlining it.
- **Named colours from the asset catalog**, surfaced as typed symbols. Do not
  construct `Color(red:green:blue:)` in a view.
- **Business rules belong on the model.** `Tapper.swift` holds the counting
  rules precisely so they can be unit-tested without a UI. Resist putting
  guards in views.
- **MVVM only where it earns its keep.** `EditTapperView` has a view model
  because it has draft state and validation. Nothing else does.
- **Accessibility identifiers on anything interactive**, following the existing
  naming (`openTapper-<name>`, `saveTapperButton`). They are both the test API
  and real accessibility support.

## Adding a screen

1. Add a case to `TapperCoordinator` in `TapperNavigationView.swift`.
2. Handle it in the `navigationDestination` switch — the compiler will point you
   at what is missing.
3. Put the view in its own folder under `Tapper/Features/`, with helpers
   attached via `+` file naming.
4. Add a `#Preview` using `TappersListView+PreviewContainer.swift`'s in-memory
   container.

## Tests

Add unit tests for anything with a rule in it, and a UI test for anything a user
can complete end to end.

```sh
bundle exec fastlane test
```

See [docs/TESTING.md](docs/TESTING.md) for the launch flags (`-UITesting`,
`-ShowcaseData`) and the accessibility identifier table.

## Generated files — do not edit

These directories are rewritten wholesale by
`Scripts/generate_appstore_assets.swift`. Editing them by hand is always lost:

- `AppStoreAssets/` — App Store uploads
- `docs/assets/` — README artwork
- `AppStoreSimulatorCaptures/` — mirrored raw captures

To change a screenshot caption, gradient, or device, edit
[`Marketing/copy.json`](Marketing/copy.json) and run
`bundle exec fastlane marketing`. See [docs/SCREENSHOTS.md](docs/SCREENSHOTS.md).

`TapperUITests/SnapshotHelper.swift` is vendored verbatim from the fastlane gem.
Do not edit it; re-copy it if it needs updating.

## Pull requests

- Branch off `main`.
- Keep the diff focused — regenerating all 19 marketing assets inside an
  unrelated bug-fix PR makes review hard. If a change genuinely requires new
  screenshots, say so in the description.
- `bundle exec fastlane test` must pass. CI runs the same command.
- Update the docs in the same PR when behaviour changes. `docs/` is expected to
  be accurate, not aspirational.
- Add a `CHANGELOG.md` entry under **Unreleased** for anything user-facing.

## Reporting bugs

Open an issue with the device, iOS version, and steps to reproduce. If it is
visual, a screenshot helps — the counters are colour-sensitive and contrast
issues are much easier to see than to describe.
