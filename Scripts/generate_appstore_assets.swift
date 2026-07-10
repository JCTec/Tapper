import AppKit
import Foundation

let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outputRoot = projectRoot.appendingPathComponent("AppStoreAssets", isDirectory: true)
let plainOutput = outputRoot.appendingPathComponent("iPhone-6.9-plain", isDirectory: true)
let showcaseOutput = outputRoot.appendingPathComponent("iPhone-6.9-showcase", isDirectory: true)
let simulatorCaptureRoot = projectRoot.appendingPathComponent("AppStoreSimulatorCaptures", isDirectory: true)
let downloadsRoot = URL(fileURLWithPath: "/Users/jc/Downloads", isDirectory: true)

let targetWidth: CGFloat = 1320
let targetHeight: CGFloat = 2868
let targetSize = NSSize(width: targetWidth, height: targetHeight)

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

func rectFromTop(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> NSRect {
    NSRect(x: x, y: targetHeight - y - height, width: width, height: height)
}

func drawText(
    _ text: String,
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
    let rect = rectFromTop(x: (targetWidth - width) / 2, y: topY, width: width, height: height)
    attributed.draw(in: rect)
}

func renderBitmap(_ draw: () -> Void) throws -> NSBitmapImageRep {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(targetWidth),
        pixelsHigh: Int(targetHeight),
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

    bitmap.size = targetSize
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

func renderPlain(source: NSImage, to url: URL) throws {
    let output = try renderBitmap {
        NSColor.black.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: targetSize)).fill()
        source.draw(
            in: aspectFillRect(source: source.size, target: targetSize),
            from: NSRect(origin: .zero, size: source.size),
            operation: .sourceOver,
            fraction: 1
        )
    }
    try savePNG(output, to: url)
}

func renderShowcase(source: NSImage, item: ScreenshotSource, to url: URL) throws {
    let output = try renderBitmap {
        let fullRect = NSRect(origin: .zero, size: targetSize)
        let gradient = NSGradient(starting: item.backgroundTop, ending: item.backgroundBottom)
        gradient?.draw(in: fullRect, angle: -90)

        drawText(
            item.title,
            topY: 145,
            width: 1060,
            font: NSFont.systemFont(ofSize: 92, weight: .black),
            color: item.titleColor,
            lineHeight: 106
        )
        drawText(
            item.subtitle,
            topY: 270,
            width: 1040,
            font: NSFont.systemFont(ofSize: 44, weight: .semibold),
            color: item.subtitleColor,
            lineHeight: 56
        )

        let phoneWidth: CGFloat = 946
        let phoneHeight = phoneWidth * source.size.height / source.size.width
        let phoneRect = rectFromTop(
            x: (targetWidth - phoneWidth) / 2,
            y: 505,
            width: phoneWidth,
            height: phoneHeight
        )
        let cornerRadius: CGFloat = 76
        let phonePath = NSBezierPath(roundedRect: phoneRect, xRadius: cornerRadius, yRadius: cornerRadius)

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.34)
        shadow.shadowBlurRadius = 54
        shadow.shadowOffset = NSSize(width: 0, height: -22)
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
        phonePath.lineWidth = 3
        phonePath.stroke()
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

    To refresh from Simulator, run `AppStoreScreenshotUITests`, copy or export `01-dashboard.png` through `04-squats.png` into `/Users/jc/Dev/Tapper/AppStoreSimulatorCaptures`, then rerun `swift Scripts/generate_appstore_assets.swift`.

    Apple currently accepts `1320x2868` portrait screenshots for 6.9-inch iPhone displays.

    """
    try readme.write(to: outputRoot.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
}

try removeAndCreateDirectory(outputRoot)
try FileManager.default.createDirectory(at: plainOutput, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: showcaseOutput, withIntermediateDirectories: true)

for item in sources {
    let image = try loadImage(item.input)
    try renderPlain(source: image, to: plainOutput.appendingPathComponent(item.plainFilename))
    try renderShowcase(source: image, item: item, to: showcaseOutput.appendingPathComponent(item.showcaseFilename))
}

try copyIcon()
try writeReadme()

print("Generated App Store assets in \(outputRoot.path)")
