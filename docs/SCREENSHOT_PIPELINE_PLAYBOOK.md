# Generated screenshot pipeline — replication playbook

A self-contained recipe for reproducing Tapper's screenshot mechanism in any
other iOS app. Copy this file into the new project and work through it; every
file you need is reproduced in full below, with `MyApp` standing in for the
app's name.

The goal of the pipeline: **no screenshot is ever taken by hand.** A UI test
drives the real app on pinned simulators, and an AppKit script paints the
branded App Store frames and README artwork from those raw captures. Copy
changes never require a simulator, and a fresh checkout or CI runner produces
byte-comparable output.

---

## 1. What the pipeline is

```
UI test (XCUITest)                   fastlane snapshot drives the app on
  + launch argument for demo data    N simulators, status bar pinned to 9:41
        │
        ▼
fastlane/screenshots/en-US/          raw PNGs, already at upload sizes
  iPhone 16 Pro Max-01-dashboard.png
        │
        ▼
Marketing/copy.json  ──────────►  Scripts/generate_appstore_assets.swift
  captions, palettes, targets         AppKit renderer
        │
        ├──► AppStoreAssets/         upload-ready, plain + captioned
        ├──► docs/assets/            README hero, feature strip, icon
        └──► AppStoreSimulatorCaptures/   committed copies of the primary source
```

Three stages, three properties worth preserving:

| Stage | File | Property it buys you |
| --- | --- | --- |
| Capture | `<App>UITests/AppStoreScreenshotUITests.swift` | Screens come from the real app, so they can never drift from shipped UI |
| Drive | `fastlane/Snapfile`, `fastlane/Fastfile` | Identical output run-to-run and machine-to-machine |
| Render | `Scripts/generate_appstore_assets.swift` + `Marketing/copy.json` | Copy and palette changes need no Xcode, no simulator, no image editor |

**The rule that makes it work:** `AppStoreAssets/` and `docs/assets/` are
generated directories. Nothing in them is ever edited by hand, because the next
run replaces both wholesale.

---

## 2. Prerequisites

- macOS with Xcode and at least one iOS simulator runtime.
- Ruby + Bundler (fastlane is installed through the Gemfile, never globally).
- The app must have a UI test target.
- Nothing else. There is deliberately no ImageMagick, no Node, no device-bezel
  artwork, and no Photoshop template — the renderer is one AppKit script that
  ships with the repo and runs via `swift`.

```ruby
# Gemfile
source "https://rubygems.org"

gem "fastlane"
```

```sh
bundle install
```

---

## 3. Prepare the app for capture

Two changes in app code. Both are small and both are what separate a
reproducible pipeline from a flaky one.

### 3.1 A launch argument that seeds demo data

Screenshots must never show whatever happens to be in the simulator's database.
Add a launch argument that (a) swaps in an in-memory store and (b) seeds curated
content.

```swift
// MyAppApp.swift — in-memory store so captures never touch real data
var sharedModelContainer: ModelContainer = {
  let schema = Schema([Item.self])
  let launchArguments = ProcessInfo.processInfo.arguments
  let usesTemporaryStore = launchArguments.contains("-UITesting")
    || launchArguments.contains("-ShowcaseData")

  let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: usesTemporaryStore)
  do {
    return try ModelContainer(for: schema, configurations: [configuration])
  } catch {
    fatalError("Could not create ModelContainer: \(error)")
  }
}()
```

```swift
// The root list view — seeded once, only under the showcase argument.
.task {
  self.seedShowcaseDataIfNeeded()
}

func seedShowcaseDataIfNeeded() {
  guard ProcessInfo.processInfo.arguments.contains("-ShowcaseData"), self.items.isEmpty else { return }

  [
    Item(name: "Push-ups", colorHex: "ffd84d", value: 6),
    Item(name: "Sit-ups",  colorHex: "ef4538", value: 15),
    Item(name: "Squats",   colorHex: "62c866", value: 2)
  ].forEach { self.modelContext.insert($0) }

  try? self.modelContext.save()
}
```

Pick demo values that look deliberate. They appear in every store listing and
every README, so treat them as copy, not as fixtures.

**Not using SwiftData?** The shape holds regardless: the launch argument routes
the app to an ephemeral store (in-memory Core Data, a temp-directory SQLite
file, a stubbed network layer) and seeds it. What matters is that the argument
makes the run hermetic.

### 3.2 Accessibility identifiers on every element the test touches

The test navigates by identifier, never by visible label position. Use stable,
parameterised identifiers so the test reads declaratively:

```swift
.accessibilityIdentifier("openItem-\(item.name)")   // one per row
.accessibilityIdentifier("closeItemButton")
.accessibilityIdentifier("fullItemName")            // asserted after navigation
```

---

## 4. The capture test

Add fastlane's `SnapshotHelper.swift` to the UI test target:

```sh
bundle exec fastlane snapshot init
```

That writes `SnapshotHelper.swift` into the project. Add it to the **UI test
target only** (not the app target), then create the capture test beside it.

```swift
// MyAppUITests/AppStoreScreenshotUITests.swift
import XCTest

/// Captures the marketing screenshots that feed `Scripts/generate_appstore_assets.swift`.
///
/// Run it through fastlane rather than Xcode so every device in `fastlane/Snapfile`
/// is covered and the status bar is pinned:
///
///     bundle exec fastlane screenshots
///
/// Captures land in `fastlane/screenshots/en-US/<device>-<name>.png`. The names
/// here must match the `id` values in `Marketing/copy.json`.
@MainActor
final class AppStoreScreenshotUITests: XCTestCase {
  private var app: XCUIApplication!

  override func setUpWithError() throws {
    try super.setUpWithError()

    continueAfterFailure = false

    self.app = XCUIApplication()

    // Must be assigned before `setupSnapshot`, which appends fastlane's own
    // locale and `-FASTLANE_SNAPSHOT` arguments rather than replacing them.
    self.app.launchArguments = ["-ShowcaseData"]
    setupSnapshot(self.app)
  }

  override func tearDownWithError() throws {
    self.app = nil

    try super.tearDownWithError()
  }

  func testCaptureAppStoreScreenshots() throws {
    self.app.launch()

    XCTAssertTrue(self.app.staticTexts["Items"].waitForExistence(timeout: 5.0))
    self.captureScreenshot(named: "01-dashboard")

    try self.openItem(named: "Push-ups")
    self.captureScreenshot(named: "02-push-ups")
    self.app.buttons["closeItemButton"].tap()

    try self.openItem(named: "Sit-ups")
    self.captureScreenshot(named: "03-sit-ups")
    self.app.buttons["closeItemButton"].tap()

    try self.openItem(named: "Squats")
    self.captureScreenshot(named: "04-squats")
  }

  private func openItem(named name: String) throws {
    let openButton = self.app.buttons["openItem-\(name)"]
    XCTAssertTrue(openButton.waitForExistence(timeout: 5.0))
    openButton.tap()

    let nameLabel = self.app.staticTexts["fullItemName"]
    XCTAssertTrue(nameLabel.waitForExistence(timeout: 5.0))
    XCTAssertEqual(nameLabel.label, name)
  }

  /// Hands the shot to fastlane and also attaches it, so a CI `.xcresult`
  /// carries the captures even when the snapshot export is unavailable.
  private func captureScreenshot(named name: String) {
    snapshot(name)

    let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    self.add(attachment)
  }
}
```

