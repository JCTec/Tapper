# Architecture

Tapper is a single-target SwiftUI app with no view frameworks, no dependency
injection container, and one third-party package. The whole app is roughly
1,700 lines of Swift. This document explains how the pieces fit together and,
where it matters, why.

The conventions here are an application of
[APP_DEVELOPMENT_STYLE.md](../APP_DEVELOPMENT_STYLE.md).

## Stack

| Concern | Choice |
| --- | --- |
| UI | SwiftUI, iOS 17.0+ |
| Persistence | SwiftData (`@Model`, `@Query`, `ModelContext`) |
| Navigation | `NavigationStack` driven by a typed route enum |
| Dependencies | [ColorKit](https://github.com/Boris-Em/ColorKit) only |
| System integration | App Intents / App Shortcuts |
| Device family | Universal — iPhone and iPad (`TARGETED_DEVICE_FAMILY = 1,2`) |

## The model

`Tapper/Tapper.swift` is the entire domain layer: one `@Model` class holding a
counter's identity, its stored settings, and its current value.

```swift
@Model final class Tapper {
  var id: UUID
  var name: String
  var sumatory: Int            // the increment step
  var allowsNegativeValue: Bool
  var backgroundColorHex: String
  var counterValue: Int
}
```

Business rules live on the model rather than in views, which is what makes them
unit-testable without a UI:

- `augmentValue()` — no-ops when `sumatory <= 0`, so a malformed step can never
  corrupt the count.
- `reduceValue()` — gated by `canReduceValue`, which requires a positive step
  and either `allowsNegativeValue` or a result that stays at or above zero.
- `resetValue()` — sets the count back to zero.

### Derived colour

Everything visual is computed from `backgroundColorHex`, so only one value is
persisted:

- `backgroundUIColor` parses the hex through ColorKit's `UIColor(hex:)`, falling
  back to the default white if parsing fails.
- `textColor` asks ColorKit for the contrast ratio against `.dark` and returns
  `.dark` when the ratio is `.acceptable` or `.acceptableForLargeText`,
  otherwise `.snowWhite`.

That last property is the reason ColorKit is a dependency at all: it means a
user can pick any colour — including one from the system colour picker — and
the label stays legible without a hand-maintained lookup table.

All four computed properties are marked `@Transient` so SwiftData does not try
to persist them.

## Navigation

`TapperNavigationView.swift` owns the only `NavigationPath` in the app and maps
a `Hashable` enum to destinations:

```swift
enum TapperCoordinator: Hashable {
  case createTapper
  case editTapper(Tapper)
  case viewTapper(Tapper)
}
```

Views receive `path` as a `@Binding` and push routes onto it. There is no
router object and no coordinator class — the enum plus `navigationDestination`
is the whole mechanism. Adding a screen means adding a case, and the compiler
finds every place that needs updating.

## Feature layout

Each screen gets a folder under `Tapper/Features/`. The root SwiftUI view is
also the namespace for everything the feature owns. Supporting types live in
`extension Feature { … }` blocks, one per `Feature+Name.swift` file, rather
than in a shared `Views/` dump:

| File | Holds |
| --- | --- |
| `Feature.swift` | The root view only: stored state, `body`, the main actions, and `#Preview` |
| `Feature+ViewModel.swift` | `extension Feature { @Observable final class ViewModel }`, when the screen needs one |
| `Feature+Helpers.swift` | Computed values and secondary functions that support the view |
| `Feature+InnerView.swift` | A nested `struct InnerView: View`, one per file |
| `Feature+Name.swift` | Any other nested type (enums, value types) |

Naming things inside the feature keeps them short. The view model is just
`ViewModel` inside the feature and `EditTapperView.ViewModel` from outside, for
example in tests. Inner views are `struct TopView: View`, never
`var topView: some View`. They receive only what they need: plain values,
`@Binding`s, `@Bindable var viewModel`, or action closures such as
`onReset: () -> Void`. A nested view that grows its own subviews moves into a
subfolder inside the feature, and its file names drop the parent's prefix. For
example, `TappersListView.SmallTapperView` lives in
`TappersListView/SmallTapperView/`, with `SmallTapperView+TitleView.swift`
alongside it.

```
Features/
├── TappersListView/
│   ├── TappersListView.swift                         root: state, body, addTapper
│   ├── TappersListView+Helpers.swift                 filtering/sorting, layout, showcase seeding
│   ├── TappersListView+SortMode.swift
│   ├── TappersListView+TitleView.swift
│   ├── TappersListView+ControlsView.swift            sort menu + search
│   ├── TappersListView+SearchView.swift
│   ├── TappersListView+ContentView.swift             empty/no-match states and the grid
│   ├── TappersListView+PreviewContainer.swift        in-memory container for #Preview
│   └── SmallTapperView/                              grid card (TappersListView.SmallTapperView)
│       ├── SmallTapperView.swift
│       ├── SmallTapperView+TitleView.swift
│       ├── SmallTapperView+ActionView.swift
│       └── SmallTapperView+ActionButton.swift
├── TapperView/
│   ├── TapperView.swift                              root: state, body, counter actions
│   ├── TapperView+Helpers.swift                      counter feedback (haptic + pulse)
│   ├── TapperView+TopView.swift                      close / reset / edit
│   ├── TapperView+BottomView.swift                   counter, labels, +/−
│   └── TapperView+ActionButton.swift
└── EditTapperView/
    ├── EditTapperView.swift                          root: form, toolbar, dialogs, save/delete
    ├── EditTapperView+ViewModel.swift                draft state, validation, persistence
    ├── EditTapperView+Validation.swift               ValidationError, ValidatedValues
    ├── EditTapperView+ColorPreset.swift
    ├── EditTapperView+Helpers.swift
    ├── EditTapperView+PreviewCard.swift
    ├── EditTapperView+NameSection.swift
    ├── EditTapperView+IncrementSection.swift
    ├── EditTapperView+CounterValueSection.swift
    ├── EditTapperView+BackgroundColorSection.swift
    └── EditTapperView+DeleteSection.swift
```

UI shared across features lives in `Tapper/Components/`, for example
`PressButtonStyle`.

`EditTapperView` is the only screen with a view model, because it is the only
one with state that outlives a single view update (draft values plus
validation). Everywhere else, `@Query` and the model are enough. This is
deliberate: MVVM is applied where it earns its keep, not uniformly. View models
use the Observation framework (`@Observable`), and the view owns them with
`@State`.

## Design tokens

`Tapper/Utilities/` holds three token enums, each extended onto `CGFloat` so
call sites read naturally:

| File | Tokens |
| --- | --- |
| `Spacing.swift` | `small: 8`, `medium: 16`, `large: 24`, `xLarge: 32`, plus `baseline` |
| `Borders.swift` | `CornerRadius` (4 / 6 / 8), `BorderWidth` (1 / 2 / 4) |
| `IconSize.swift` | `small: 16` through `xxLarge: 96` |

Usage looks like `.padding(.spacing.medium)` rather than `.padding(16)`. Named
colours come from `Assets.xcassets/Colors/` and are surfaced as typed Swift
symbols (`ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES`),
so `.snowWhite` and `.dark` are compiler-checked.

## The container and launch flags

`TapperApp.swift` builds one `ModelContainer` and chooses its storage based on
launch arguments:

```swift
let usesTemporaryStore = launchArguments.contains("-UITesting")
                      || launchArguments.contains("-ShowcaseData")
let modelConfiguration = ModelConfiguration(schema: schema,
                                            isStoredInMemoryOnly: usesTemporaryStore)
```

This single switch is what makes both UI testing and screenshot generation
deterministic — neither can see or damage real user data. See
[TESTING.md](TESTING.md).

## App Intents

`OpenTapperIntent` (with `openAppWhenRun = true`) and `TapperShortcuts` register
the phrases "Open Tapper" and "Start counting with Tapper", using
`hand.tap.fill` as the shortcut glyph. The intent currently just opens the app;
it is the extension point for per-counter Siri actions later.

## Known rough edges

Worth knowing before you make changes:

- **CloudKit is declared but not wired.** `Tapper.entitlements` names the
  container `iCloud.com.jctec.tapper` and `Info.plist` declares the
  `remote-notification` background mode, but `ModelConfiguration` is built
  without `cloudKitDatabase:`. Nothing syncs today.
- **ColorKit is pinned to a branch.** `Package.resolved` records revision
  `6e4375a` on `master` rather than a version tag, so a forced re-resolve could
  drift. See [CI.md](CI.md).
- **Two colour sets reference macOS system colours.** `DangerColor` and
  `Disable` use `"platform": "osx"` references inside an iOS-only app.
