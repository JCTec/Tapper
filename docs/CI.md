# Continuous integration

Two GitHub Actions workflows, split so that pull requests get fast feedback and
the slow marketing work happens only when asked for.

Nothing in this repository authenticates against App Store Connect. There is no
`deliver`, `pilot`, `match`, or `gym`, no API key, and no signing certificate.
Every job targets a simulator, so no secrets are required and forks can run CI
unchanged.

## `ci.yml` — build and test

**Triggers:** push to `main`, and every pull request.

Cancels superseded runs via a `concurrency` group, so pushing twice to a branch
does not leave a stale run burning minutes.

| Step | Notes |
| --- | --- |
| `maxim-lobanov/setup-xcode` | `latest-stable` |
| `ruby/setup-ruby` | Ruby 4.0, `bundler-cache: true` |
| `xcrun simctl list devicetypes` | Diagnostic — makes device mismatches obvious |
| `actions/cache` | Swift packages, keyed on `Package.resolved` |
| `xcodebuild -resolvePackageDependencies` | Into `.swiftpm-cache` |
| `bundle exec fastlane test` | `SPM_CACHE_PATH=.swiftpm-cache` |
| `actions/upload-artifact` | `fastlane/test_output`, `if: always()` |

The cache only helps if the test build uses the same checkout directory, which
is why `SPM_CACHE_PATH` is threaded through to `scan`'s
`cloned_source_packages_path`. Without it the resolve step would populate a
directory the build never reads.

## `screenshots.yml` — marketing assets

**Triggers:** `workflow_dispatch` (the "Run workflow" button) and `v*` tags.

Not on pull requests: capturing four screens across three simulators takes far
longer than the test suite, and screenshots rarely need to change per PR.

It runs `bundle exec fastlane screenshots` and uploads three artifacts:

| Artifact | Contents | Retention |
| --- | --- | --- |
| `appstore-assets` | `AppStoreAssets/` | 30 days |
| `readme-artwork` | `docs/assets/` | 30 days |
| `raw-captures` | `fastlane/screenshots/` | 14 days |

The workflow does **not** commit anything back. Download the artifact, review
the renders, and commit them deliberately — a bot commit that silently rewrites
19 binary files on every run is worse than an explicit one.

## Running the same thing locally

```sh
bundle install
bundle exec fastlane test
bundle exec fastlane screenshots
```

These are the exact commands CI runs. There is no CI-only configuration beyond
the `SPM_CACHE_PATH` environment variable.

## Notes and known issues

**Ruby version.** The workflows pin Ruby 4.0 to match the `Gemfile.lock`, which
was resolved with Bundler 4.0.11. If a runner cannot provide Ruby 4.0, either
change `ruby-version` in both workflows and re-resolve the lockfile, or drop
`Gemfile.lock` from version control and let each run resolve fresh.

**Lockfile platforms.** `Gemfile.lock` lists `arm64-darwin-24` (macos-15),
`arm64-darwin-25`, `x86_64-darwin-24`, and the generic `ruby` platform. A runner
image on a newer macOS may need another entry:

```sh
bundle lock --add-platform arm64-darwin-26
```

**Simulator names are Xcode-dependent.** The marketing devices are pinned for
exact pixel sizes and created by the `prepare_simulators` lane if missing. Test
lanes resolve any available iPhone instead, so they are immune to this. The
`simctl list devicetypes` step exists to make a genuine mismatch readable in the
log.

**Code signing.** Simulator builds sign locally and need no team. If a runner's
automatic-signing resolution ever objects to `DEVELOPMENT_TEAM = S8662L649U`,
add this to the `scan` invocation in `test_options`:

```ruby
xcargs: "CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO"
```

**ColorKit is pinned to a branch.** `Package.resolved` records revision
`6e4375a` on `master` rather than a version tag. Resolution is reproducible
today because the lockfile pins the revision, but a forced re-resolve would pick
up whatever `master` points at. Worth changing to an exact revision or a version
rule in Xcode's package settings.

**The `AccentColor` build setting has no asset.**
`ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor` names a colour
set that does not exist, which produces a warning on every build.
