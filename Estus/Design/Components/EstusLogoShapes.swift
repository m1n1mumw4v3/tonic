import SwiftUI

// MARK: - Estus Logo Shapes
// One `Shape` per glyph of `estus-logo-01.svg` (viewBox 0 0 6160 1280).
// Every shape lives in the same 6160×1280 space and is fitted uniformly to
// the rect it's given, so layering them in one 6160:1280 frame reproduces
// the full lockup.

enum EstusLogoGeometry {
    static let viewBox = CGSize(width: 6160, height: 1280)
    static let aspectRatio = viewBox.width / viewBox.height

    /// Mark center in SVG units. The mark is symmetric under a 180° turn.
    static let markCenter = CGPoint(x: 5760, y: 400)
    /// Whole-logo center in SVG units.
    static let logoCenter = CGPoint(x: 3080, y: 640)

    static let e = SVGPathParser.path(from: "M880,840h0c0,110.46-89.54,200-200,200h-160c-110.46,0-200-89.54-200-200h0v-80h880l.29-200c0-320.22-320.13-480.35-480.2-480.35h-240.1C320,79.65,0,240,0,560v200l3.31-.78c.03.39.06.78.1,1.16l-3.41-.39v40c0,320,320,480,480,480h240c159.03,0,476.13-157.83,479.95-434.93.03-1.69.05-3.38.05-5.07h-320ZM320,416c0-53.02,42.98-96,96-96h368c53.02,0,96,42.98,96,96v10.82c0,53.02-42.98,96-96,96h-368c-53.02,0-96-42.98-96-96v-10.82Z")

    static let s1 = SVGPathParser.path(from: "M1560,448.77v-8.77c0-66.27,53.73-120,120-120h200c88.37,0,160,71.63,160,160v40h320v-80c0-280-280-360-440-360h-240c-160,0-440,80-440,360v21.38c0,128.48,87.44,240.48,212.09,271.64l557.61,139.4c17.81,4.45,30.3,20.45,30.3,38.81v8.77c0,66.27-53.73,120-120,120h-200c-88.37,0-160-71.63-160-160v-40h-320v80c0,280,280.03,359.83,440,359.83v.17h240v-.17c159.97,0,440-79.83,440-359.83v-21.38c0-128.48-87.44-240.48-212.09-271.64l-557.61-139.4c-17.81-4.45-30.3-20.45-30.3-38.81Z")

    static let t = SVGPathParser.path(from: "M3039.71,520v-240h-320V0h-320v960c0,160,80,319.83,320,319.83l120,.17h200v-260h-320v-500h320Z")

    static let u = SVGPathParser.path(from: "M3879.96,80v760h.07c0,110.46-89.54,200-200,200h-80c-110.46,0-200-89.54-200-200h0s-.07,0-.07,0V80h-319.96v800c.12,319.88,280.03,399.83,440,399.83v.17h240v-.17c159.97,0,439.88-79.94,440-399.83V80s-320.04,0-320.04,0Z")

    static let s2 = SVGPathParser.path(from: "M4560.29,448.77v-8.77c0-66.27,53.73-120,120-120h200c88.37,0,160,71.63,160,160v40h320v-80c0-280-280-360-440-360h-240c-160,0-440,80-440,360v21.38c0,128.48,87.44,240.48,212.09,271.64l557.61,139.4c17.81,4.45,30.3,20.45,30.3,38.81v8.77c0,66.27-53.73,120-120,120h-200c-88.37,0-160-71.63-160-160v-40h-320v80c0,280,280.03,359.83,440,359.83v.17h240v-.17c159.97,0,440-79.83,440-359.83v-21.38c0-128.48-87.44-240.48-212.09-271.64l-557.61-139.4c-17.81-4.45-30.3-20.45-30.3-38.81Z")

