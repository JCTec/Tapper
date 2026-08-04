# Testing

Tapper has three test bundles' worth of coverage split across two targets. All
of them run on the simulator and need no signing.

## Running tests

```sh
bundle exec fastlane test         # everything except the screenshot run
bundle exec fastlane unit_tests   # TapperTests only
bundle exec fastlane ui_tests     # TapperUITests, minus screenshots
```

Results land in `fastlane/test_output/` as a JUnit report plus an `.xcresult`
bundle. Both are gitignored and both are uploaded as CI artifacts.

The lanes pick a simulator automatically — the first of `iPhone 17`,
`iPhone 16`, `iPhone 16 Pro`, `iPhone 15` that exists, otherwise any available
iPhone. Override it when you need a specific one:

```sh
TEST_DEVICE="iPhone 16 Pro Max" bundle exec fastlane test
```

`fastlane test` deliberately skips `AppStoreScreenshotUITests`: it is a
marketing asset generator, not an assertion of correctness, and running it on
every PR would triple CI time. See [SCREENSHOTS.md](SCREENSHOTS.md).

## What's covered

### `TapperTests/TapperTests.swift` — unit

Exercises the rules on the `Tapper` model directly, with no UI:

- `augmentValue()` adds the step; `reduceValue()` subtracts it.
- A zero or negative `sumatory` is refused by both, so a malformed step cannot
  corrupt a count.
- `reduceValue()` refuses to go below zero unless `allowsNegativeValue` is set.
- `resetValue()` returns the count to zero.

The class is annotated `@MainActor` because SwiftData model access is
main-actor bound.

### `TapperUITests/` — UI

| File | Purpose |
| --- | --- |
| `TapperUITests.swift` | End-to-end: create a counter, count it, reset it, delete it |
| `TapperUITestsLaunchTests.swift` | Launch screenshot for every configuration |
| `AppStoreScreenshotUITests.swift` | Marketing captures — see [SCREENSHOTS.md](SCREENSHOTS.md) |

`SnapshotHelper.swift` also lives in this target. It is vendored verbatim from
the fastlane gem; do not edit it by hand. Refresh it with:

```sh
cp "$(bundle show fastlane)/snapshot/lib/assets/SnapshotHelper.swift" TapperUITests/
```

## Launch arguments

The app reads two launch arguments in `TapperApp.swift`, and they are the reason
the UI tests are deterministic:

| Argument | Effect |
| --- | --- |
| `-UITesting` | Builds the `ModelContainer` with `isStoredInMemoryOnly: true` |
| `-ShowcaseData` | Same in-memory store, plus seeds three demo counters |

Because both swap in an in-memory store, tests can never see or damage real
data, and every run starts from a known state.

`-ShowcaseData` seeds the counters used in marketing screenshots, via
`TappersListView.seedShowcaseDataIfNeeded()`:

| Name | Colour | Value |
| --- | --- | --- |
| Push-ups | `ffd84d` | 6 |
| Sit-ups | `ef4538` | 15 |
| Squats | `62c866` | 2 |

Changing those values changes the screenshots, so treat them as marketing
assets rather than test fixtures.

## Accessibility identifiers

Views carry stable accessibility identifiers, which serve double duty as the UI
test API and as real accessibility support. Prefer querying these over labels
or index paths — labels are user-facing copy and will change.

| Identifier | Element |
| --- | --- |
| `addTapperButton` | Adds a counter from the list |
| `saveTapperButton` | Commits the create/edit form |
| `openTapper-<name>` | Opens a specific counter from the grid |
| `increment-<name>` / `decrement-<name>` | Inline grid-cell controls |
| `fullTapperName` / `fullCounterValue` | Labels on the full-screen counter |
| `closeTapperButton` | Dismisses the full-screen counter |
| `resetTapperButton` / `editTapperButton` | Full-screen counter actions |
| `colorPreset-<name>` | A colour swatch in the edit form |

When you add a control that a test or a screenshot needs, give it an identifier
in the same style rather than reaching for a label match.

## Previews

`TappersListView+PreviewContainer.swift` builds an in-memory `ModelContainer`
with sample data so `#Preview` blocks work without touching the real store.
Reuse it rather than constructing a container inline.
