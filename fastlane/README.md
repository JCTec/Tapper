fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios prepare_simulators

```sh
[bundle exec] fastlane ios prepare_simulators
```

Create any missing marketing simulator so screenshots are reproducible

### ios unit_tests

```sh
[bundle exec] fastlane ios unit_tests
```

Run the TapperTests unit bundle

### ios ui_tests

```sh
[bundle exec] fastlane ios ui_tests
```

Run the TapperUITests bundle, excluding the marketing screenshot run

### ios test

```sh
[bundle exec] fastlane ios test
```

Run every test bundle (unit + UI), skipping the screenshot run

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Capture simulator screenshots and render the branded marketing assets

### ios marketing

```sh
[bundle exec] fastlane ios marketing
```

Re-render App Store and README assets from existing captures (no simulator)

### ios ci

```sh
[bundle exec] fastlane ios ci
```

Everything CI runs: tests, then screenshots and marketing assets

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