Four details that are easy to get wrong:

1. **`launchArguments` before `setupSnapshot`.** `setupSnapshot` *appends*
   fastlane's locale and `-FASTLANE_SNAPSHOT` arguments. Assigning
   `launchArguments` afterwards wipes them and the capture silently fails.
2. **Every navigation step asserts before shooting.** `waitForExistence` plus an
   equality check on the destination label means a timing failure produces a
   red test, not a screenshot of a spinner.
3. **`continueAfterFailure = false`** — combined with `stop_after_first_error`
   in the Snapfile, a broken run stops instead of emitting a partial set that
   later gets uploaded.
4. **The dual capture.** `snapshot(name)` is the fastlane path;
   the `XCTAttachment` is the fallback that survives in the `.xcresult` when
   snapshot's export step fails on CI.

---

## 5. Pin the devices

Choose simulators whose **native pixel size already equals an App Store upload
size**, so the renderer never upscales. As of writing:

| Simulator | Native pixels | App Store size |
| --- | --- | --- |
| iPhone 16 Pro Max | 1320 × 2868 | 6.9-inch |
| iPhone 11 Pro Max | 1242 × 2688 | 6.5-inch |
| iPad Pro 13-inch (M4) | 2064 × 2752 | 13-inch |

Verify against Apple's current requirements before committing to a list, and
confirm the device exists in your Xcode with `xcrun simctl list devicetypes`.

```ruby
# fastlane/Snapfile
# Devices are chosen so each capture is already at an App Store upload size,
# which means the renderer never has to upscale. Keep these in sync with the
# `sourceDevice` values in Marketing/copy.json:
#
#   iPhone 16 Pro Max    1320x2868   6.9-inch
#   iPhone 11 Pro Max    1242x2688   6.5-inch
#   iPad Pro 13-inch     2064x2752   13-inch
project("./MyApp.xcodeproj")
scheme("MyApp")

devices([
  "iPhone 16 Pro Max",
  "iPhone 11 Pro Max",
  "iPad Pro 13-inch (M4)"
])

languages(["en-US"])

output_directory("./fastlane/screenshots")
only_testing(["MyAppUITests/AppStoreScreenshotUITests"])

clear_previous_screenshots(true)

# Pins the status bar to 9:41, full battery, full signal.
override_status_bar(true)

# The showcase gradients in Marketing/copy.json were designed against dark-mode
# captures. Without this the simulator defaults to light and the frames lose
# their contrast against the dark background.
dark_mode(true)

concurrent_simulators(true)
stop_after_first_error(true)
skip_open_summary(true)
```

`override_status_bar` and `dark_mode` are the two settings that exist purely for
determinism. Without the first, the status bar reads whatever the simulator
clock says and successive runs differ. Without the second, the simulator
defaults to light mode and your palette assumptions break.

---

## 6. The lanes

