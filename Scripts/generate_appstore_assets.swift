#!/usr/bin/env swift
//
// Renders Tapper's branded App Store screenshots and README artwork.
//
//     swift Scripts/generate_appstore_assets.swift
//
// or, more usually, via the lane that captures fresh screenshots first:
//
//     bundle exec fastlane screenshots
//
// Captions, palettes, and device targets all come from Marketing/copy.json.
// Run it from the repository root, or set TAPPER_PROJECT_ROOT.
//
// Environment overrides:
//   TAPPER_PROJECT_ROOT   repository root (default: current directory)
//   SCREENSHOT_INPUT_DIR  where raw captures live (default: search order below)
//   APPSTORE_OUTPUT_DIR   App Store asset output (default: AppStoreAssets)
//   DOCS_ASSET_DIR        README artwork output (default: docs/assets)

import AppKit
import Foundation

// MARK: - Paths

let environment = ProcessInfo.processInfo.environment

let projectRoot = URL(
    fileURLWithPath: environment["TAPPER_PROJECT_ROOT"] ?? FileManager.default.currentDirectoryPath,
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
let legacyCaptureRoot = projectRoot.appendingPathComponent("AppStoreSimulatorCaptures", isDirectory: true)
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
        let mirrorsToLegacyCaptures: Bool?

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
            throw GenerationError(message: "Missing marketing copy at \(copyFile.path). Run from the repository root or set TAPPER_PROJECT_ROOT.")
        }
        return try JSONDecoder().decode(MarketingCopy.self, from: try Data(contentsOf: copyFile))
    } catch {
        fail(error)
    }
}

let copy = loadCopy()

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
    candidates.append(legacyCaptureRoot.appendingPathComponent(screenshot.plainFilename))

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
func drawInsetScreenshot(_ source: NSImage, in rect: NSRect, cornerRadius: CGFloat, shadowBlur: CGFloat, shadowOffset: CGFloat, shadowAlpha: CGFloat = 0.34, strokeWidth: CGFloat) {
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
    let iconURL = projectRoot.appendingPathComponent("Tapper/Assets.xcassets/AppIcon.appiconset/appstore.png")
    let icon = FileManager.default.fileExists(atPath: iconURL.path) ? try loadImage(iconURL) : nil

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
    let source = projectRoot.appendingPathComponent("Tapper/Assets.xcassets/AppIcon.appiconset/appstore.png")
    guard FileManager.default.fileExists(atPath: source.path) else {
        throw GenerationError(message: "Missing app icon at \(source.path)")
    }

    let destination = directory.appendingPathComponent(filename)

    guard let width else {
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: source, to: destination)
        return
    }

    let icon = try loadImage(source)
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
    # Tapper App Store Assets

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
        : "committed captures in `AppStoreSimulatorCaptures`"

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

            // The 6.9-inch pass doubles as the source for README artwork and for
            // the committed captures that let `fastlane marketing` run offline.
            if target.mirrorsToLegacyCaptures == true {
                heroSources.append(source)
                featureBitmaps.append((item.id, showcase))

                if usingFastlaneCaptures {
                    try FileManager.default.createDirectory(at: legacyCaptureRoot, withIntermediateDirectories: true)
                    let mirrored = legacyCaptureRoot.appendingPathComponent(item.plainFilename)
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
    throw GenerationError(message: "No target is marked `mirrorsToLegacyCaptures`, so there is no source for README artwork.")
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
