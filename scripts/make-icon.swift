// Generates Resources/AppIcon.icns from the rug texture: a rounded square of the road mat with a
// soft shadow, in the macOS icon grid. Run from the repo root:  swift scripts/make-icon.swift
import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let texture = NSImage(contentsOf: root.appendingPathComponent("Resources/rug.png"))!
    .cgImage(forProposedRect: nil, context: nil, hints: nil)!
let iconset = root.appendingPathComponent("build/AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
try! FileManager.default.createDirectory(at: root.appendingPathComponent("docs"), withIntermediateDirectories: true)

func render(_ px: Int) -> Data {
    let s = CGFloat(px)
    let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: px * 4,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    // macOS icon grid: 824/1024 body, 185/1024 corner radius.
    let inset = s * 100 / 1024
    let body = CGRect(x: inset, y: inset, width: s - 2 * inset, height: s - 2 * inset)
    let path = CGPath(roundedRect: body, cornerWidth: s * 185 / 1024, cornerHeight: s * 185 / 1024, transform: nil)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.012), blur: s * 0.03,
                  color: CGColor(gray: 0, alpha: 0.35))
    ctx.addPath(path)
    ctx.setFillColor(CGColor(srgbRed: 0.29, green: 0.30, blue: 0.33, alpha: 1))
    ctx.fillPath()
    ctx.restoreGState()

    // A square crop from the middle of the mat, slightly zoomed so the roads read at small sizes.
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    let crop = CGFloat(texture.height) * 0.62
    let src = CGRect(x: (CGFloat(texture.width) - crop) / 2, y: (CGFloat(texture.height) - crop) / 2,
                     width: crop, height: crop)
    ctx.interpolationQuality = .high
    ctx.draw(texture.cropping(to: src)!, in: body)
    // Gentle top light, like the pile catching it.
    let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                              colors: [CGColor(gray: 1, alpha: 0.18), CGColor(gray: 0, alpha: 0.12)] as CFArray,
                              locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: body.maxY), end: CGPoint(x: 0, y: body.minY), options: [])
    ctx.restoreGState()

    // Bound edge.
    ctx.addPath(path)
    ctx.setStrokeColor(CGColor(srgbRed: 0.24, green: 0.25, blue: 0.28, alpha: 1))
    ctx.setLineWidth(s * 0.03)
    ctx.strokePath()

    return NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!
}

for base in [16, 32, 128, 256, 512] {
    try! render(base).write(to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try! render(base * 2).write(to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
let out = root.appendingPathComponent("Resources/AppIcon.icns")
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", out.path]
try! task.run()
task.waitUntilExit()
try! render(512).write(to: root.appendingPathComponent("docs/icon.png"))
print("Wrote \(out.path)")
