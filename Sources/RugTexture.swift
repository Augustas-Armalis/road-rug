import Cocoa
import Metal

func makeBitmap(_ w: Int, _ h: Int) -> CGContext {
    CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
              space: CGColorSpace(name: CGColorSpace.sRGB)!,
              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}

func makeTexture(device: MTLDevice, from ctx: CGContext, mipmapped: Bool, queue: MTLCommandQueue?) -> MTLTexture? {
    let w = ctx.width, h = ctx.height
    let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: w, height: h, mipmapped: mipmapped)
    d.usage = .shaderRead
    guard let t = device.makeTexture(descriptor: d), let data = ctx.data else { return nil }
    t.replace(region: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0, withBytes: data, bytesPerRow: ctx.bytesPerRow)
    if mipmapped, let cb = queue?.makeCommandBuffer(), let blit = cb.makeBlitCommandEncoder() {
        blit.generateMipmaps(for: t)
        blit.endEncoding()
        cb.commit()
        cb.waitUntilCompleted()
    }
    return t
}

/// The city-roads play mat texture (Resources/rug.png),
/// drawn as-is: rounded corners and the bound edge are added by the shader.
func paintRug() -> CGContext {
    let img = Bundle.main.url(forResource: "rug", withExtension: "png")
        .flatMap { NSImage(contentsOf: $0)?.cgImage(forProposedRect: nil, context: nil, hints: nil) }
    if img == nil { NSLog("Road Rug: rug.png missing from the app bundle; using a plain rug") }
    let w = img?.width ?? 1024, h = img?.height ?? 544
    let ctx = makeBitmap(w, h)
    let full = CGRect(x: 0, y: 0, width: w, height: h)
    ctx.setFillColor(CGColor(srgbRed: 0.36, green: 0.37, blue: 0.40, alpha: 1))
    ctx.fill(full)
    if let img {
        ctx.interpolationQuality = .high
        ctx.draw(img, in: full)
    }
    return ctx
}

/// Desktop-style icon + label for an item hidden under the rug (100x100 pt, drawn @2x).
func makeIconTexture(device: MTLDevice, url: URL) -> MTLTexture? {
    let scale = 2, size = 100
    let ctx = makeBitmap(size * scale, size * scale)
    ctx.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
    let icon = NSWorkspace.shared.icon(forFile: url.path)
    icon.draw(in: NSRect(x: 18, y: 34, width: 64, height: 64))
    let para = NSMutableParagraphStyle()
    para.alignment = .center
    para.lineBreakMode = .byTruncatingMiddle
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.85)
    shadow.shadowBlurRadius = 2
    shadow.shadowOffset = NSSize(width: 0, height: -1)
    let name = FileManager.default.displayName(atPath: url.path) as NSString
    name.draw(in: NSRect(x: 2, y: 12, width: 96, height: 18), withAttributes: [
        .font: NSFont.systemFont(ofSize: 12, weight: .medium),
        .foregroundColor: NSColor.white,
        .paragraphStyle: para,
        .shadow: shadow,
    ])
    NSGraphicsContext.restoreGraphicsState()
    return makeTexture(device: device, from: ctx, mipmapped: false, queue: nil)
}
