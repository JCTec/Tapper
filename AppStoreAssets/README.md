# Tapper App Store Assets

Generated from fastlane snapshot captures in `fastlane/screenshots/en-US` on 2026-08-04.

**This directory is generated — do not edit it by hand.** Every run replaces
its entire contents. Captions and palettes live in `Marketing/copy.json`.

## Contents

- `AppIcon-1024.png`: copied from the app icon asset catalog.
- `iPhone-6.9-plain/`: exact-size, upload-ready screenshots at `1320x2868`.
- `iPhone-6.9-showcase/`: captioned App Store screenshots at `1320x2868`.
- `iPhone-6.5-plain/`: exact-size, upload-ready screenshots at `1242x2688`.
- `iPhone-6.5-showcase/`: captioned App Store screenshots at `1242x2688`.
- `iPad-13-previews/`: captioned App Store screenshots at `2064x2752` (3 images).

## Refreshing

```sh
bundle exec fastlane screenshots   # capture on every device, then render
bundle exec fastlane marketing     # re-render from existing captures
```

Apple currently accepts `1320x2868` for iPhone 6.9-inch displays, `1242x2688` for iPhone 6.5-inch displays, `2064x2752` for iPad 13-inch displays.
