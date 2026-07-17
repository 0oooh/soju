// Renders the Soju app icon and writes Resources/AppIcon.icns + AppIcon.png.
// Run from the repo root: swift Scripts/make-icon.swift
// The generated icns is committed, so CI never needs to run this.

import AppKit
import CoreGraphics
import Foundation

let canvas = 1024
let repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resources = repoRoot.appendingPathComponent("Resources")
try? FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)

guard let context = CGContext(
    data: nil, width: canvas, height: canvas, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("no context") }

let size = CGFloat(canvas)

// macOS icon grid: full-bleed rounded square with a transparent margin.
let plate = CGRect(x: 100, y: 100, width: 824, height: 824)
let platePath = CGPath(roundedRect: plate, cornerWidth: 185, cornerHeight: 185, transform: nil)

// Soju-green vertical gradient.
context.saveGState()
context.addPath(platePath)
context.clip()
let colors = [
    CGColor(srgbRed: 0.180, green: 0.720, blue: 0.440, alpha: 1),   // light jade, top
    CGColor(srgbRed: 0.000, green: 0.478, blue: 0.290, alpha: 1),   // deep bottle green, bottom
] as CFArray
let gradient = CGGradient(colorsSpace: nil, colors: colors, locations: [0, 1])!
context.drawLinearGradient(
    gradient,
    start: CGPoint(x: size / 2, y: plate.maxY),
    end: CGPoint(x: size / 2, y: plate.minY),
    options: []
)

// Subtle top sheen, like light on glass.
let sheen = CGGradient(colorsSpace: nil, colors: [
    CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.18),
    CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0),
] as CFArray, locations: [0, 1])!
context.drawLinearGradient(
    sheen,
    start: CGPoint(x: size / 2, y: plate.maxY),
    end: CGPoint(x: size / 2, y: plate.maxY - 330),
    options: []
)
context.restoreGState()

// Soju bottle silhouette: cap, short neck flaring into square shoulders,
// straight body. Centered, slightly below optical center.
let bottle = CGMutablePath()
let cx = size / 2
let bodyW: CGFloat = 300
let bodyBottom: CGFloat = 236
let bodyTop: CGFloat = 610       // shoulder line
let neckW: CGFloat = 118
let neckTop: CGFloat = 730
let capH: CGFloat = 58
let r: CGFloat = 40              // body corner radius

// Body with rounded bottom corners, straight sides up to the shoulder curve.
bottle.move(to: CGPoint(x: cx - bodyW / 2, y: bodyTop))
bottle.addLine(to: CGPoint(x: cx - bodyW / 2, y: bodyBottom + r))
bottle.addQuadCurve(to: CGPoint(x: cx - bodyW / 2 + r, y: bodyBottom), control: CGPoint(x: cx - bodyW / 2, y: bodyBottom))
bottle.addLine(to: CGPoint(x: cx + bodyW / 2 - r, y: bodyBottom))
bottle.addQuadCurve(to: CGPoint(x: cx + bodyW / 2, y: bodyBottom + r), control: CGPoint(x: cx + bodyW / 2, y: bodyBottom))
bottle.addLine(to: CGPoint(x: cx + bodyW / 2, y: bodyTop))
// Right shoulder into neck.
bottle.addQuadCurve(
    to: CGPoint(x: cx + neckW / 2, y: neckTop),
    control: CGPoint(x: cx + bodyW / 2, y: neckTop - 8)
)
// Neck top to the other side.
bottle.addLine(to: CGPoint(x: cx - neckW / 2, y: neckTop))
// Left shoulder back down.
bottle.addQuadCurve(
    to: CGPoint(x: cx - bodyW / 2, y: bodyTop),
    control: CGPoint(x: cx - bodyW / 2, y: neckTop - 8)
)
bottle.closeSubpath()

context.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.94))
context.addPath(bottle)
context.fillPath()

// Cap.
let cap = CGRect(x: cx - neckW / 2 - 6, y: neckTop + 8, width: neckW + 12, height: capH)
context.addPath(CGPath(roundedRect: cap, cornerWidth: 16, cornerHeight: 16, transform: nil))
context.fillPath()

// Label band across the body, in the plate green so it reads as a cutout.
let label = CGRect(x: cx - bodyW / 2 + 44, y: 320, width: bodyW - 88, height: 190)
context.setFillColor(CGColor(srgbRed: 0.000, green: 0.478, blue: 0.290, alpha: 0.55))
context.addPath(CGPath(roundedRect: label, cornerWidth: 22, cornerHeight: 22, transform: nil))
context.fillPath()

guard let master = context.makeImage() else { fatalError("no image") }

// Write master PNG (used by the README).
let pngURL = resources.appendingPathComponent("AppIcon.png")
let pngDest = CGImageDestinationCreateWithURL(pngURL as CFURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(pngDest, master, nil)
CGImageDestinationFinalize(pngDest)

// Build the iconset and convert with iconutil.
let iconset = resources.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

func writePNG(_ pixels: Int, _ name: String) {
    let scaled = CGContext(
        data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    scaled.interpolationQuality = .high
    scaled.draw(master, in: CGRect(x: 0, y: 0, width: pixels, height: pixels))
    let img = scaled.makeImage()!
    let url = iconset.appendingPathComponent(name)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, img, nil)
    CGImageDestinationFinalize(dest)
}

for size in [16, 32, 128, 256, 512] {
    writePNG(size, "icon_\(size)x\(size).png")
    writePNG(size * 2, "icon_\(size)x\(size)@2x.png")
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", resources.appendingPathComponent("AppIcon.icns").path]
try iconutil.run()
iconutil.waitUntilExit()
try? FileManager.default.removeItem(at: iconset)

print(iconutil.terminationStatus == 0 ? "AppIcon.icns written" : "iconutil failed")
exit(iconutil.terminationStatus)
