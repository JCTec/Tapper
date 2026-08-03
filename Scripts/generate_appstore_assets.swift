import AppKit
import Foundation

let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outputRoot = projectRoot.appendingPathComponent("AppStoreAssets", isDirectory: true)
let simulatorCaptureRoot = projectRoot.appendingPathComponent("AppStoreSimulatorCaptures", isDirectory: true)
let downloadsRoot = URL(fileURLWithPath: "/Users/jc/Downloads", isDirectory: true)

struct ScreenshotTarget {
    let displayName: String
    let size: NSSize
    let plainDirectoryName: String
    let showcaseDirectoryName: String
    let acceptedDimensions: String
}

let targets = [
    ScreenshotTarget(
        displayName: "iPhone 6.9-inch",
        size: NSSize(width: 1320, height: 2868),
        plainDirectoryName: "iPhone-6.9-plain",
        showcaseDirectoryName: "iPhone-6.9-showcase",
        acceptedDimensions: "1320x2868"
    ),
    ScreenshotTarget(
        displayName: "iPhone 6.5-inch",
        size: NSSize(width: 1242, height: 2688),
        plainDirectoryName: "iPhone-6.5-plain",
        showcaseDirectoryName: "iPhone-6.5-showcase",
        acceptedDimensions: "1242x2688"
    )
]

let iPadPreviewTarget = ScreenshotTarget(
    displayName: "iPad 13-inch",
    size: NSSize(width: 2064, height: 2752),
    plainDirectoryName: "",
    showcaseDirectoryName: "iPad-13-previews",
    acceptedDimensions: "2064x2752"
)

struct ScreenshotSource {
    let input: URL
    let plainFilename: String
    let showcaseFilename: String
    let title: String
    let subtitle: String
    let backgroundTop: NSColor
    let backgroundBottom: NSColor
    let titleColor: NSColor
    let subtitleColor: NSColor
}

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
}

let expectedSimulatorCaptureNames = [
    "01-dashboard.png",
    "02-push-ups.png",
    "03-sit-ups.png",
    "04-squats.png"
]
let usesSimulatorCaptures = expectedSimulatorCaptureNames.allSatisfy { filename in
    FileManager.default.fileExists(atPath: simulatorCaptureRoot.appendingPathComponent(filename).path)
}
let sourceDescription = usesSimulatorCaptures
    ? simulatorCaptureRoot.path
    : downloadsRoot.path

func sourceURL(simulatorFilename: String, downloadFilename: String) -> URL {
    if usesSimulatorCaptures {
        return simulatorCaptureRoot.appendingPathComponent(simulatorFilename)
    }

    return downloadsRoot.appendingPathComponent(downloadFilename)
}

let sources: [ScreenshotSource] = [
    ScreenshotSource(
        input: sourceURL(
            simulatorFilename: "01-dashboard.png",
            downloadFilename: "photo_2026-06-30 08.25.08.jpeg"
        ),
        plainFilename: "01-dashboard.png",
        showcaseFilename: "01-all-your-counters.png",
        title: "All Your Counters",
        subtitle: "Colorful tappers, sorted and ready.",
        backgroundTop: color(8, 12, 28),
        backgroundBottom: color(17, 24, 48),
        titleColor: .white,
        subtitleColor: color(204, 211, 224)
    ),
    ScreenshotSource(
        input: sourceURL(
            simulatorFilename: "02-push-ups.png",
            downloadFilename: "photo_2026-06-30 08.25.18.jpeg"
        ),
        plainFilename: "02-push-ups.png",
        showcaseFilename: "02-tap-to-count.png",
        title: "Tap To Count",
        subtitle: "Big controls for quick sessions.",
        backgroundTop: color(255, 221, 79),
        backgroundBottom: color(249, 196, 44),
        titleColor: color(9, 12, 25),
        subtitleColor: color(57, 48, 21)
    ),
    ScreenshotSource(
        input: sourceURL(
            simulatorFilename: "03-sit-ups.png",
            downloadFilename: "photo_2026-06-30 08.25.11.jpeg"
        ),
        plainFilename: "03-sit-ups.png",
        showcaseFilename: "03-stay-in-flow.png",
        title: "Stay In Flow",
        subtitle: "Reset or edit without losing focus.",
        backgroundTop: color(244, 78, 62),
        backgroundBottom: color(226, 62, 56),
        titleColor: color(9, 12, 25),
        subtitleColor: color(47, 23, 25)
    ),
    ScreenshotSource(
        input: sourceURL(
            simulatorFilename: "04-squats.png",
            downloadFilename: "photo_2026-06-30 08.25.15.jpeg"
        ),
        plainFilename: "04-squats.png",
        showcaseFilename: "04-color-code-it.png",
        title: "Color Code It",
        subtitle: "Spot every counter at a glance.",
        backgroundTop: color(105, 207, 105),
        backgroundBottom: color(77, 184, 91),
        titleColor: color(9, 12, 25),
        subtitleColor: color(23, 58, 32)
    )
]