```ruby
# fastlane/Fastfile
#
# Scope note: this file deliberately contains no App Store Connect actions.
# There is no `deliver`, `pilot`, `match`, or `gym` here, nothing authenticates,
# and no signing certificates are required — every lane targets a simulator.

require "json"
require "shellwords"

default_platform(:ios)

PROJECT = "MyApp.xcodeproj".freeze
SCHEME = "MyApp".freeze
TEST_OUTPUT = "./fastlane/test_output".freeze

# Marketing captures are pinned to these devices because each one renders at an
# App Store upload size, so the renderer never upscales. Keep in sync with the
# `sourceDevice` values in Marketing/copy.json and with fastlane/Snapfile.
MARKETING_DEVICES = [
  "iPhone 16 Pro Max",
  "iPhone 11 Pro Max",
  "iPad Pro 13-inch (M4)"
].freeze

# Tests just need any iPhone, so resolve one that actually exists rather than
# hardcoding a name that varies with the installed Xcode.
PREFERRED_TEST_DEVICES = [
  "iPhone 17",
  "iPhone 16",
  "iPhone 16 Pro",
  "iPhone 15"
].freeze

def available_simulator_names
  json = JSON.parse(`xcrun simctl list devices available --json`)
  json["devices"].values.flatten.map { |device| device["name"] }
rescue JSON::ParserError
  UI.user_error!("Could not read the simulator list from `xcrun simctl`.")
end

def newest_ios_runtime
  json = JSON.parse(`xcrun simctl list runtimes --json`)
  runtimes = json["runtimes"].select do |runtime|
    runtime["isAvailable"] && runtime["identifier"].include?("SimRuntime.iOS")
  end

  UI.user_error!("No iOS simulator runtime is installed.") if runtimes.empty?

  runtimes.max_by { |runtime| Gem::Version.new(runtime["version"]) }["identifier"]
end

# Shared `scan` options. `cloned_source_packages_path` stays nil unless CI sets
# SPM_CACHE_PATH, so local runs keep using the normal DerivedData location.
def test_options
  {
    project: PROJECT,
    scheme: SCHEME,
    devices: [resolve_test_device],
    result_bundle: true,
    output_directory: TEST_OUTPUT,
    output_types: "junit",
    cloned_source_packages_path: ENV["SPM_CACHE_PATH"]
  }.compact
end

def resolve_test_device
  override = ENV["TEST_DEVICE"]
  return override unless override.nil? || override.empty?

  available = available_simulator_names
  device = PREFERRED_TEST_DEVICES.find { |name| available.include?(name) }
  device ||= available.find { |name| name.start_with?("iPhone") }

  UI.user_error!("No iPhone simulator available. Create one in Xcode or set TEST_DEVICE.") if device.nil?

  UI.message("Testing on #{device}")
  device
end

platform :ios do
  desc "Create any missing marketing simulator so screenshots are reproducible"
  lane :prepare_simulators do
    available = available_simulator_names
    missing = MARKETING_DEVICES.reject { |name| available.include?(name) }

    if missing.empty?
      UI.message("All marketing simulators are present.")
      next
    end

    runtime = newest_ios_runtime
    missing.each do |name|
      UI.message("Creating simulator: #{name}")
      sh("xcrun simctl create #{name.shellescape} #{name.shellescape} #{runtime.shellescape}", log: false)
    end
  end

  desc "Run the unit test bundle"
  lane :unit_tests do
    run_tests(test_options.merge(only_testing: ["MyAppTests"], code_coverage: true))
  end

  desc "Run the UI test bundle, excluding the marketing screenshot run"
  lane :ui_tests do
    run_tests(test_options.merge(
      only_testing: [
        "MyAppUITests/MyAppUITests",
        "MyAppUITests/MyAppUITestsLaunchTests"
      ]
    ))
  end

  desc "Run every test bundle (unit + UI), skipping the screenshot run"
  lane :test do
    run_tests(test_options.merge(
      skip_testing: ["MyAppUITests/AppStoreScreenshotUITests"],
      code_coverage: true
    ))
  end

  desc "Capture simulator screenshots and render the branded marketing assets"
  lane :screenshots do
    prepare_simulators
    capture_screenshots
    marketing
  end

  desc "Re-render App Store and README assets from existing captures (no simulator)"
  lane :marketing do
    # `sh` runs with the working directory set to fastlane/, hence the `cd ..`.
    sh("cd .. && swift Scripts/generate_appstore_assets.swift")
  end

  desc "Everything CI runs: tests, then screenshots and marketing assets"
  lane :ci do
    test
    screenshots
  end
end
```

Three design decisions worth carrying over verbatim:

- **`prepare_simulators` runs first.** It creates any pinned device the machine
  lacks, on the newest installed runtime. This is the single thing that makes a
  fresh checkout or a GitHub-hosted runner able to produce the same output.
- **Marketing devices are pinned; test devices are resolved.** Screenshots need
  exact pixel sizes; tests just need any iPhone, so `resolve_test_device` picks
  one that exists instead of hardcoding a name that breaks on every Xcode bump.
- **The screenshot class is excluded from `test`.** Three simulators × four
  screens is far slower than the suite, and the capture run is not an assertion
  about correctness.

---

## 7. The copy file

Every caption, palette, and device target lives in one JSON file. This is the
only file a copy change touches.

```json
{
  "$comment": "Single source of truth for MyApp's marketing imagery. Consumed by Scripts/generate_appstore_assets.swift. Colors are [red, green, blue] in the 0-255 range.",

  "app": {
    "name": "MyApp",
    "tagline": "Count anything, one tap at a time.",
    "heroMeta": "iOS 17  ·  SwiftUI  ·  SwiftData  ·  App Intents",
    "heroGradient": { "top": [8, 12, 28], "bottom": [17, 24, 48] },
    "heroTitleColor": [255, 255, 255],
    "heroSubtitleColor": [204, 211, 224],
    "heroMetaColor": [128, 142, 170],
    "iconPath": "MyApp/Assets.xcassets/AppIcon.appiconset/appstore.png",
    "committedCapturesDirectory": "AppStoreSimulatorCaptures"
  },

  "screenshots": [
    {
      "id": "01-dashboard",
      "showcaseFilename": "01-all-your-counters.png",
      "title": "All Your Counters",
      "subtitle": "Colorful items, sorted and ready.",
      "gradient": { "top": [8, 12, 28], "bottom": [17, 24, 48] },
      "titleColor": [255, 255, 255],
      "subtitleColor": [204, 211, 224]
    },
    {
      "id": "02-push-ups",
      "showcaseFilename": "02-tap-to-count.png",
      "title": "Tap To Count",
      "subtitle": "Big controls for quick sessions.",
      "gradient": { "top": [255, 221, 79], "bottom": [249, 196, 44] },
      "titleColor": [9, 12, 25],
      "subtitleColor": [57, 48, 21]
    },
    {
      "id": "03-sit-ups",
      "showcaseFilename": "03-stay-in-flow.png",
      "title": "Stay In Flow",
      "subtitle": "Reset or edit without losing focus.",
      "gradient": { "top": [244, 78, 62], "bottom": [226, 62, 56] },
      "titleColor": [9, 12, 25],
      "subtitleColor": [47, 23, 25]
    },
    {
      "id": "04-squats",
      "showcaseFilename": "04-color-code-it.png",
      "title": "Color Code It",
      "subtitle": "Spot every counter at a glance.",
      "gradient": { "top": [105, 207, 105], "bottom": [77, 184, 91] },
      "titleColor": [9, 12, 25],
      "subtitleColor": [23, 58, 32]
    }
  ],

  "targets": [
    {
      "id": "iPhone-6.9",
      "displayName": "iPhone 6.9-inch",
      "width": 1320,
      "height": 2868,
      "sourceDevice": "iPhone 16 Pro Max",
      "plainDirectory": "iPhone-6.9-plain",
      "showcaseDirectory": "iPhone-6.9-showcase",
      "style": "iphone",
      "isPrimary": true
    },
    {
      "id": "iPhone-6.5",
      "displayName": "iPhone 6.5-inch",
      "width": 1242,
      "height": 2688,
      "sourceDevice": "iPhone 11 Pro Max",
      "plainDirectory": "iPhone-6.5-plain",
      "showcaseDirectory": "iPhone-6.5-showcase",
      "style": "iphone"
    },
    {
      "id": "iPad-13",
      "displayName": "iPad 13-inch",
      "width": 2064,
      "height": 2752,
      "sourceDevice": "iPad Pro 13-inch (M4)",
      "showcaseDirectory": "iPad-13-previews",
      "style": "ipad",
      "limit": 3
    }
  ]
}
```

