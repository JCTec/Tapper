# Screenshots and marketing assets

Every App Store screenshot and every image in the README is generated. Nothing
is cropped by hand, and no file in `AppStoreAssets/` or `docs/assets/` should
ever be edited directly — the next run replaces both directories wholesale.

## The pipeline

```
AppStoreScreenshotUITests            fastlane snapshot drives the app on
  -ShowcaseData                      3 simulators, status bar pinned to 9:41
        │
        ▼
fastlane/screenshots/en-US/          12 raw PNGs, already at upload sizes
  iPhone 16 Pro Max-01-dashboard.png
        │
        ▼
Marketing/copy.json  ──────────►  Scripts/generate_appstore_assets.swift
  captions, palettes, targets         AppKit renderer
        │
        ├──► AppStoreAssets/         upload-ready, plain + captioned
        ├──► docs/assets/            README hero, feature strip, icon
        └──► AppStoreSimulatorCaptures/   committed copies of the 6.9" sources
```

## Commands

```sh
bundle exec fastlane screenshots   # capture on all devices, then render
bundle exec fastlane marketing     # re-render from existing captures (no simulator)
swift Scripts/generate_appstore_assets.swift   # what `marketing` runs
```

`marketing` is the fast path. Because the 6.9-inch captures are mirrored into
`AppStoreSimulatorCaptures/` and committed, you can re-render everything after a
copy change without booting a simulator.

## Devices

Each device is chosen because it renders natively at an App Store upload size,
so the renderer never upscales:

| Simulator | Native pixels | App Store size |
| --- | --- | --- |
| iPhone 16 Pro Max | 1320 × 2868 | 6.9-inch |
| iPhone 11 Pro Max | 1242 × 2688 | 6.5-inch |
| iPad Pro 13-inch (M4) | 2064 × 2752 | 13-inch |

These are declared in three places that must agree: `fastlane/Snapfile`
(`devices`), `fastlane/Fastfile` (`MARKETING_DEVICES`), and `Marketing/copy.json`
(`targets[].sourceDevice`).

The `prepare_simulators` lane runs first and creates any of them that the
machine is missing, using the newest installed iOS runtime. That is what makes
the capture reproducible on a fresh checkout or a CI runner.

Two Snapfile settings matter for how the captures look, and both exist to keep
successive runs identical:

- `override_status_bar(true)` pins the status bar to 9:41 with full battery and
  signal, instead of whatever the simulator clock happens to read.
- `dark_mode(true)` forces the dark appearance. The showcase gradients were
  designed against dark captures; without this the simulator defaults to light
  and the frames lose their contrast against the dark navy background.

## Editing the copy

Captions, subtitles, gradients, and text colours all live in
[`Marketing/copy.json`](../Marketing/copy.json). Change it, run
`bundle exec fastlane marketing`, and the renders update. No Swift edits needed.

```json
{
  "id": "02-push-ups",
  "showcaseFilename": "02-tap-to-count.png",
  "title": "Tap To Count",
  "subtitle": "Big controls for quick sessions.",
  "gradient": { "top": [255, 221, 79], "bottom": [249, 196, 44] },
  "titleColor": [9, 12, 25],
  "subtitleColor": [57, 48, 21]
}
```

Colours are `[red, green, blue]` in the 0–255 range, optionally with a fourth
alpha component.

`id` is the contract with the UI test: `snapshot("02-push-ups")` in
`AppStoreScreenshotUITests` must match the `id` here. Adding a screenshot means
adding a `snapshot(...)` call *and* an entry in this file.

## Output

`AppStoreAssets/` — upload-ready:

| Directory | Contents |
| --- | --- |
| `iPhone-6.9-plain/` | 4 bare screenshots, 1320 × 2868 |
| `iPhone-6.9-showcase/` | 4 captioned frames, 1320 × 2868 |
| `iPhone-6.5-plain/` | 4 bare screenshots, 1242 × 2688 |
| `iPhone-6.5-showcase/` | 4 captioned frames, 1242 × 2688 |
| `iPad-13-previews/` | 3 captioned frames, 2064 × 2752 |
| `AppIcon-1024.png` | Copied from the asset catalog |

`docs/assets/` — README artwork:

| File | Purpose |
| --- | --- |
| `hero.png` | 2400 × 1000 banner: icon, wordmark, tagline, 3 stepped screens |
| `feature-01..04.png` | Captioned frames scaled to 620 px wide |
| `app-icon.png` | 256 px icon |

## Render styles

The renderer paints each frame in code with AppKit — there is no device-bezel
artwork and no ImageMagick dependency:

1. Vertical `NSGradient` background from the palette.
2. Title in `systemFont(weight: .black)`, subtitle in `.semibold`.
3. The screenshot clipped into a rounded rect with a drop shadow and a
   0.18-alpha white hairline stroke.

iPhone frames use a fixed inset width, tuned to the 6.9-inch canvas and scaled
from there. iPad frames size the inset to the available height instead —
an iPad capture is nearly 4:3, so a fixed width would leave the lower third of
the canvas empty.

## Environment overrides

The script honours four variables, mainly for CI:

| Variable | Default |
| --- | --- |
| `TAPPER_PROJECT_ROOT` | current directory |
| `SCREENSHOT_INPUT_DIR` | `fastlane/screenshots/en-US`, then `AppStoreSimulatorCaptures` |
| `APPSTORE_OUTPUT_DIR` | `AppStoreAssets` |
| `DOCS_ASSET_DIR` | `docs/assets` |

If no capture can be found, the script prints every path it tried and exits 1.
It never falls back to a guess.

## Troubleshooting

**"No capture found for …"** — you have neither fastlane captures nor committed
ones. Run `bundle exec fastlane screenshots`.

**A device is missing on this machine** — `prepare_simulators` should create it.
If the device type genuinely does not exist in your Xcode, check with
`xcrun simctl list devicetypes` and update the three declaration sites above.

**Status bar shows the wrong time** — `override_status_bar` in the Snapfile pins
it to 9:41. Capturing through Xcode directly bypasses that, which is why the
lane is the supported path.
