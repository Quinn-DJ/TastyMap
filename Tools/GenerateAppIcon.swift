import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: swift GenerateAppIcon.swift <output-directory>\n", stderr)
    exit(64)
}

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1])
let sizes = [16, 32, 64, 128, 256, 512, 1024]

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
}

func drawIcon(size: Int) throws -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "TastyMapIcon", code: 1)
    }

    let context = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    defer { NSGraphicsContext.restoreGraphicsState() }

    let scale = CGFloat(size) / 1024
    color(0.063, 0.086, 0.082).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: size, height: size)).fill()

    for index in 0..<4 {
        let offset = CGFloat(index) * 54 * scale
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 60 * scale + offset, y: 190 * scale))
        path.curve(
            to: NSPoint(x: 980 * scale, y: 780 * scale - offset),
            controlPoint1: NSPoint(x: 260 * scale, y: 580 * scale),
            controlPoint2: NSPoint(x: 610 * scale, y: 260 * scale + offset)
        )
        path.lineWidth = max(1, 3 * scale)
        path.setLineDash([10 * scale, 14 * scale], count: 2, phase: 0)
        color(0.208, 0.420, 0.400, 0.20).setStroke()
        path.stroke()
    }

    let pinCircle = NSRect(
        x: 262 * scale,
        y: 354 * scale,
        width: 500 * scale,
        height: 500 * scale
    )
    let pinTail = NSBezierPath()
    pinTail.move(to: NSPoint(x: 342 * scale, y: 488 * scale))
    pinTail.line(to: NSPoint(x: 512 * scale, y: 154 * scale))
    pinTail.line(to: NSPoint(x: 682 * scale, y: 488 * scale))
    pinTail.close()

    color(0.953, 0.941, 0.906).setFill()
    NSBezierPath(ovalIn: pinCircle.insetBy(dx: -20 * scale, dy: -20 * scale)).fill()
    pinTail.lineWidth = 40 * scale
    pinTail.lineJoinStyle = .round
    color(0.953, 0.941, 0.906).setStroke()
    pinTail.stroke()
    NSBezierPath(ovalIn: pinCircle.insetBy(dx: 18 * scale, dy: 18 * scale)).fill()

    color(0.890, 0.635, 0.231).setFill()
    NSBezierPath(ovalIn: pinCircle.insetBy(dx: 54 * scale, dy: 54 * scale)).fill()
    pinTail.lineWidth = 68 * scale
    pinTail.lineJoinStyle = .round
    color(0.890, 0.635, 0.231).setStroke()
    pinTail.stroke()

    if let fork = NSImage(
        systemSymbolName: "fork.knife",
        accessibilityDescription: nil
    )?.withSymbolConfiguration(
        NSImage.SymbolConfiguration(pointSize: 230 * scale, weight: .bold)
    ) {
        let symbolRect = NSRect(
            x: 355 * scale,
            y: 432 * scale,
            width: 314 * scale,
            height: 314 * scale
        )
        fork.isTemplate = true
        color(0.125, 0.094, 0.055).set()
        fork.draw(in: symbolRect)
    }

    let badgeCircle = NSRect(
        x: 634 * scale,
        y: 174 * scale,
        width: 210 * scale,
        height: 210 * scale
    )
    color(0.612, 0.243, 0.145).setFill()
    NSBezierPath(ovalIn: badgeCircle).fill()

    let star = NSBezierPath()
    let starCenter = NSPoint(x: 739 * scale, y: 279 * scale)
    let outerRadius = 67 * scale
    let innerRadius = 29 * scale
    for index in 0..<10 {
        let angle = -Double.pi / 2 + Double(index) * Double.pi / 5
        let radius = index.isMultiple(of: 2) ? outerRadius : innerRadius
        let point = NSPoint(
            x: starCenter.x + CGFloat(cos(angle)) * radius,
            y: starCenter.y + CGFloat(sin(angle)) * radius
        )
        if index == 0 {
            star.move(to: point)
        } else {
            star.line(to: point)
        }
    }
    star.close()
    color(0.953, 0.941, 0.906).setFill()
    star.fill()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "TastyMapIcon", code: 2)
    }
    return data
}

try FileManager.default.createDirectory(
    at: outputDirectory,
    withIntermediateDirectories: true
)

for size in sizes {
    let data = try drawIcon(size: size)
    try data.write(
        to: outputDirectory.appendingPathComponent("AppIcon-\(size).png"),
        options: .atomic
    )
}

print("Generated \(sizes.count) app icon files in \(outputDirectory.path)")