Field reference:

| Field | Meaning |
| --- | --- |
| `screenshots[].id` | **The contract with the UI test.** Must equal the `snapshot("…")` argument, and is also the raw capture's filename. |
| `screenshots[].showcaseFilename` | Human-readable name for the captioned output — this is what App Store Connect shows you when uploading. |
| `targets[].sourceDevice` | Must match the Snapfile device name exactly; it is half of the raw capture's filename. |
| `targets[].plainDirectory` | Optional. Omit to render only captioned frames for that size. |
| `targets[].style` | `iphone` or `ipad` — selects the layout geometry (see §8). |
| `targets[].limit` | Optional cap on how many screenshots this size gets. |
| `targets[].isPrimary` | Exactly one target sets this. It sources the README artwork and the committed offline captures. |

---

## 8. The renderer

`Scripts/generate_appstore_assets.swift` — a standalone `swift` script, no
package, no build step. It reads the copy file, finds each raw capture, and
paints the frames with AppKit.

```swift
#!/usr/bin/env swift
//
// Renders MyApp's branded App Store screenshots and README artwork.
//
//     swift Scripts/generate_appstore_assets.swift
//
// or, more usually, via the lane that captures fresh screenshots first:
//
//     bundle exec fastlane screenshots
//
// Captions, palettes, and device targets all come from Marketing/copy.json.
// Run it from the repository root, or set PROJECT_ROOT.
//
// Environment overrides:
//   PROJECT_ROOT          repository root (default: current directory)
//   SCREENSHOT_INPUT_DIR  where raw captures live (default: search order below)
//   APPSTORE_OUTPUT_DIR   App Store asset output (default: AppStoreAssets)
//   DOCS_ASSET_DIR        README artwork output (default: docs/assets)

import AppKit
import Foundation

// MARK: - Paths

let environment = ProcessInfo.processInfo.environment

let projectRoot = URL(
    fileURLWithPath: environment["PROJECT_ROOT"] ?? FileManager.default.currentDirectoryPath,
    isDirectory: true
)

func resolvedDirectory(_ override: String?, default defaultPath: String) -> URL {
    if let override, !override.isEmpty {
        return URL(fileURLWithPath: override, isDirectory: true)
    }
    return projectRoot.appendingPathComponent(defaultPath, isDirectory: true)
}

let outputRoot = resolvedDirectory(environment["APPSTORE_OUTPUT_DIR"], default: "AppStoreAssets")
let docsAssetRoot = resolvedDirectory(environment["DOCS_ASSET_DIR"], default: "docs/assets")
let copyFile = projectRoot.appendingPathComponent("Marketing/copy.json")
let fastlaneCaptureRoot = projectRoot.appendingPathComponent("fastlane/screenshots/en-US", isDirectory: true)

// MARK: - Configuration model

struct MarketingCopy: Decodable {
    struct Gradient: Decodable {
        let top: [CGFloat]
        let bottom: [CGFloat]
    }

    struct App: Decodable {
        let name: String
        let tagline: String
        let heroMeta: String
        let heroGradient: Gradient
        let heroTitleColor: [CGFloat]
        let heroSubtitleColor: [CGFloat]
        let heroMetaColor: [CGFloat]
        let iconPath: String
        let committedCapturesDirectory: String
    }

    struct Screenshot: Decodable {
        let id: String
        let showcaseFilename: String
        let title: String
        let subtitle: String
        let gradient: Gradient
        let titleColor: [CGFloat]
        let subtitleColor: [CGFloat]

        /// Raw captures keep their `id` as the filename.
        var plainFilename: String { "\(id).png" }
    }

    struct Target: Decodable {
        let id: String
        let displayName: String
        let width: CGFloat
        let height: CGFloat
        let sourceDevice: String
        let plainDirectory: String?
        let showcaseDirectory: String
        let style: String
        let limit: Int?
        let isPrimary: Bool?

        var size: NSSize { NSSize(width: width, height: height) }
        var acceptedDimensions: String { "\(Int(width))x\(Int(height))" }
        var isIPad: Bool { style == "ipad" }
    }

    let app: App
    let screenshots: [Screenshot]
    let targets: [Target]
}

struct GenerationError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

func color(_ components: [CGFloat]) throws -> NSColor {
    guard components.count == 3 || components.count == 4 else {
        throw GenerationError(message: "Colors must have 3 or 4 components, got \(components.count).")
    }
    return NSColor(
        calibratedRed: components[0] / 255,
        green: components[1] / 255,
        blue: components[2] / 255,
        alpha: components.count == 4 ? components[3] : 1
    )
}

func gradient(_ value: MarketingCopy.Gradient) throws -> NSGradient? {
    NSGradient(starting: try color(value.top), ending: try color(value.bottom))
}

/// Reports the problem and stops, rather than letting Swift dump a stack trace.
func fail(_ error: Error) -> Never {
    let message = (error as? GenerationError)?.message ?? error.localizedDescription
    FileHandle.standardError.write(Data("error: \(message)\n".utf8))
    exit(1)
}

func loadCopy() -> MarketingCopy {
    do {
        guard FileManager.default.fileExists(atPath: copyFile.path) else {
            throw GenerationError(message: "Missing marketing copy at \(copyFile.path). Run from the repository root or set PROJECT_ROOT.")
        }
        return try JSONDecoder().decode(MarketingCopy.self, from: try Data(contentsOf: copyFile))
    } catch {
        fail(error)
    }
}

let copy = loadCopy()
let committedCaptureRoot = projectRoot.appendingPathComponent(copy.app.committedCapturesDirectory, isDirectory: true)
let appIconURL = projectRoot.appendingPathComponent(copy.app.iconPath)

// MARK: - Source resolution

/// Resolution order: `$SCREENSHOT_INPUT_DIR`, then fastlane's snapshot output,
/// then the committed captures. Fails loudly rather than guessing.
func sourceURL(for screenshot: MarketingCopy.Screenshot, target: MarketingCopy.Target) throws -> URL {
    var candidates: [URL] = []

    if let override = environment["SCREENSHOT_INPUT_DIR"], !override.isEmpty {
        let root = URL(fileURLWithPath: override, isDirectory: true)
        candidates.append(root.appendingPathComponent("\(target.sourceDevice)-\(screenshot.id).png"))
        candidates.append(root.appendingPathComponent(screenshot.plainFilename))
    }

    candidates.append(fastlaneCaptureRoot.appendingPathComponent("\(target.sourceDevice)-\(screenshot.id).png"))
    candidates.append(committedCaptureRoot.appendingPathComponent(screenshot.plainFilename))

    if let match = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) {
        return match
    }

    let searched = candidates.map { "  - \($0.path)" }.joined(separator: "\n")
    throw GenerationError(message: """
        No capture found for "\(screenshot.id)" on \(target.displayName).

        Looked in:
        \(searched)

        Capture fresh screenshots with `bundle exec fastlane screenshots`.
        """)
}

// MARK: - Drawing primitives

func removeAndCreateDirectory(_ url: URL) throws {
    if FileManager.default.fileExists(atPath: url.path) {
        try FileManager.default.removeItem(at: url)
    }
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
}

func loadImage(_ url: URL) throws -> NSImage {
    guard let image = NSImage(contentsOf: url) else {
        throw GenerationError(message: "Could not load \(url.path)")
    }
    return image
}

func aspectFillRect(source: NSSize, target: NSSize) -> NSRect {
    let scale = max(target.width / source.width, target.height / source.height)
    let width = source.width * scale
    let height = source.height * scale
    return NSRect(
        x: (target.width - width) / 2,
        y: (target.height - height) / 2,
        width: width,
        height: height
    )
}

/// AppKit's origin is bottom-left; layout reads better from the top.
func rectFromTop(canvas: NSSize, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> NSRect {
    NSRect(x: x, y: canvas.height - y - height, width: width, height: height)
}

func drawText(
    _ text: String,
    canvas: NSSize,
    topY: CGFloat,
    width: CGFloat,
    font: NSFont,
    color: NSColor,
    lineHeight: CGFloat,
    alignment: NSTextAlignment = .center
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineSpacing = 0
    paragraph.minimumLineHeight = lineHeight
    paragraph.maximumLineHeight = lineHeight

    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]

    let attributed = NSAttributedString(string: text, attributes: attributes)
    let height = max(lineHeight * 2, attributed.boundingRect(
        with: NSSize(width: width, height: 1000),
        options: [.usesLineFragmentOrigin, .usesFontLeading]
    ).height + 20)
    let rect = rectFromTop(
        canvas: canvas,
        x: alignment == .left ? 0 : (canvas.width - width) / 2,
        y: topY,
        width: width,
        height: height
    )
    attributed.draw(in: rect)
}

func renderBitmap(size: NSSize, _ draw: () -> Void) throws -> NSBitmapImageRep {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size.width),
        pixelsHigh: Int(size.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw GenerationError(message: "Could not create a \(Int(size.width))x\(Int(size.height)) bitmap context")
    }

    bitmap.size = size
    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw GenerationError(message: "Could not create graphics context")
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    draw()
    NSGraphicsContext.restoreGraphicsState()

    return bitmap
}

func savePNG(_ bitmap: NSBitmapImageRep, to url: URL) throws {
    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw GenerationError(message: "Could not encode \(url.path)")
    }
    try png.write(to: url)
}

func image(from bitmap: NSBitmapImageRep) -> NSImage {
    let image = NSImage(size: NSSize(width: bitmap.pixelsWide, height: bitmap.pixelsHigh))
    image.addRepresentation(bitmap)
    return image
}

/// Writes a width-constrained copy, so the README pulls a few hundred KB
/// instead of the multi-megabyte upload assets.
func saveScaledCopy(of bitmap: NSBitmapImageRep, width: CGFloat, to url: URL) throws {
    let source = image(from: bitmap)
    let height = (width * CGFloat(bitmap.pixelsHigh) / CGFloat(bitmap.pixelsWide)).rounded()
    let size = NSSize(width: width, height: height)

    let scaled = try renderBitmap(size: size) {
        source.draw(
            in: NSRect(origin: .zero, size: size),
            from: NSRect(origin: .zero, size: source.size),
            operation: .copy,
            fraction: 1
        )
    }
    try savePNG(scaled, to: url)
}

/// The screenshot inset used by every showcase render: rounded rect, drop
/// shadow, hairline highlight.
func drawInsetScreenshot(
    _ source: NSImage,
    in rect: NSRect,
    cornerRadius: CGFloat,
    shadowBlur: CGFloat,
    shadowOffset: CGFloat,
    shadowAlpha: CGFloat = 0.34,
    strokeWidth: CGFloat
) {
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(shadowAlpha)
    shadow.shadowBlurRadius = shadowBlur
    shadow.shadowOffset = NSSize(width: 0, height: -shadowOffset)
    shadow.set()
    NSColor.black.withAlphaComponent(0.16).setFill()
    path.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    path.addClip()
    source.draw(
        in: rect,
        from: NSRect(origin: .zero, size: source.size),
        operation: .sourceOver,
        fraction: 1
    )
    NSGraphicsContext.restoreGraphicsState()

    NSColor.white.withAlphaComponent(0.18).setStroke()
    path.lineWidth = strokeWidth
    path.stroke()
}

// MARK: - App Store renders

func renderPlain(source: NSImage, target: MarketingCopy.Target, to url: URL) throws {
    let output = try renderBitmap(size: target.size) {
        NSColor.black.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: target.size)).fill()
        source.draw(
            in: aspectFillRect(source: source.size, target: target.size),
            from: NSRect(origin: .zero, size: source.size),
            operation: .sourceOver,
            fraction: 1
        )
    }
    try savePNG(output, to: url)
}

@discardableResult
func renderShowcase(
    source: NSImage,
    item: MarketingCopy.Screenshot,
    target: MarketingCopy.Target,
    to url: URL
) throws -> NSBitmapImageRep {
    let canvas = target.size
    let titleColor = try color(item.titleColor)
    let subtitleColor = try color(item.subtitleColor)
    let background = try gradient(item.gradient)

    // Geometry is expressed against the reference canvas each style was
    // designed on, then scaled to whatever the target size is.
    let reference: NSSize = target.isIPad
        ? NSSize(width: 2064, height: 2752)
        : NSSize(width: 1320, height: 2868)
    let scale = min(canvas.width / reference.width, canvas.height / reference.height)

    let titleSize: CGFloat = target.isIPad ? 132 : 92
    let titleWidth: CGFloat = target.isIPad ? 1660 : 1060
    let titleLineHeight: CGFloat = target.isIPad ? 150 : 106
    let subtitleTopY: CGFloat = target.isIPad ? 325 : 270
    let subtitleSize: CGFloat = target.isIPad ? 62 : 44
    let subtitleWidth: CGFloat = target.isIPad ? 1580 : 1040
    let subtitleLineHeight: CGFloat = target.isIPad ? 78 : 56
    let insetWidth: CGFloat = 946
    let insetTopY: CGFloat = target.isIPad ? 515 : 505
    let cornerRadius: CGFloat = target.isIPad ? 74 : 76
    let shadowBlur: CGFloat = target.isIPad ? 70 : 54
    let shadowOffset: CGFloat = target.isIPad ? 28 : 22
    let shadowAlpha: CGFloat = target.isIPad ? 0.32 : 0.34
    let strokeWidth: CGFloat = target.isIPad ? 4 : 3

    let output = try renderBitmap(size: canvas) {
        background?.draw(in: NSRect(origin: .zero, size: canvas), angle: -90)

        drawText(
            item.title,
            canvas: canvas,
            topY: 145 * scale,
            width: titleWidth * scale,
            font: NSFont.systemFont(ofSize: titleSize * scale, weight: .black),
            color: titleColor,
            lineHeight: titleLineHeight * scale
        )
        drawText(
            item.subtitle,
            canvas: canvas,
            topY: subtitleTopY * scale,
            width: subtitleWidth * scale,
            font: NSFont.systemFont(ofSize: subtitleSize * scale, weight: .semibold),
            color: subtitleColor,
            lineHeight: subtitleLineHeight * scale
        )

        // iPhone captures are tall enough that a fixed width fills the canvas.
        // An iPad capture is nearly 4:3, so size it to the available height
        // instead or the lower third of the frame ends up empty.
        let width: CGFloat
        if target.isIPad {
            let available = canvas.height - (insetTopY + 220) * scale
            let widthToFillHeight = available * source.size.width / source.size.height
            width = min(canvas.width - 360 * scale, widthToFillHeight)
        } else {
            width = insetWidth * scale
        }
        let height = width * source.size.height / source.size.width
        let rect = rectFromTop(
            canvas: canvas,
            x: (canvas.width - width) / 2,
            y: insetTopY * scale,
            width: width,
            height: height
        )
        drawInsetScreenshot(
            source,
            in: rect,
            cornerRadius: cornerRadius * scale,
            shadowBlur: shadowBlur * scale,
            shadowOffset: shadowOffset * scale,
            shadowAlpha: shadowAlpha,
            strokeWidth: strokeWidth * scale
        )
    }

    try savePNG(output, to: url)
    return output
}

// MARK: - README artwork

func renderHero(sources: [NSImage], to url: URL) throws {
    let canvas = NSSize(width: 2400, height: 1000)
    let background = try gradient(copy.app.heroGradient)
    let titleColor = try color(copy.app.heroTitleColor)
    let subtitleColor = try color(copy.app.heroSubtitleColor)
    let metaColor = try color(copy.app.heroMetaColor)
    let icon = FileManager.default.fileExists(atPath: appIconURL.path) ? try loadImage(appIconURL) : nil

    let output = try renderBitmap(size: canvas) {
        background?.draw(in: NSRect(origin: .zero, size: canvas), angle: -90)

        let leftMargin: CGFloat = 150

        if let icon {
            let iconRect = rectFromTop(canvas: canvas, x: leftMargin, y: 250, width: 190, height: 190)
            let iconPath = NSBezierPath(roundedRect: iconRect, xRadius: 42, yRadius: 42)
            NSGraphicsContext.saveGraphicsState()
            iconPath.addClip()
            icon.draw(
                in: iconRect,
                from: NSRect(origin: .zero, size: icon.size),
                operation: .sourceOver,
                fraction: 1
            )
            NSGraphicsContext.restoreGraphicsState()
        }

        let textRect = rectFromTop(canvas: canvas, x: leftMargin, y: 480, width: 1100, height: 190)
        NSAttributedString(
            string: copy.app.name,
            attributes: [
                .font: NSFont.systemFont(ofSize: 150, weight: .black),
                .foregroundColor: titleColor
            ]
        ).draw(in: textRect)

        let taglineRect = rectFromTop(canvas: canvas, x: leftMargin, y: 660, width: 1000, height: 170)
        let taglineParagraph = NSMutableParagraphStyle()
        taglineParagraph.lineSpacing = 8
        NSAttributedString(
            string: copy.app.tagline,
            attributes: [
                .font: NSFont.systemFont(ofSize: 54, weight: .medium),
                .foregroundColor: subtitleColor,
                .paragraphStyle: taglineParagraph
            ]
        ).draw(in: taglineRect)

        let metaRect = rectFromTop(canvas: canvas, x: leftMargin, y: 775, width: 1050, height: 60)
        NSAttributedString(
            string: copy.app.heroMeta,
            attributes: [
                .font: NSFont.systemFont(ofSize: 30, weight: .semibold),
                .foregroundColor: metaColor
            ]
        ).draw(in: metaRect)

        // Screenshots stepped across the right-hand side.
        let phoneWidth: CGFloat = 340
        let spacing: CGFloat = 375
        let startX: CGFloat = 1290
        for (index, source) in sources.prefix(3).enumerated() {
            let height = phoneWidth * source.size.height / source.size.width
            let stagger = CGFloat(index) * 34
            let rect = rectFromTop(
                canvas: canvas,
                x: startX + CGFloat(index) * spacing,
                y: 116 + stagger,
                width: phoneWidth,
                height: height
            )
            drawInsetScreenshot(
                source,
                in: rect,
                cornerRadius: 30,
                shadowBlur: 34,
                shadowOffset: 14,
                strokeWidth: 2
            )
        }
    }

    try savePNG(output, to: url)
}

func copyAppIcon(to directory: URL, filename: String, width: CGFloat?) throws {
    guard FileManager.default.fileExists(atPath: appIconURL.path) else {
        throw GenerationError(message: "Missing app icon at \(appIconURL.path)")
    }

    let destination = directory.appendingPathComponent(filename)

    guard let width else {
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: appIconURL, to: destination)
        return
    }

    let icon = try loadImage(appIconURL)
    let size = NSSize(width: width, height: width)
    let scaled = try renderBitmap(size: size) {
        icon.draw(
            in: NSRect(origin: .zero, size: size),
            from: NSRect(origin: .zero, size: icon.size),
            operation: .copy,
            fraction: 1
        )
    }
    try savePNG(scaled, to: destination)
}

// MARK: - Generated inventory

func writeReadme(sourceDescription: String) throws {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(identifier: "UTC")

    let inventory = copy.targets.map { target -> String in
        var lines: [String] = []
        if let plain = target.plainDirectory {
            lines.append("- `\(plain)/`: exact-size, upload-ready screenshots at `\(target.acceptedDimensions)`.")
        }
        let count = target.limit.map { " (\($0) images)" } ?? ""
        lines.append("- `\(target.showcaseDirectory)/`: captioned App Store screenshots at `\(target.acceptedDimensions)`\(count).")
        return lines.joined(separator: "\n")
    }.joined(separator: "\n")

    let accepted = copy.targets
        .map { "`\($0.acceptedDimensions)` for \($0.displayName) displays" }
        .joined(separator: ", ")

    let readme = """
    # \(copy.app.name) App Store Assets

    Generated from \(sourceDescription) on \(formatter.string(from: Date())).

    **This directory is generated — do not edit it by hand.** Every run replaces
    its entire contents. Captions and palettes live in `Marketing/copy.json`.

    ## Contents

    - `AppIcon-1024.png`: copied from the app icon asset catalog.
    \(inventory)

    ## Refreshing

    ```sh
    bundle exec fastlane screenshots   # capture on every device, then render
    bundle exec fastlane marketing     # re-render from existing captures
    ```

    Apple currently accepts \(accepted).

    """
    try readme.write(to: outputRoot.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
}

// MARK: - Main

func generate() throws {
    let usingFastlaneCaptures = FileManager.default.fileExists(atPath: fastlaneCaptureRoot.path)
    let sourceDescription = usingFastlaneCaptures
        ? "fastlane snapshot captures in `fastlane/screenshots/en-US`"
        : "committed captures in `\(copy.app.committedCapturesDirectory)`"

    try removeAndCreateDirectory(outputRoot)
    try removeAndCreateDirectory(docsAssetRoot)

    var heroSources: [NSImage] = []
    var featureBitmaps: [(String, NSBitmapImageRep)] = []

    for target in copy.targets {
        let showcaseDirectory = outputRoot.appendingPathComponent(target.showcaseDirectory, isDirectory: true)
        try FileManager.default.createDirectory(at: showcaseDirectory, withIntermediateDirectories: true)

        var plainDirectory: URL?
        if let plain = target.plainDirectory {
            let directory = outputRoot.appendingPathComponent(plain, isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            plainDirectory = directory
        }

        let items = target.limit.map { Array(copy.screenshots.prefix($0)) } ?? copy.screenshots

        for item in items {
            let inputURL = try sourceURL(for: item, target: target)
            let source = try loadImage(inputURL)

            if let plainDirectory {
                try renderPlain(
                    source: source,
                    target: target,
                    to: plainDirectory.appendingPathComponent(item.plainFilename)
                )
            }

            let showcase = try renderShowcase(
                source: source,
                item: item,
                target: target,
                to: showcaseDirectory.appendingPathComponent(item.showcaseFilename)
            )

            // The primary pass doubles as the source for README artwork and for
            // the committed captures that let `fastlane marketing` run offline.
            if target.isPrimary == true {
                heroSources.append(source)
                featureBitmaps.append((item.id, showcase))

                if usingFastlaneCaptures {
                    try FileManager.default.createDirectory(at: committedCaptureRoot, withIntermediateDirectories: true)
                    let mirrored = committedCaptureRoot.appendingPathComponent(item.plainFilename)
                    if FileManager.default.fileExists(atPath: mirrored.path) {
                        try FileManager.default.removeItem(at: mirrored)
                    }
                    try FileManager.default.copyItem(at: inputURL, to: mirrored)
                }
            }
        }

        print("Rendered \(items.count) screenshot(s) for \(target.displayName) at \(target.acceptedDimensions)")
    }

    guard !heroSources.isEmpty else {
        throw GenerationError(message: "No target is marked `isPrimary`, so there is no source for README artwork.")
    }

    try copyAppIcon(to: outputRoot, filename: "AppIcon-1024.png", width: nil)
    try writeReadme(sourceDescription: sourceDescription)

    try renderHero(sources: heroSources, to: docsAssetRoot.appendingPathComponent("hero.png"))
    try copyAppIcon(to: docsAssetRoot, filename: "app-icon.png", width: 256)
    for (index, entry) in featureBitmaps.enumerated() {
        let filename = String(format: "feature-%02d.png", index + 1)
        try saveScaledCopy(of: entry.1, width: 620, to: docsAssetRoot.appendingPathComponent(filename))
    }

    print("Generated App Store assets in \(outputRoot.path)")
    print("Generated README artwork in \(docsAssetRoot.path)")
}

do {
    try generate()
} catch {
    fail(error)
}
```