    static let mark = SVGPathParser.path(from: "M5734.25,680h1.38c23.26,0,45.02,11.56,57.93,30.9,35.86,53.71,97.01,89.09,166.44,89.1,110.3,0,200.01-89.7,200.01-200.01,0-69.43-35.38-130.58-89.1-166.44-19.34-12.91-30.9-34.68-30.9-57.93v-1.38c0-20.5,9.16-39.81,24.66-53.23,33.89-29.34,55.34-72.67,55.34-121.02,0-88.57-71.43-160-160-160-48.34,0-91.68,21.44-121.01,55.34-13.42,15.5-32.72,24.66-53.23,24.66h-1.38c-23.26,0-45.02-11.56-57.93-30.9C5690.59,35.39,5629.44,0,5560.01,0c-110.3,0-200.01,89.7-200.01,200.01,0,69.43,35.38,130.58,89.1,166.44,19.34,12.91,30.9,34.68,30.9,57.93v1.38c0,20.5-9.16,39.81-24.66,53.23-33.89,29.34-55.34,72.67-55.34,121.01,0,88.57,71.43,160.01,160,160,48.34,0,91.68-21.44,121.02-55.34,13.42-15.5,32.72-24.66,53.23-24.66ZM5640,425.12h0c0-23.73,11.86-45.86,31.54-59.11,21.48-14.46,40.01-32.99,54.47-54.47,13.25-19.69,35.38-31.54,59.11-31.54h0c20.75,0,40.38,9.13,53.98,24.8,4.98,5.74,10.35,11.11,16.09,16.09,15.67,13.6,24.8,33.23,24.8,53.98h0c0,23.73-11.86,45.86-31.54,59.11-21.49,14.46-40.01,32.99-54.47,54.47-13.25,19.69-35.38,31.54-59.11,31.54h0c-20.75,0-40.38-9.13-53.98-24.8-4.98-5.74-10.35-11.11-16.09-16.09-15.67-13.6-24.8-33.23-24.8-53.98Z")

    /// Scales a path from SVG space to fit `rect` uniformly, centered.
    static func fitted(_ path: Path, in rect: CGRect) -> Path {
        let k = min(rect.width / viewBox.width, rect.height / viewBox.height)
        let dx = rect.minX + (rect.width - viewBox.width * k) / 2
        let dy = rect.minY + (rect.height - viewBox.height * k) / 2
        return path.applying(CGAffineTransform(a: k, b: 0, c: 0, d: k, tx: dx, ty: dy))
    }
}

struct EstusLogoE: Shape {
    func path(in rect: CGRect) -> Path { EstusLogoGeometry.fitted(EstusLogoGeometry.e, in: rect) }
}

struct EstusLogoS1: Shape {
    func path(in rect: CGRect) -> Path { EstusLogoGeometry.fitted(EstusLogoGeometry.s1, in: rect) }
}

struct EstusLogoT: Shape {
    func path(in rect: CGRect) -> Path { EstusLogoGeometry.fitted(EstusLogoGeometry.t, in: rect) }
}

struct EstusLogoU: Shape {
    func path(in rect: CGRect) -> Path { EstusLogoGeometry.fitted(EstusLogoGeometry.u, in: rect) }
}

struct EstusLogoS2: Shape {
    func path(in rect: CGRect) -> Path { EstusLogoGeometry.fitted(EstusLogoGeometry.s2, in: rect) }
}

struct EstusMark: Shape {
    func path(in rect: CGRect) -> Path { EstusLogoGeometry.fitted(EstusLogoGeometry.mark, in: rect) }
}

// MARK: - SVG Path Parser
// Minimal parser for SVG path data: M/L/H/V/C/S/Z, absolute and relative.
// Enough for the Illustrator-exported logo; arcs and quadratics aren't used.

