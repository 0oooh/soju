import AppKit
import Foundation

public enum Icns {
    /// Write an .icns file for an image by rendering an iconset and calling iconutil.
    public static func write(_ image: NSImage, to icnsURL: URL) throws {
        let fm = FileManager.default
        let iconset = icnsURL.deletingPathExtension().appendingPathExtension("iconset")
        try? fm.removeItem(at: iconset)
        try fm.createDirectory(at: iconset, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: iconset) }

        for size in [16, 32, 128, 256, 512] {
            try renderPNG(image, pixels: size, to: iconset.appendingPathComponent("icon_\(size)x\(size).png"))
            try renderPNG(image, pixels: size * 2, to: iconset.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
        }

        let iconutil = Process()
        iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
        iconutil.arguments = ["-c", "icns", iconset.path, "-o", icnsURL.path]
        try iconutil.run()
        iconutil.waitUntilExit()
        guard iconutil.terminationStatus == 0 else {
            throw CocoaError(.fileWriteUnknown)
        }
    }

    static func renderPNG(_ image: NSImage, pixels: Int, to url: URL) throws {
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) else { throw CocoaError(.fileWriteUnknown) }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(
            in: NSRect(x: 0, y: 0, width: pixels, height: pixels),
            from: .zero, operation: .copy, fraction: 1
        )
        NSGraphicsContext.restoreGraphicsState()

        guard let png = rep.representation(using: .png, properties: [:]) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try png.write(to: url)
    }
}
