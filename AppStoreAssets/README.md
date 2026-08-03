# Tapper App Store Assets

Generated from screenshots in `/Users/jc/Dev/Tapper/AppStoreSimulatorCaptures` on 2026-06-30.

## Contents

- `AppIcon-1024.png`: copied from the app icon asset catalog.
- `iPhone-6.9-plain/`: exact-size, upload-ready screenshots at `1320x2868`.
- `iPhone-6.9-showcase/`: App Store-style screenshots with short captions at `1320x2868`.
- `iPhone-6.5-plain/`: exact-size, upload-ready screenshots at `1242x2688`.
- `iPhone-6.5-showcase/`: App Store-style screenshots with short captions at `1242x2688`.
- `iPad-13-previews/`: three App Store-style iPad previews at `2064x2752`.

To refresh from Simulator, run `AppStoreScreenshotUITests`, copy or export `01-dashboard.png` through `04-squats.png` into `/Users/jc/Dev/Tapper/AppStoreSimulatorCaptures`, then rerun `swift Scripts/generate_appstore_assets.swift`.

Apple currently accepts `1320x2868` portrait screenshots for 6.9-inch iPhone displays, `1242x2688` portrait screenshots for 6.5-inch iPhone displays, and `2064x2752` portrait screenshots for iPad 13-inch displays.