enum SVGPathParser {
    static func path(from d: String) -> Path {
        var path = Path()
        let chars = Array(d.utf8)
        var i = 0
        var command: UInt8 = 0
        var current = CGPoint.zero
        var subpathStart = CGPoint.zero
        var lastCubicControl: CGPoint?

        func isSeparator(_ c: UInt8) -> Bool {
            c == UInt8(ascii: " ") || c == UInt8(ascii: ",") || c == UInt8(ascii: "\n")
                || c == UInt8(ascii: "\t") || c == UInt8(ascii: "\r")
        }
        func isDigit(_ c: UInt8) -> Bool { c >= UInt8(ascii: "0") && c <= UInt8(ascii: "9") }
        func isCommand(_ c: UInt8) -> Bool {
            ((c >= UInt8(ascii: "A") && c <= UInt8(ascii: "Z")) || (c >= UInt8(ascii: "a") && c <= UInt8(ascii: "z")))
                && c != UInt8(ascii: "e") && c != UInt8(ascii: "E")
        }

        func skipSeparators() {
            while i < chars.count, isSeparator(chars[i]) { i += 1 }
        }

        func number() -> CGFloat {
            skipSeparators()
            let start = i
            if i < chars.count, chars[i] == UInt8(ascii: "-") || chars[i] == UInt8(ascii: "+") { i += 1 }
            while i < chars.count, isDigit(chars[i]) { i += 1 }
            if i < chars.count, chars[i] == UInt8(ascii: ".") {
                i += 1
                while i < chars.count, isDigit(chars[i]) { i += 1 }
            }
            if i < chars.count, chars[i] == UInt8(ascii: "e") || chars[i] == UInt8(ascii: "E") {
                i += 1
                if i < chars.count, chars[i] == UInt8(ascii: "-") || chars[i] == UInt8(ascii: "+") { i += 1 }
                while i < chars.count, isDigit(chars[i]) { i += 1 }
            }
            let text = String(decoding: chars[start..<i], as: UTF8.self)
            return CGFloat(Double(text) ?? 0)
        }

        func point(relative: Bool) -> CGPoint {
            let x = number(), y = number()
            return relative ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
        }

        while true {
            skipSeparators()
            guard i < chars.count else { break }

            if isCommand(chars[i]) {
                command = chars[i]
                i += 1
            } else if command == 0 {
                break
            }

            let relative = command >= UInt8(ascii: "a")
            switch command | 0x20 { // lowercase
            case UInt8(ascii: "m"):
                current = point(relative: relative)
                subpathStart = current
                path.move(to: current)
                lastCubicControl = nil
                // Extra coordinate pairs after a moveto are implicit linetos.
                command = relative ? UInt8(ascii: "l") : UInt8(ascii: "L")
            case UInt8(ascii: "l"):
                current = point(relative: relative)
                path.addLine(to: current)
                lastCubicControl = nil
            case UInt8(ascii: "h"):
                let x = number()
                current.x = relative ? current.x + x : x
                path.addLine(to: current)
                lastCubicControl = nil
            case UInt8(ascii: "v"):
                let y = number()
                current.y = relative ? current.y + y : y
                path.addLine(to: current)
                lastCubicControl = nil
            case UInt8(ascii: "c"):
                let c1 = point(relative: relative)
                let c2 = point(relative: relative)
                let end = point(relative: relative)
                path.addCurve(to: end, control1: c1, control2: c2)
                lastCubicControl = c2
                current = end
            case UInt8(ascii: "s"):
                // First control point reflects the previous cubic's second one.
                let c1 = lastCubicControl.map { CGPoint(x: 2 * current.x - $0.x, y: 2 * current.y - $0.y) } ?? current
                let c2 = point(relative: relative)
                let end = point(relative: relative)
                path.addCurve(to: end, control1: c1, control2: c2)
                lastCubicControl = c2
                current = end
            case UInt8(ascii: "z"):
                path.closeSubpath()
                current = subpathStart
                lastCubicControl = nil
            default:
                assertionFailure("Unsupported SVG path command: \(UnicodeScalar(command))")
                return path
            }
        }
        return path
    }
}