### How the renderer is put together

**Source resolution with a fallback chain.** `SCREENSHOT_INPUT_DIR` →
`fastlane/screenshots/en-US/<device>-<id>.png` → committed captures. If nothing
matches, it prints every path it tried and exits 1. It never falls back to a
guess or a placeholder, because a silently-wrong screenshot is worse than a
failed build.

**Reference-canvas geometry.** Every layout constant is written against the
canvas the style was designed on, then multiplied by a single `scale` derived
from the actual target size. Adding a fourth device size costs one JSON entry
and no code.

**Two layout styles.** iPhone frames use a fixed inset width, because a tall
capture fills the canvas anyway. iPad captures are nearly 4:3, so a fixed width
leaves the lower third empty — the iPad branch sizes the inset to the available
*height* instead.

**Painted, not composited.** Vertical `NSGradient`, title in
`systemFont(weight: .black)`, subtitle in `.semibold`, and the screenshot
clipped into a rounded rect with a drop shadow and a 0.18-alpha white hairline.
No bezel PNGs to source, license, or keep current with new hardware.

**The primary target does triple duty.** It renders its own assets, sources the
README hero and feature strip, and mirrors its raw captures into the committed
directory — which is what makes `fastlane marketing` work with no simulator.

**A generated README in the output directory.** Every run rewrites
`AppStoreAssets/README.md` with the date, the source, an inventory, and a
"do not edit by hand" notice. That sentence lives *inside* the generated
directory, where someone about to edit a file will actually see it.