func removeAndCreateDirectory(_ url: URL) throws {
    if FileManager.default.fileExists(atPath: url.path) {
        try FileManager.default.removeItem(at: url)
    }
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
}

func loadImage(_ url: URL) throws -> NSImage {
    guard let image = NSImage(contentsOf: url) else {
        throw NSError(domain: "AppStoreAssets", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not load \(url.path)"])
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

func rectFromTop(target: ScreenshotTarget, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> NSRect {
    NSRect(x: x, y: target.size.height - y - height, width: width, height: height)
}

func drawText(
    _ text: String,
    target: ScreenshotTarget,
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
        target: target,
        x: (target.size.width - width) / 2,
        y: topY,
        width: width,
        height: height
    )
    attributed.draw(in: rect)
}

func renderBitmap(target: ScreenshotTarget, _ draw: () -> Void) throws -> NSBitmapImageRep {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(target.size.width),
        pixelsHigh: Int(target.size.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "AppStoreAssets", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not create bitmap context"])
    }

    bitmap.size = target.size
    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw NSError(domain: "AppStoreAssets", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not create graphics context"])
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    draw()
    NSGraphicsContext.restoreGraphicsState()

    return bitmap
}

func savePNG(_ bitmap: NSBitmapImageRep, to url: URL) throws {
    guard let png = bitmap.representation(using: .png, properties: [.compressionFactor: 0.9]) else {
        throw NSError(domain: "AppStoreAssets", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not encode \(url.path)"])
    }
    try png.write(to: url)
}

func renderPlain(source: NSImage, target: ScreenshotTarget, to url: URL) throws {
    let output = try renderBitmap(target: target) {
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

func renderShowcase(source: NSImage, item: ScreenshotSource, target: ScreenshotTarget, to url: URL) throws {
    let output = try renderBitmap(target: target) {
        let scale = min(target.size.width / 1320, target.size.height / 2868)
        let fullRect = NSRect(origin: .zero, size: target.size)
        let gradient = NSGradient(starting: item.backgroundTop, ending: item.backgroundBottom)
        gradient?.draw(in: fullRect, angle: -90)

        drawText(
            item.title,
            target: target,
            topY: 145 * scale,
            width: 1060 * scale,
            font: NSFont.systemFont(ofSize: 92 * scale, weight: .black),
            color: item.titleColor,
            lineHeight: 106 * scale
        )
        drawText(
            item.subtitle,
            target: target,
            topY: 270 * scale,
            width: 1040 * scale,
            font: NSFont.systemFont(ofSize: 44 * scale, weight: .semibold),
            color: item.subtitleColor,
            lineHeight: 56 * scale
        )

        let phoneWidth: CGFloat = 946 * scale
        let phoneHeight = phoneWidth * source.size.height / source.size.width
        let phoneRect = rectFromTop(
            target: target,
            x: (target.size.width - phoneWidth) / 2,
            y: 505 * scale,
            width: phoneWidth,
            height: phoneHeight
        )
        let cornerRadius: CGFloat = 76 * scale
        let phonePath = NSBezierPath(roundedRect: phoneRect, xRadius: cornerRadius, yRadius: cornerRadius)

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.34)
        shadow.shadowBlurRadius = 54 * scale
        shadow.shadowOffset = NSSize(width: 0, height: -22 * scale)
        shadow.set()
        NSColor.black.withAlphaComponent(0.16).setFill()
        phonePath.fill()
        NSGraphicsContext.restoreGraphicsState()

        NSGraphicsContext.saveGraphicsState()
        phonePath.addClip()
        source.draw(
            in: phoneRect,
            from: NSRect(origin: .zero, size: source.size),
            operation: .sourceOver,
            fraction: 1
        )
        NSGraphicsContext.restoreGraphicsState()

        NSColor.white.withAlphaComponent(0.18).setStroke()
        phonePath.lineWidth = 3 * scale
        phonePath.stroke()
    }
    try savePNG(output, to: url)
}

func renderIPadPreview(source: NSImage, item: ScreenshotSource, target: ScreenshotTarget, to url: URL) throws {
    let output = try renderBitmap(target: target) {
        let scale = min(target.size.width / 2064, target.size.height / 2752)
        let fullRect = NSRect(origin: .zero, size: target.size)
        let gradient = NSGradient(starting: item.backgroundTop, ending: item.backgroundBottom)
        gradient?.draw(in: fullRect, angle: -90)

        drawText(
            item.title,
            target: target,
            topY: 145 * scale,
            width: 1660 * scale,
            font: NSFont.systemFont(ofSize: 132 * scale, weight: .black),
            color: item.titleColor,
            lineHeight: 150 * scale
        )
        drawText(
            item.subtitle,
            target: target,
            topY: 325 * scale,
            width: 1580 * scale,
            font: NSFont.systemFont(ofSize: 62 * scale, weight: .semibold),
            color: item.subtitleColor,
            lineHeight: 78 * scale
        )

        let previewWidth: CGFloat = 1010 * scale
        let previewHeight = previewWidth * source.size.height / source.size.width
        let previewRect = rectFromTop(
            target: target,
            x: (target.size.width - previewWidth) / 2,
            y: 515 * scale,
            width: previewWidth,
            height: previewHeight
        )
        let cornerRadius: CGFloat = 74 * scale
        let previewPath = NSBezierPath(roundedRect: previewRect, xRadius: cornerRadius, yRadius: cornerRadius)

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.32)
        shadow.shadowBlurRadius = 70 * scale
        shadow.shadowOffset = NSSize(width: 0, height: -28 * scale)
        shadow.set()
        NSColor.black.withAlphaComponent(0.16).setFill()
        previewPath.fill()
        NSGraphicsContext.restoreGraphicsState()

        NSGraphicsContext.saveGraphicsState()
        previewPath.addClip()
        source.draw(
            in: previewRect,
            from: NSRect(origin: .zero, size: source.size),
            operation: .sourceOver,
            fraction: 1
        )
        NSGraphicsContext.restoreGraphicsState()

        NSColor.white.withAlphaComponent(0.18).setStroke()
        previewPath.lineWidth = 4 * scale
        previewPath.stroke()
    }
    try savePNG(output, to: url)
}

func copyIcon() throws {
    let source = projectRoot.appendingPathComponent("Tapper/Assets.xcassets/AppIcon.appiconset/appstore.png")
    let destination = outputRoot.appendingPathComponent("AppIcon-1024.png")
    if FileManager.default.fileExists(atPath: destination.path) {
        try FileManager.default.removeItem(at: destination)
    }
    try FileManager.default.copyItem(at: source, to: destination)
}

func writeReadme() throws {
    let readme = """
    # Tapper App Store Assets

    Generated from screenshots in `\(sourceDescription)` on 2026-06-30.

    ## Contents

    - `AppIcon-1024.png`: copied from the app icon asset catalog.
    - `iPhone-6.9-plain/`: exact-size, upload-ready screenshots at `1320x2868`.
    - `iPhone-6.9-showcase/`: App Store-style screenshots with short captions at `1320x2868`.
    - `iPhone-6.5-plain/`: exact-size, upload-ready screenshots at `1242x2688`.
    - `iPhone-6.5-showcase/`: App Store-style screenshots with short captions at `1242x2688`.
    - `iPad-13-previews/`: three App Store-style iPad previews at `2064x2752`.

    To refresh from Simulator, run `AppStoreScreenshotUITests`, copy or export `01-dashboard.png` through `04-squats.png` into `/Users/jc/Dev/Tapper/AppStoreSimulatorCaptures`, then rerun `swift Scripts/generate_appstore_assets.swift`.

    Apple currently accepts `1320x2868` portrait screenshots for 6.9-inch iPhone displays, `1242x2688` portrait screenshots for 6.5-inch iPhone displays, and `2064x2752` portrait screenshots for iPad 13-inch displays.

    """
    try readme.write(to: outputRoot.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
}

try removeAndCreateDirectory(outputRoot)
for target in targets {
    try FileManager.default.createDirectory(
        at: outputRoot.appendingPathComponent(target.plainDirectoryName, isDirectory: true),
        withIntermediateDirectories: true
    )
    try FileManager.default.createDirectory(
        at: outputRoot.appendingPathComponent(target.showcaseDirectoryName, isDirectory: true),
        withIntermediateDirectories: true
    )
}
try FileManager.default.createDirectory(
    at: outputRoot.appendingPathComponent(iPadPreviewTarget.showcaseDirectoryName, isDirectory: true),
    withIntermediateDirectories: true
)

for item in sources {
    let image = try loadImage(item.input)

    for target in targets {
        let plainOutput = outputRoot.appendingPathComponent(target.plainDirectoryName, isDirectory: true)
        let showcaseOutput = outputRoot.appendingPathComponent(target.showcaseDirectoryName, isDirectory: true)

        try renderPlain(source: image, target: target, to: plainOutput.appendingPathComponent(item.plainFilename))
        try renderShowcase(source: image, item: item, target: target, to: showcaseOutput.appendingPathComponent(item.showcaseFilename))
    }
}

let iPadPreviewOutput = outputRoot.appendingPathComponent(iPadPreviewTarget.showcaseDirectoryName, isDirectory: true)
for item in sources.prefix(3) {
    let image = try loadImage(item.input)
    try renderIPadPreview(
        source: image,
        item: item,
        target: iPadPreviewTarget,
        to: iPadPreviewOutput.appendingPathComponent(item.showcaseFilename)
    )
}

try copyIcon()
try writeReadme()

print("Generated App Store assets in \(outputRoot.path)")
