# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Entries below 1.0 are reconstructed from git history and are dated by commit.

## [Unreleased]

### Changed

- **License changed from MIT to
  [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/).** The project
  stays free to use, modify, and share for noncommercial purposes with
  attribution; selling it, or shipping a derivative as a commercial product, is
  no longer permitted. Copies obtained under the previous MIT `LICENSE` remain
  MIT-licensed — relicensing is not retroactive.

### Added

- fastlane automation with no App Store Connect dependency: `test`,
  `unit_tests`, `ui_tests`, `screenshots`, `marketing`, `prepare_simulators`,
  and `ci` lanes.
- `prepare_simulators` lane, which creates any missing marketing simulator so
  screenshot capture is reproducible on a fresh machine or CI runner.
- GitHub Actions: `ci.yml` (build and test on push and pull request) and
  `screenshots.yml` (marketing assets on demand or on a `v*` tag).
- `Marketing/copy.json` as the single source of truth for screenshot captions,
  palettes, and device targets.
- README artwork generation — `docs/assets/hero.png`, `feature-01..04.png`, and
  `app-icon.png` — produced by the same renderer as the App Store assets.
- Documentation suite: `docs/ARCHITECTURE.md`, `docs/TESTING.md`,
  `docs/SCREENSHOTS.md`, `docs/CI.md`, `docs/APP_STORE.md`, `docs/PRIVACY.md`,
  plus `CONTRIBUTING.md`, `CHANGELOG.md`, and a `LICENSE`.
- App Store listing copy, which previously existed nowhere in the repository.
- `AccentColor` colour set, resolving a build warning from
  `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME`.

### Changed

- Screenshots are now captured by `fastlane snapshot` across three simulators
  (iPhone 16 Pro Max, iPhone 11 Pro Max, iPad Pro 13-inch) instead of a single
  manual Xcode run, with the status bar pinned to 9:41 and the dark appearance
  forced so successive runs are identical.
- Each App Store size now renders from a natively-sized capture rather than an
  upscaled iPhone screenshot. The iPad previews show real iPad UI for the first
  time.
- iPad preview layout sizes its inset to the available height, so a 4:3 capture
  no longer leaves the lower third of the frame empty.
- `README.md` rewritten from a single line into a full project page.
- Privacy policy now has a Markdown source; previously only a PDF existed, with
  no script to regenerate it.

### Fixed

- `Scripts/generate_appstore_assets.swift` no longer falls back to a hardcoded
  `/Users/jc/Downloads` path when captures are missing. It reports every path it
  tried and exits non-zero.
- The generated `AppStoreAssets/README.md` no longer hardcodes the date
  `2026-06-30` or an absolute `/Users/jc/Dev/Tapper` path.
- Generator failures print a readable message instead of a Swift stack dump.

## [1.0] — 2024-01-13

### Added

- Initial release: create, count, reset, and delete named counters.
- Per-counter colour, custom increment, and optional negative values.
- SwiftData persistence with a `NavigationStack` and typed routes.
- Siri and Shortcuts support via App Intents.
- Universal iPhone and iPad layout.

[Unreleased]: https://github.com/JCTec/Tapper/compare/main...HEAD
