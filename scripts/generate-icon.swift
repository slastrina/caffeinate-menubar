// Generate Resources/AppIcon.icns from the cup.and.saucer.fill SF Symbol.
// Renders every size required by macOS into an AppIcon.iconset/, then shells
// out to /usr/bin/iconutil to produce the final .icns.
//
// Run once from the repo root:
//   swift scripts/generate-icon.swift
//
// The output (Resources/AppIcon.icns) is checked in. Only regenerate if you
// want to change the icon design.

import AppKit
import Foundation

let sizes: [(name: String, px: Int)] = [
    ("icon_16x16",      16),
    ("icon_16x16@2x",   32),
    ("icon_32x32",      32),
    ("icon_32x32@2x",   64),
    ("icon_128x128",    128),
    ("icon_128x128@2x", 256),
    ("icon_256x256",    256),
    ("icon_256x256@2x", 512),
    ("icon_512x512",    512),
    ("icon_512x512@2x", 1024),
]

let iconsetDir = URL(fileURLWithPath: "build/AppIcon.iconset")
let resourcesDir = URL(fileURLWithPath: "Resources")
let icnsPath = resourcesDir.appendingPathComponent("AppIcon.icns")

try? FileManager.default.removeItem(at: iconsetDir)
try FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: resourcesDir, withIntermediateDirectories: true)

// Coffee-brown background with a white SF Symbol overlay.
let backgroundColor = NSColor(srgbRed: 0.45, green: 0.27, blue: 0.16, alpha: 1.0)
let symbolColor = NSColor.white

func renderIcon(pixelSize: Int) -> Data? {
    let side = CGFloat(pixelSize)
    let cornerRadius = side * 0.22

    // Bitmap with explicit pixel dimensions — bypasses NSImage's backing-scale doubling.
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { return nil }
    rep.size = NSSize(width: side, height: side)

    guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else { return nil }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx

    // Rounded-rect background
    let bgPath = NSBezierPath(
        roundedRect: NSRect(x: 0, y: 0, width: side, height: side),
        xRadius: cornerRadius,
        yRadius: cornerRadius
    )
    backgroundColor.setFill()
    bgPath.fill()

    // SF Symbol foreground, tinted white, centered
    let symbolPointSize = side * 0.58
    let baseConfig = NSImage.SymbolConfiguration(pointSize: symbolPointSize, weight: .regular)
    let symbolConfig = baseConfig.applying(NSImage.SymbolConfiguration(paletteColors: [symbolColor]))

    if let baseSymbol = NSImage(systemSymbolName: "cup.and.saucer.fill",
                                accessibilityDescription: nil),
       let symbol = baseSymbol.withSymbolConfiguration(symbolConfig) {
        let symbolSize = symbol.size
        let origin = NSPoint(
            x: (side - symbolSize.width) / 2,
            y: (side - symbolSize.height) / 2 - side * 0.02
        )
        symbol.draw(at: origin, from: .zero, operation: .sourceOver, fraction: 1.0)
    }

    NSGraphicsContext.restoreGraphicsState()

    return rep.representation(using: .png, properties: [:])
}

for size in sizes {
    guard let data = renderIcon(pixelSize: size.px) else {
        fputs("Failed to render \(size.name)\n", stderr)
        exit(1)
    }
    let outURL = iconsetDir.appendingPathComponent("\(size.name).png")
    try data.write(to: outURL)
    print("wrote \(size.name).png (\(size.px)x\(size.px))")
}

// Invoke iconutil to roll the iconset into a single .icns
let proc = Process()
proc.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
proc.arguments = ["-c", "icns", iconsetDir.path, "-o", icnsPath.path]
try proc.run()
proc.waitUntilExit()
guard proc.terminationStatus == 0 else {
    fputs("iconutil failed with status \(proc.terminationStatus)\n", stderr)
    exit(Int32(proc.terminationStatus))
}

print("==> Wrote \(icnsPath.path)")