---

## 9. Git hygiene

Raw captures are large and fully regenerable; rendered assets are small and
belong in the repo so the README renders on GitHub.

```gitignore
# fastlane
# Raw captures are regenerable and large; the rendered assets in
# AppStoreAssets/ and docs/assets/ are committed instead.
fastlane/screenshots/
fastlane/test_output/
fastlane/report.xml
fastlane/Preview.html
*.xcresult

# Ruby / bundler
.bundle/
vendor/bundle/
```

Committed: `AppStoreAssets/`, `docs/assets/`, `AppStoreSimulatorCaptures/`,
`Marketing/copy.json`, everything under `fastlane/` except the outputs above.

---

## 10. CI

Capture is slow — several simulators booting and running a UI test. Do not put
it on every pull request.

```yaml
# .github/workflows/screenshots.yml
name: Marketing screenshots

# Deliberately not run on every pull request: capturing four screens across
# three simulators takes far longer than the test suite. Trigger it by hand
# from the Actions tab, or let a release tag do it.
on:
  workflow_dispatch:
  push:
    tags: ["v*"]

concurrency:
  group: screenshots-${{ github.ref }}
  cancel-in-progress: true

jobs:
  screenshots:
    name: Capture and render
    runs-on: macos-15
    timeout-minutes: 60

    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: latest-stable

      - name: Set up Ruby and install gems
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: "4.0"
          bundler-cache: true

      # The marketing devices are pinned for exact pixel sizes, so surface what
      # the runner's Xcode actually offers before `prepare_simulators` runs.
      - name: Show available simulator device types
        run: xcrun simctl list devicetypes available

      - name: Capture screenshots and render marketing assets
        run: bundle exec fastlane screenshots

      - name: Upload App Store assets
        uses: actions/upload-artifact@v4
        with:
          name: appstore-assets
          path: AppStoreAssets
          retention-days: 30

      - name: Upload README artwork
        uses: actions/upload-artifact@v4
        with:
          name: readme-artwork
          path: docs/assets
          retention-days: 30

      - name: Upload raw captures
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: raw-captures
          path: fastlane/screenshots
          retention-days: 14
          if-no-files-found: warn
```

