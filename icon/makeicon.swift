// Generates the Fitness Exporter app icon (same family as PaperDrop, PaperPress and
// Prospect: flat vivid tile, bold white glyph, soft shadows).
// Run: swift icon/makeicon.swift   (from the repo root)
//
// iOS differences from the macOS generators: the tile is a full-bleed opaque square
// with no baked corners (iOS applies its own mask), and only a 1024 px PNG is needed,
// written straight into the asset catalog. A 256 px preview lands in icon/ for eyeballing.
//
// Then optimise the PNGs. `make icon` does both steps; by hand:
//
//   swift icon/makeicon.swift
//   oxipng -o max --zopfli --strip safe FitnessExporter/Assets.xcassets/AppIcon.appiconset/icon.png icon/preview.png
//
// oxipng with Zopfli takes the 1024 px icon from ~95 KB to ~38 KB. ImageOptim gets a
// similar result on the preview but was slower than oxipng on the big one.
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let assetURL = URL(fileURLWithPath: "FitnessExporter/Assets.xcassets/AppIcon.appiconset/icon.png")
let previewURL = URL(fileURLWithPath: "icon/preview.png")

func draw(_ size: Int) -> CGImage {
    let s = CGFloat(size)
    let ctx = CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!

    // Flat tile. PaperDrop is blue, PaperPress vermillion, Prospect teal; health data
    // gets raspberry, warm without straying into the press's orange.
    let bg = CGColor(red: 0.86, green: 0.16, blue: 0.40, alpha: 1)
    ctx.setFillColor(bg)
    ctx.fill(CGRect(x: 0, y: 0, width: s, height: s))

    func softShadow() {
        ctx.setShadow(
            offset: CGSize(width: 0, height: -s * 0.012), blur: s * 0.025,
            color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.28))
    }

    // y measured from the top, like the other generators
    func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x * s, y: s - y * s) }

    // Heart: a classic two-lobe bezier in a unit box, mapped into the lower two thirds.
    let hx = 0.16, hy = 0.36, hw = 0.68, hh = 0.56
    func hp(_ x: Double, _ y: Double) -> CGPoint { pt(hx + x * hw, hy + y * hh) }
    let heart = CGMutablePath()
    heart.move(to: hp(0.5, 1.0))
    heart.addCurve(to: hp(0.0, 0.36), control1: hp(0.5, 1.0), control2: hp(0.0, 0.66))
    heart.addCurve(to: hp(0.27, 0.0), control1: hp(0.0, 0.14), control2: hp(0.12, 0.0))
    heart.addCurve(to: hp(0.5, 0.18), control1: hp(0.38, 0.0), control2: hp(0.47, 0.08))
    heart.addCurve(to: hp(0.73, 0.0), control1: hp(0.53, 0.08), control2: hp(0.62, 0.0))
    heart.addCurve(to: hp(1.0, 0.36), control1: hp(0.88, 0.0), control2: hp(1.0, 0.14))
    heart.addCurve(to: hp(0.5, 1.0), control1: hp(1.0, 0.66), control2: hp(0.5, 1.0))
    heart.closeSubpath()

    // Export arrow: bold, rising out of the heart's notch. Drawn with the heart as one
    // silhouette so the shadow reads as a single object.
    let shaftW = 0.11, headW = 0.32, apexY = 0.07, shaftBottom = hy + 0.30 * hh
    let headBase = apexY + headW * 0.62
    let arrow = CGMutablePath()
    arrow.move(to: pt(0.5 - shaftW / 2, shaftBottom))
    arrow.addLine(to: pt(0.5 + shaftW / 2, shaftBottom))
    arrow.addLine(to: pt(0.5 + shaftW / 2, headBase))
    arrow.addLine(to: pt(0.5 + headW / 2, headBase))
    arrow.addLine(to: pt(0.5, apexY))
    arrow.addLine(to: pt(0.5 - headW / 2, headBase))
    arrow.addLine(to: pt(0.5 - shaftW / 2, headBase))
    arrow.closeSubpath()

    // Fill the two shapes separately inside a transparency layer: the shadow is
    // applied once to the merged result, and the overlap cannot cancel out the way
    // it would with a single nonzero-winding fill of two opposing paths.
    softShadow()
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    ctx.addPath(heart)
    ctx.fillPath()
    ctx.addPath(arrow)
    ctx.fillPath()
    ctx.endTransparencyLayer()

    // Pulse trace cut back out in the tile colour, clipped to the heart so it can never
    // escape the edge. Same grammar as the text lines on the pages of the other icons.
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    ctx.saveGState()
    ctx.addPath(heart)
    ctx.clip()
    ctx.setStrokeColor(bg)
    ctx.setLineWidth(s * 0.042)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    let baseline = 0.50
    let trace: [(Double, Double)] = [
        (0.00, baseline), (0.30, baseline), (0.38, 0.34), (0.48, 0.72),
        (0.56, 0.40), (0.62, baseline), (1.00, baseline)
    ]
    ctx.move(to: hp(trace[0].0, trace[0].1))
    for (x, y) in trace.dropFirst() { ctx.addLine(to: hp(x, y)) }
    ctx.strokePath()
    ctx.restoreGState()

    return ctx.makeImage()!
}

func write(_ image: CGImage, to url: URL) {
    let dest = CGImageDestinationCreateWithURL(
        url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

write(draw(1024), to: assetURL)
write(draw(256), to: previewURL)
print("icon written to \(assetURL.path) (preview: \(previewURL.path))")