The raw-captures upload runs `if: always()` on purpose — when a capture fails,
the partial output is the most useful debugging artifact you have.

---

## 11. Daily use

```sh
bundle exec fastlane screenshots   # capture on all devices, then render
bundle exec fastlane marketing     # re-render from existing captures (no simulator)
swift Scripts/generate_appstore_assets.swift   # what `marketing` runs
```

`marketing` is the fast path and the one you will use most: because the primary
device's captures are committed, a caption or palette change re-renders
everything in seconds without booting anything.

**To change copy or colours:** edit `Marketing/copy.json`, run
`bundle exec fastlane marketing`. No Swift edits.

**To add a screenshot:** add a `snapshot("05-…")` call to the UI test *and* a
matching entry in `copy.json`. Both, or the run fails — which is the intent.

**To add a device size:** add it in all three places — `Snapfile` `devices`,
`Fastfile` `MARKETING_DEVICES`, and `copy.json` `targets[].sourceDevice`.

---

## 12. Replication checklist

- [ ] `Gemfile` with `fastlane`; `bundle install`
- [ ] `-ShowcaseData` launch argument: ephemeral store + seeded demo content
- [ ] Accessibility identifiers on every element the capture test touches
- [ ] `SnapshotHelper.swift` added to the **UI test target only**
- [ ] `AppStoreScreenshotUITests.swift` — `launchArguments` set *before* `setupSnapshot`
- [ ] `fastlane/Snapfile` — devices, `override_status_bar`, `dark_mode`, `only_testing`
- [ ] `fastlane/Fastfile` — `prepare_simulators`, `screenshots`, `marketing`; screenshot class excluded from `test`
- [ ] `Marketing/copy.json` — ids matching the test, one target marked `isPrimary`
- [ ] `Scripts/generate_appstore_assets.swift` with the app's `iconPath`
- [ ] `.gitignore` — raw captures and fastlane output ignored, rendered assets committed
- [ ] `.github/workflows/screenshots.yml` — manual + tag trigger only
- [ ] First run: `bundle exec fastlane screenshots`, then commit the mirrored captures
- [ ] Verify `bundle exec fastlane marketing` works with `fastlane/screenshots/` deleted

---

## 13. Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| `No capture found for …` | Neither fastlane captures nor committed ones exist. Run `bundle exec fastlane screenshots`. The error lists every path it tried. |
| Captures are empty or the app shows the launch screen | The test navigated before the UI settled. Every step needs `waitForExistence` before `snapshot(...)`. |
| No screenshots exported at all | `launchArguments` was assigned *after* `setupSnapshot`, wiping fastlane's `-FASTLANE_SNAPSHOT` argument. |
| Status bar shows the wrong time | `override_status_bar` only applies through the lane. Capturing from Xcode directly bypasses it — that's why the lane is the supported path. |
| Device missing on this machine | `prepare_simulators` creates it. If the device type genuinely doesn't exist in your Xcode, check `xcrun simctl list devicetypes` and update all three declaration sites. |
| Renders look washed out | The simulator ran in light mode. Confirm `dark_mode(true)` in the Snapfile, or re-tune the palettes in `copy.json` for light captures. |
| Wrong output size | `targets[].width/height` in `copy.json` disagrees with the device's native size. The renderer trusts the JSON and aspect-fills, so a mismatch crops. |
| Screenshots show stale or personal data | The `-ShowcaseData` argument isn't reaching the store configuration, or the seed guard (`items.isEmpty`) never fires. |
